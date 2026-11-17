-- =====================================================================
-- Catering IS - sanity checks. Read-only, except the rule tests in
-- section 6, which roll back everything they try.
-- =====================================================================

SET LINESIZE 200
SET PAGESIZE 100
SET SERVEROUTPUT ON
COLUMN table_name FORMAT A24
COLUMN tree FORMAT A50
COLUMN menu_name FORMAT A26
COLUMN name FORMAT A30

-- 1. Row counts per table
SELECT 'ROLES' AS table_name, COUNT(*) AS row_count FROM roles
UNION ALL SELECT 'USERS', COUNT(*) FROM users
UNION ALL SELECT 'USER_ROLES', COUNT(*) FROM user_roles
UNION ALL SELECT 'CUSTOMERS', COUNT(*) FROM customers
UNION ALL SELECT 'PROJECTS', COUNT(*) FROM projects
UNION ALL SELECT 'PROJECT_NODES', COUNT(*) FROM project_nodes
UNION ALL SELECT 'PRODUCTS', COUNT(*) FROM products
UNION ALL SELECT 'ALLERGENS', COUNT(*) FROM allergens
UNION ALL SELECT 'PRODUCT_ALLERGENS', COUNT(*) FROM product_allergens
UNION ALL SELECT 'PRODUCT_PRICE_HISTORY', COUNT(*) FROM product_price_history
UNION ALL SELECT 'MENUS', COUNT(*) FROM menus
UNION ALL SELECT 'MENU_REVISIONS', COUNT(*) FROM menu_revisions
UNION ALL SELECT 'MENU_CATEGORIES', COUNT(*) FROM menu_categories
UNION ALL SELECT 'MENU_ITEMS', COUNT(*) FROM menu_items
UNION ALL SELECT 'SHARE_LINKS', COUNT(*) FROM share_links
UNION ALL SELECT 'COMMENTS', COUNT(*) FROM comments;

-- 2. Folder tree of project 1 (recursive relationship, hierarchical query)
SELECT LPAD(' ', (LEVEL - 1) * 2) || name || CASE node_type WHEN 'FOLDER' THEN '/' WHEN 'MENU' THEN ' [menu]' END AS tree,
       node_type, size_bytes
FROM project_nodes
WHERE project_id = 1
START WITH parent_id IS NULL
CONNECT BY PRIOR node_id = parent_id
ORDER SIBLINGS BY node_type DESC, name;

-- 3. Menu revision history with totals (view)
SELECT menu_id, revision_no, menu_name, state, item_count, total_price, price_per_guest
FROM v_menu_revision_totals
WHERE project_id IN (1, 4)
ORDER BY menu_id, revision_no;

-- 4. Price journal
SELECT p.name, h.old_price, h.new_price, TO_CHAR(h.changed_at, 'YYYY-MM-DD') AS changed_on
FROM product_price_history h JOIN products p ON p.product_id = h.product_id
ORDER BY h.changed_at;

-- 5. Integrity checks: each query must return 0
SELECT 'projects without exactly one root folder' AS rule_check, COUNT(*) AS violations
FROM projects p
WHERE (SELECT COUNT(*) FROM project_nodes n WHERE n.project_id = p.project_id AND n.parent_id IS NULL) <> 1
UNION ALL
SELECT 'nodes whose parent is in another project', COUNT(*)
FROM project_nodes c JOIN project_nodes p ON p.node_id = c.parent_id
WHERE c.project_id <> p.project_id
UNION ALL
SELECT 'nodes whose parent is not a FOLDER', COUNT(*)
FROM project_nodes c JOIN project_nodes p ON p.node_id = c.parent_id
WHERE p.node_type <> 'FOLDER'
UNION ALL
SELECT 'menus whose node is not a MENU node of the same project with the same name', COUNT(*)
FROM menus m
WHERE NOT EXISTS (SELECT 1 FROM project_nodes n
                  WHERE n.node_id = m.node_id AND n.node_type = 'MENU'
                    AND n.project_id = m.project_id AND n.name = m.name)
UNION ALL
SELECT 'menus with more than one active share link', COUNT(*)
FROM (SELECT menu_id FROM share_links WHERE active = 'Y' GROUP BY menu_id HAVING COUNT(*) > 1)
UNION ALL
SELECT 'share links to a WORKING revision', COUNT(*)
FROM share_links l JOIN menu_revisions r ON r.menu_id = l.menu_id AND r.revision_no = l.revision_no
WHERE r.state <> 'SHARED'
UNION ALL
SELECT 'menus without revision 1', COUNT(*)
FROM menus m WHERE NOT EXISTS (SELECT 1 FROM menu_revisions r WHERE r.menu_id = m.menu_id AND r.revision_no = 1)
UNION ALL
SELECT 'no active administrator', CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
FROM users u JOIN user_roles ur ON ur.user_id = u.user_id
WHERE ur.role_code = 'ADMIN' AND u.active = 'Y';

-- 6. Rules enforced by the database (each attempt must fail; everything is rolled back)
DECLARE
  PROCEDURE expect_error(p_label VARCHAR2, p_sql VARCHAR2) IS
  BEGIN
    SAVEPOINT before_test;
    EXECUTE IMMEDIATE p_sql;
    DBMS_OUTPUT.PUT_LINE('FAIL  ' || p_label || ' (statement was accepted)');
    ROLLBACK TO before_test;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('OK    ' || p_label || ': ' || SUBSTR(SQLERRM, 1, 90));
      ROLLBACK TO before_test;
  END;
BEGIN
  expect_error('ARC: comment on revision and item at once',
    'INSERT INTO comments (menu_id, revision_no, category_id, product_id, author_name, body) ' ||
    'SELECT c.menu_id, c.revision_no, i.category_id, i.product_id, ''X'', ''Y'' ' ||
    'FROM menu_items i JOIN menu_categories c ON c.category_id = i.category_id WHERE ROWNUM = 1');
  expect_error('STI: folder with document columns',
    'UPDATE project_nodes SET storage_key = ''x/y'' WHERE node_type = ''FOLDER'' AND ROWNUM = 1');
  expect_error('second root folder in a project',
    'INSERT INTO project_nodes (project_id, parent_id, node_type, name) VALUES (1, NULL, ''FOLDER'', ''Druhý kořen'')');
  expect_error('duplicate name in one folder',
    'INSERT INTO project_nodes (project_id, parent_id, node_type, name) ' ||
    'SELECT project_id, parent_id, ''FOLDER'', name FROM project_nodes WHERE name = ''Smlouvy'' AND project_id = 1');
  expect_error('non-transferable: move menu to another project',
    'UPDATE menus SET project_id = 2 WHERE menu_id = 1');
  expect_error('non-transferable: move project to another customer',
    'UPDATE projects SET customer_id = 2 WHERE project_id = 1');
  expect_error('negative quantity in menu item',
    'UPDATE menu_items SET quantity = -1 WHERE ROWNUM = 1');
  expect_error('second root folder of MENU type (ux_project_nodes_root)',
    'INSERT INTO project_nodes (project_id, parent_id, node_type, name) VALUES (1, NULL, ''MENU'', ''Kořenové menu'')');
  expect_error('resolved comment without who and when',
    'UPDATE comments SET resolved = ''Y'', resolved_by = NULL, resolved_at = NULL WHERE resolved = ''N'' AND ROWNUM = 1');
  expect_error('user supervises himself',
    'UPDATE users SET supervisor_id = user_id WHERE user_id = 1');
  expect_error('invalid e-mail',
    'UPDATE users SET email = ''not-an-email'' WHERE user_id = 1');
END;
/

-- 7. Transferable relationship: a project can be handed over to another worker
SAVEPOINT transfer_test;
UPDATE projects SET responsible_user_id = 6 WHERE project_id = 1;
SELECT project_id, responsible_user_id FROM projects WHERE project_id = 1;
ROLLBACK TO transfer_test;
