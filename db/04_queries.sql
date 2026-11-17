-- =====================================================================
-- Catering IS - SQL query catalogue (Oracle 19c syntax).
-- One section per block of the assignment, in assignment order.
-- Run as the schema owner (local: CATERING) after 01_schema.sql + 02_seed.sql:
--   sqlplus CATERING@db @04_queries.sql      or F5 in Oracle SQL Developer.
-- The script leaves the database at seed state:
--   * sections DD S15 .. SQL S06 and the later SELECT-only sections are read-only,
--   * every DDL/DML demo works on scratch objects named TMP_*, dropped with PURGE
--     at the end (and also at the start, so the script can be re-run),
--   * real tables are touched only in the SQL S14 demo (one UPDATE, ROLLBACK).
-- No NEXTVAL is called on the schema sequences (SEQ_*), only on TMP_ sequences.
-- =====================================================================

SET DEFINE OFF
SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 60
SET LONG 300
SET NULL '(null)'
ALTER SESSION SET NLS_DATE_LANGUAGE = 'ENGLISH';
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT = 'YYYY-MM-DD HH24:MI:SS TZR';
COLUMN name FORMAT A32
COLUMN full_name FORMAT A22
COLUMN email FORMAT A30
COLUMN contact FORMAT A50
COLUMN company_name FORMAT A26
COLUMN city FORMAT A14
COLUMN description FORMAT A34
COLUMN org_chart FORMAT A34
COLUMN path FORMAT A40
COLUMN constraint_name FORMAT A32
COLUMN search_condition FORMAT A60
COLUMN table_name FORMAT A22
COLUMN column_name FORMAT A18
COLUMN index_name FORMAT A26
COLUMN object_name FORMAT A30
COLUMN original_name FORMAT A22

-- ---------------------------------------------------------------------
-- 0. Cleanup of scratch objects from an earlier run (ignores missing objects)
-- ---------------------------------------------------------------------
BEGIN
  FOR o IN (SELECT object_name, object_type FROM user_objects
            WHERE object_name LIKE 'TMP\_%' ESCAPE '\'
              AND object_type IN ('VIEW', 'SYNONYM', 'PROCEDURE', 'SEQUENCE')) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP ' || o.object_type || ' ' || o.object_name;
    EXCEPTION WHEN OTHERS THEN NULL;   -- ORA-00942/02289/04043: already gone
    END;
  END LOOP;
  FOR t IN (SELECT table_name FROM user_tables WHERE table_name LIKE 'TMP\_%' ESCAPE '\') LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
  FOR r IN (SELECT object_name FROM user_recyclebin
            WHERE original_name LIKE 'TMP\_%' ESCAPE '\' AND type = 'TABLE') LOOP
    BEGIN
      EXECUTE IMMEDIATE 'PURGE TABLE "' || r.object_name || '"';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END;
/

-- #####################################################################
-- PART 1: read-only queries on the real tables
-- #####################################################################

-- =====================================================================
-- DD S15 L01  Concatenation, DISTINCT
-- =====================================================================
-- || joins strings: customer contact line "name <email>".
SELECT name || ' <' || email || '>' AS contact FROM customers ORDER BY name FETCH FIRST 5 ROWS ONLY;
-- CONCAT takes exactly two arguments, so three parts need nesting.
SELECT CONCAT(CONCAT(name, ' - '), city) AS customer_city FROM customers ORDER BY name FETCH FIRST 5 ROWS ONLY;
-- DISTINCT: cities our customers come from (20 customers, fewer cities).
SELECT DISTINCT city FROM customers ORDER BY city;
-- DISTINCT over a pair of columns: unique status + guest count combinations of projects.
SELECT DISTINCT status, guest_count FROM projects ORDER BY status, guest_count;

-- =====================================================================
-- DD S16 L02  WHERE, LOWER / UPPER / INITCAP
-- =====================================================================
-- WHERE: projects that are already confirmed by the customer.
SELECT project_id, name, event_date, guest_count FROM projects WHERE status = 'CONFIRMED';
-- UPPER/LOWER/INITCAP on customer data (INITCAP capitalises every word).
SELECT UPPER(name) AS upper_name, LOWER(email) AS lower_email, INITCAP('svatební MENU novákovi') AS initcap_demo
FROM customers WHERE customer_id <= 3;
-- Case-insensitive search: LOWER on the column makes 'Ostrava' and 'OSTRAVA' equal.
SELECT name, city FROM customers WHERE LOWER(city) = 'ostrava';

-- =====================================================================
-- DD S16 L03  BETWEEN, LIKE, IN, IS NULL
-- =====================================================================
-- BETWEEN is inclusive on both ends: events in the 2026 Christmas season.
SELECT name, event_date FROM projects WHERE event_date BETWEEN DATE '2026-11-01' AND DATE '2027-01-31' ORDER BY event_date;
-- LIKE with %: every project whose name starts with 'Svatba' (wedding).
SELECT name FROM projects WHERE name LIKE 'Svatba%';
-- LIKE with _ (exactly one character): 'N_voroční' matches 'Novoroční'.
SELECT name FROM projects WHERE name LIKE 'N_voroční%';
-- LIKE on e-mail: customers with a Czech business domain.
SELECT name, email FROM customers WHERE email LIKE '%@%.cz' AND email NOT LIKE '%@seznam.cz';
-- IN: projects in one of two states.
SELECT name, status FROM projects WHERE status IN ('DONE', 'ARCHIVED');
-- IS NULL: private persons have no company.
SELECT name FROM customers WHERE company_name IS NULL ORDER BY name;
-- IS NOT NULL: customers with a company and a phone number (= NULL would never match).
SELECT name, company_name, phone FROM customers WHERE company_name IS NOT NULL AND phone IS NOT NULL ORDER BY name FETCH FIRST 5 ROWS ONLY;

-- =====================================================================
-- DD S17 L01  AND, OR, NOT, priority with ()
-- =====================================================================
-- AND binds stronger than OR: this means CONFIRMED  OR  (DONE AND guests > 100).
SELECT name, status, guest_count FROM projects
WHERE status = 'CONFIRMED' OR status = 'DONE' AND guest_count > 100;
-- Parentheses change the meaning: (CONFIRMED OR DONE) AND guests > 100.
SELECT name, status, guest_count FROM projects
WHERE (status = 'CONFIRMED' OR status = 'DONE') AND guest_count > 100;
-- NOT negates a condition: projects that are neither archived nor done.
SELECT name, status FROM projects WHERE NOT (status = 'ARCHIVED' OR status = 'DONE');

-- =====================================================================
-- DD S17 L02  ORDER BY
-- =====================================================================
-- One attribute, descending: the biggest events first.
SELECT name, guest_count FROM projects ORDER BY guest_count DESC;
-- More attributes: by status A-Z, inside a status the newest event first.
SELECT status, name, event_date FROM projects ORDER BY status ASC, event_date DESC;
-- Column position instead of a name.
SELECT name, current_price FROM products ORDER BY 2 DESC, 1 FETCH FIRST 5 ROWS ONLY;

-- =====================================================================
-- DD S17 L03  Single-row and multi-row functions
-- =====================================================================
-- Single-row function: runs once per row (name length and upper-cased name).
SELECT name, LENGTH(name) AS name_length, UPPER(name) AS upper_name FROM products FETCH FIRST 5 ROWS ONLY;
-- Multi-row (aggregate) functions: one result row for the whole product catalogue.
SELECT MIN(current_price) AS cheapest, MAX(current_price) AS dearest, ROUND(AVG(current_price), 2) AS average,
       SUM(current_price) AS total, COUNT(*) AS products
FROM products;

-- =====================================================================
-- SQL S01 L01  Character functions, DUAL
-- =====================================================================
-- DUAL is the one-row dummy table: pure function demos need no real table.
SELECT CONCAT('Cate', 'ring') AS concat_demo, LENGTH('Catering') AS len, UPPER('catering') AS up,
       LOWER('CATERING') AS low, INITCAP('catering IS') AS init
FROM dual;
-- SUBSTR(text, start, length) and INSTR(text, search): mailbox and domain of a customer e-mail.
SELECT email, SUBSTR(email, 1, INSTR(email, '@') - 1) AS mailbox, SUBSTR(email, INSTR(email, '@') + 1) AS domain
FROM customers FETCH FIRST 5 ROWS ONLY;
-- LPAD/RPAD: right-aligned price column and a dotted leader for a printed menu card.
SELECT RPAD(name, 34, '.') || LPAD(TO_CHAR(current_price), 6, ' ') AS menu_card_line FROM products WHERE product_id <= 5;
-- TRIM removes spaces (or another single character) from both/leading/trailing ends.
SELECT TRIM('   Svatební menu  ') AS trimmed, TRIM(LEADING '0' FROM '000123') AS no_leading_zeros,
       TRIM(TRAILING '.' FROM 'Konec...') AS no_trailing_dots
FROM dual;
-- REPLACE: normalise a phone number by removing the spaces.
SELECT phone, REPLACE(phone, ' ', '') AS phone_compact FROM customers WHERE phone IS NOT NULL FETCH FIRST 5 ROWS ONLY;

-- =====================================================================
-- SQL S01 L02  ROUND, TRUNC, MOD
-- =====================================================================
-- ROUND/TRUNC to 2 decimals: price with VAT (VAT 12 or 21 percent).
SELECT name, current_price, vat_rate,
       ROUND(current_price * (1 + vat_rate / 100), 2) AS price_with_vat_rounded,
       TRUNC(current_price * (1 + vat_rate / 100), 2) AS price_with_vat_truncated
FROM products WHERE vat_rate = 21;
-- Negative precision: whole thousands (the dearest revisions priced to thousands).
SELECT menu_name, revision_no, total_price, ROUND(total_price, -3) AS rounded_thousands, TRUNC(total_price, -3) AS truncated_thousands
FROM v_menu_revision_totals WHERE state = 'SHARED' ORDER BY total_price DESC FETCH FIRST 5 ROWS ONLY;
-- MOD: remainder; how many guests stay over when tables seat 10.
SELECT name, guest_count, MOD(guest_count, 10) AS guests_without_full_table FROM projects ORDER BY guest_count;

-- =====================================================================
-- SQL S01 L03  Date functions, SYSDATE
-- =====================================================================
-- SYSDATE is the current date and time of the DB server; subtracting dates gives days.
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI') AS now,
       name, event_date, event_date - TRUNC(SYSDATE) AS days_to_event
FROM projects WHERE status IN ('IN_PROGRESS', 'CONFIRMED') ORDER BY event_date;
-- MONTHS_BETWEEN, ADD_MONTHS: months until the event and the date of the final payment (3 months before).
SELECT name, event_date, ROUND(MONTHS_BETWEEN(event_date, SYSDATE), 1) AS months_to_event,
       ADD_MONTHS(event_date, -3) AS final_payment_due
FROM projects WHERE status <> 'ARCHIVED' ORDER BY event_date;
-- NEXT_DAY: first Monday after the event (day to send the invoice); LAST_DAY: end of the event month.
SELECT name, event_date, NEXT_DAY(event_date, 'MONDAY') AS invoice_day, LAST_DAY(event_date) AS month_end
FROM projects FETCH FIRST 5 ROWS ONLY;
-- ROUND/TRUNC on dates: first day of the month, first day of the year, nearest month start.
SELECT name, event_date, TRUNC(event_date, 'MONTH') AS month_start, TRUNC(event_date, 'YEAR') AS year_start,
       ROUND(event_date, 'MONTH') AS nearest_month
FROM projects FETCH FIRST 5 ROWS ONLY;
-- Interval column arithmetic: when an event ends (DATE + INTERVAL DAY TO SECOND) and when its documents may be deleted.
SELECT name, event_date, event_duration, CAST(event_date AS TIMESTAMP) + event_duration AS event_end,
       ADD_MONTHS(event_date, 12 * 5) AS retention_until_simple
FROM projects WHERE project_id <= 4;

-- =====================================================================
-- SQL S02 L01  TO_CHAR, TO_NUMBER, TO_DATE
-- =====================================================================
-- TO_CHAR with a date mask: Czech-style date and the weekday of the event.
SELECT name, TO_CHAR(event_date, 'DD.MM.YYYY') AS cz_date, TO_CHAR(event_date, 'FMDay') AS weekday
FROM projects FETCH FIRST 5 ROWS ONLY;
-- TO_CHAR with a number mask: thousand separator and 2 decimals.
SELECT name, TO_CHAR(current_price, '99,990.00') AS price_text FROM products WHERE product_id IN (1, 13);
-- TO_NUMBER: text to number, also from a phone number with spaces removed.
SELECT TO_NUMBER('1,234.50', '9,999.99') AS parsed_price,
       TO_NUMBER(REPLACE(REPLACE(phone, '+', ''), ' ', '')) AS phone_as_number
FROM customers WHERE customer_id = 1;
-- TO_DATE: text to date with an explicit mask; used here to filter projects.
SELECT name, event_date FROM projects WHERE event_date >= TO_DATE('01.01.2027', 'DD.MM.YYYY') ORDER BY event_date;

-- =====================================================================
-- SQL S02 L02  NVL, NVL2, NULLIF, COALESCE
-- =====================================================================
-- NVL: show the person when there is no company.
SELECT name, NVL(company_name, '(private person)') AS company FROM customers FETCH FIRST 6 ROWS ONLY;
-- NVL2(x, if_not_null, if_null): company or private customer label.
SELECT name, NVL2(company_name, 'COMPANY', 'PRIVATE') AS customer_kind FROM customers FETCH FIRST 6 ROWS ONLY;
-- NULLIF returns NULL when both are equal: NULL for customers in Ostrava (everything else stays).
SELECT name, city, NULLIF(city, 'Ostrava') AS city_outside_ostrava FROM customers FETCH FIRST 6 ROWS ONLY;
-- COALESCE returns the first non-NULL: best way to contact a customer.
SELECT name, COALESCE(company_name, phone, email) AS first_available FROM customers FETCH FIRST 6 ROWS ONLY;

-- =====================================================================
-- SQL S02 L03  DECODE, CASE, IF-THEN-ELSE
-- =====================================================================
-- DECODE (Oracle-only equality switch): readable status label.
SELECT name, DECODE(status, 'IN_PROGRESS', 'Preparing', 'CONFIRMED', 'Confirmed', 'DONE', 'Finished', 'Archive') AS status_label
FROM projects;
-- Searched CASE with ranges: size class of the event.
SELECT name, guest_count,
       CASE WHEN guest_count < 60 THEN 'small' WHEN guest_count < 150 THEN 'medium' ELSE 'large' END AS size_class
FROM projects ORDER BY guest_count;
-- Simple CASE on one expression: VAT rate to text.
SELECT name, vat_rate, CASE vat_rate WHEN 12 THEN 'reduced' WHEN 21 THEN 'basic' ELSE 'other' END AS vat_class
FROM products FETCH FIRST 5 ROWS ONLY;
-- IF-THEN-ELSE exists only in PL/SQL: a block classifying one project by its guest count.
DECLARE
  v_guests projects.guest_count%TYPE;
BEGIN
  SELECT guest_count INTO v_guests FROM projects WHERE project_id = 1;
  IF v_guests >= 150 THEN
    DBMS_OUTPUT.PUT_LINE('Project 1: large event, ' || v_guests || ' guests');
  ELSIF v_guests >= 60 THEN
    DBMS_OUTPUT.PUT_LINE('Project 1: medium event, ' || v_guests || ' guests');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Project 1: small event, ' || v_guests || ' guests');
  END IF;
END;
/

-- =====================================================================
-- SQL S03 L01  NATURAL JOIN, CROSS JOIN
-- =====================================================================
-- NATURAL JOIN joins on all columns with the same name; menus and menu_revisions share only MENU_ID.
-- (customers NATURAL JOIN projects would also try NAME = NAME and return nothing: use it with care.)
SELECT menu_id, name AS menu_name, revision_no, state FROM menus NATURAL JOIN menu_revisions WHERE menu_id <= 2 ORDER BY menu_id, revision_no;
-- NATURAL JOIN on user_roles and roles (common column ROLE_CODE): who has which role.
SELECT u.username, role_code, r.name AS role_name
FROM users u JOIN user_roles USING (user_id) NATURAL JOIN roles r ORDER BY u.username;
-- CROSS JOIN = Cartesian product: every user x every role (3 users shown, 9 rows).
SELECT u.username, r.role_code FROM users u CROSS JOIN roles r WHERE u.user_id <= 3 ORDER BY u.username, r.role_code;

-- =====================================================================
-- SQL S03 L02  JOIN USING, JOIN ON
-- =====================================================================
-- JOIN USING (column): the join column appears once and takes no alias.
SELECT m.name AS menu_name, menu_id, revision_no, r.state
FROM menus m JOIN menu_revisions r USING (menu_id) WHERE menu_id = 1 ORDER BY revision_no;
-- JOIN ON with any condition: project, its customer and the responsible worker (3 tables).
SELECT p.name AS project, c.name AS customer, u.full_name AS responsible
FROM projects p
JOIN customers c ON c.customer_id = p.customer_id
JOIN users u ON u.user_id = p.responsible_user_id
ORDER BY p.project_id;
-- Four-table join with a filter: items of the latest-shared wedding menu with their category and product.
SELECT cat.name AS category, pr.name AS product, i.quantity, i.unit_price
FROM menu_categories cat
JOIN menu_items i ON i.category_id = cat.category_id
JOIN products pr ON pr.product_id = i.product_id
WHERE cat.menu_id = 1 AND cat.revision_no = 2
ORDER BY cat.position, pr.name;

-- =====================================================================
-- SQL S03 L03  LEFT / RIGHT / FULL OUTER JOIN
-- =====================================================================
-- LEFT OUTER JOIN: all customers, also those without any project (project columns NULL).
SELECT c.name AS customer, p.name AS project
FROM customers c LEFT OUTER JOIN projects p ON p.customer_id = c.customer_id
WHERE p.project_id IS NULL ORDER BY c.name FETCH FIRST 6 ROWS ONLY;
-- RIGHT OUTER JOIN: all users, also those who are responsible for no project.
SELECT u.username, p.name AS project
FROM projects p RIGHT OUTER JOIN users u ON p.responsible_user_id = u.user_id
WHERE p.project_id IS NULL ORDER BY u.username;
-- FULL OUTER JOIN: unmatched rows from both sides. Customers whose city appears in a project's place
-- vs projects held in no customer's city (NULL on the left side).
SELECT c.name AS customer, c.city, p.name AS project, p.event_place
FROM customers c FULL OUTER JOIN projects p ON p.event_place LIKE '%' || c.city || '%'
WHERE c.customer_id IS NULL OR p.project_id IS NULL
ORDER BY c.name, p.name FETCH FIRST 8 ROWS ONLY;

-- =====================================================================
-- SQL S03 L04  Self join, hierarchical query
-- =====================================================================
-- Self-join with two aliases: employee and supervisor from the one table USERS (LEFT: the boss has none).
SELECT e.full_name AS employee, NVL(s.full_name, '(top of the hierarchy)') AS supervisor
FROM users e LEFT JOIN users s ON s.user_id = e.supervisor_id ORDER BY e.user_id;
-- START WITH / CONNECT BY PRIOR / LEVEL: the org chart. NOCYCLE protects against a bad supervisor loop
-- (the schema does not forbid it for users).
SELECT LPAD(' ', 2 * (LEVEL - 1)) || full_name AS org_chart, LEVEL AS lvl,
       SYS_CONNECT_BY_PATH(username, '/') AS path, CONNECT_BY_ISLEAF AS is_leaf
FROM users
START WITH supervisor_id IS NULL
CONNECT BY NOCYCLE PRIOR user_id = supervisor_id
ORDER SIBLINGS BY full_name;
-- The same tree walked upwards (PRIOR on the other side): chain of command above one worker.
SELECT LEVEL AS steps_up, full_name FROM users
START WITH username = 'kpokorny' CONNECT BY PRIOR supervisor_id = user_id;
-- The project folder tree (also in 03_checks.sql, section 2): hierarchy over project_nodes.parent_id.
SELECT LPAD(' ', (LEVEL - 1) * 2) || name || CASE node_type WHEN 'FOLDER' THEN '/' WHEN 'MENU' THEN ' [menu]' END AS org_chart
FROM project_nodes WHERE project_id = 2
START WITH parent_id IS NULL CONNECT BY PRIOR node_id = parent_id
ORDER SIBLINGS BY node_type DESC, name;

-- =====================================================================
-- SQL S04 L02  AVG, COUNT, MIN, MAX, SUM, VARIANCE, STDDEV
-- =====================================================================
-- All aggregate functions over the guest counts of the projects (spread of the event sizes).
SELECT COUNT(*) AS projects, MIN(guest_count) AS min_guests, MAX(guest_count) AS max_guests,
       ROUND(AVG(guest_count), 1) AS avg_guests, SUM(guest_count) AS total_guests,
       ROUND(VARIANCE(guest_count), 1) AS variance_guests, ROUND(STDDEV(guest_count), 1) AS stddev_guests
FROM projects;
-- Aggregates over a money column: item price statistics of all menu items.
SELECT MIN(unit_price) AS min_price, MAX(unit_price) AS max_price, ROUND(AVG(unit_price), 2) AS avg_price,
       ROUND(STDDEV(unit_price), 2) AS stddev_price, SUM(quantity * unit_price) AS value_of_all_items
FROM menu_items;

-- =====================================================================
-- SQL S04 L03  COUNT(*) vs COUNT(col), COUNT DISTINCT, NVL in aggregates
-- =====================================================================
-- COUNT(*) counts rows, COUNT(col) skips NULLs, COUNT(DISTINCT col) skips duplicates too.
SELECT COUNT(*) AS customers, COUNT(company_name) AS with_company, COUNT(DISTINCT city) AS distinct_cities,
       COUNT(DISTINCT company_name) AS distinct_companies
FROM customers;
-- Why NVL in aggregates: AVG ignores NULL (folders have no size), so it averages documents only;
-- NVL(size,0) makes folders count as 0 bytes and gives a lower average over all nodes.
SELECT COUNT(*) AS nodes, COUNT(size_bytes) AS documents,
       ROUND(AVG(size_bytes)) AS avg_per_document, ROUND(AVG(NVL(size_bytes, 0))) AS avg_per_node
FROM project_nodes;

-- =====================================================================
-- SQL S05 L01  GROUP BY, HAVING
-- =====================================================================
-- GROUP BY: projects and guests per status.
SELECT status, COUNT(*) AS projects, SUM(guest_count) AS guests, ROUND(AVG(guest_count)) AS avg_guests
FROM projects GROUP BY status ORDER BY projects DESC, status;
-- GROUP BY with a join: number of projects and guests per customer city.
SELECT c.city, COUNT(*) AS projects, SUM(p.guest_count) AS guests
FROM projects p JOIN customers c ON c.customer_id = p.customer_id
GROUP BY c.city ORDER BY projects DESC, c.city;
-- HAVING filters groups after aggregation (WHERE filters rows before): workers with 2+ projects.
SELECT u.full_name, COUNT(*) AS projects
FROM projects p JOIN users u ON u.user_id = p.responsible_user_id
GROUP BY u.full_name HAVING COUNT(*) >= 2 ORDER BY projects DESC, u.full_name;
-- Category totals of one menu revision (GROUP BY on a join of three tables).
SELECT cat.name AS category, COUNT(*) AS items, SUM(i.quantity * i.unit_price) AS category_total
FROM menu_categories cat JOIN menu_items i ON i.category_id = cat.category_id
WHERE cat.menu_id = 1 AND cat.revision_no = 2
GROUP BY cat.name, cat.position ORDER BY cat.position;

-- =====================================================================
-- SQL S05 L02  ROLLUP, CUBE, GROUPING SETS
-- =====================================================================
-- ROLLUP: guests per status and responsible worker, with subtotals per status and a grand total.
SELECT status, responsible_user_id, COUNT(*) AS projects, SUM(guest_count) AS guests
FROM projects GROUP BY ROLLUP (status, responsible_user_id) ORDER BY status, responsible_user_id;
-- CUBE: all combinations; GROUPING() is 1 on a subtotal row so it can be labelled.
SELECT CASE GROUPING(status) WHEN 1 THEN 'ALL STATUSES' ELSE status END AS status,
       CASE GROUPING(vat) WHEN 1 THEN 'ALL VAT' ELSE TO_CHAR(vat) END AS vat_rate,
       COUNT(*) AS products
FROM (SELECT p.current_price, p.vat_rate AS vat, CASE WHEN p.current_price >= 200 THEN 'MAIN' ELSE 'SIDE' END AS status FROM products p)
GROUP BY CUBE (status, vat) ORDER BY 1, 2;
-- GROUPING SETS: only the wanted groupings (per status, per worker, grand total), no other combinations.
SELECT status, responsible_user_id, COUNT(*) AS projects
FROM projects GROUP BY GROUPING SETS ((status), (responsible_user_id), ()) ORDER BY status, responsible_user_id;

-- =====================================================================
-- SQL S05 L03  UNION, UNION ALL, INTERSECT, MINUS, ORDER BY
-- =====================================================================
-- UNION removes duplicates: all cities where we have either a customer or an event.
SELECT city AS place FROM customers WHERE city IS NOT NULL
UNION
SELECT event_place FROM projects
ORDER BY 1 FETCH FIRST 8 ROWS ONLY;
-- UNION ALL keeps duplicates (and is faster): every person-like name in the system, customers and workers.
SELECT name AS person, 'customer' AS kind FROM customers WHERE customer_id <= 3
UNION ALL
SELECT full_name, 'worker' FROM users WHERE user_id <= 3
ORDER BY person;
-- INTERSECT: products that are used on a menu AND carry an allergen.
SELECT product_id FROM menu_items
INTERSECT
SELECT product_id FROM product_allergens
ORDER BY product_id;
-- MINUS: products that carry no allergen (all catalogue products minus those listed in product_allergens).
SELECT product_id, name FROM products
MINUS
SELECT p.product_id, p.name FROM products p JOIN product_allergens pa ON pa.product_id = p.product_id
ORDER BY name;
-- ORDER BY in a set operation: only once at the very end, by a name or position from the FIRST query.
SELECT name AS item, current_price AS price FROM products WHERE unit = 'l'
UNION
SELECT name, current_price FROM products WHERE unit = 'set'
ORDER BY price DESC, item;

-- =====================================================================
-- SQL S06 L01  Subqueries: single value, multi-column, EXISTS
-- =====================================================================
-- Subquery returning one value: products dearer than the average product.
SELECT name, current_price FROM products WHERE current_price > (SELECT AVG(current_price) FROM products) ORDER BY current_price DESC;
-- Multi-column subquery: the biggest project of every customer (pair compared at once).
SELECT name, customer_id, guest_count FROM projects
WHERE (customer_id, guest_count) IN (SELECT customer_id, MAX(guest_count) FROM projects GROUP BY customer_id)
ORDER BY customer_id;
-- EXISTS (correlated): customers who have at least one project.
SELECT c.name FROM customers c WHERE EXISTS (SELECT 1 FROM projects p WHERE p.customer_id = c.customer_id) ORDER BY c.name;
-- NOT EXISTS: customers without any project.
SELECT c.name FROM customers c WHERE NOT EXISTS (SELECT 1 FROM projects p WHERE p.customer_id = c.customer_id) ORDER BY c.name FETCH FIRST 5 ROWS ONLY;

-- =====================================================================
-- SQL S06 L02  Single-row subqueries
-- =====================================================================
-- Single-row subquery with =: the project with the most guests.
SELECT name, guest_count FROM projects WHERE guest_count = (SELECT MAX(guest_count) FROM projects);
-- Single-row subquery in a comparison with a join: projects of the customer of project 1.
SELECT p.name, p.status FROM projects p
WHERE p.customer_id = (SELECT customer_id FROM projects WHERE project_id = 1);
-- Correlated single-row subquery: products dearer than the average of their own unit.
SELECT p.name, p.unit, p.current_price FROM products p
WHERE p.current_price > (SELECT AVG(x.current_price) FROM products x WHERE x.unit = p.unit)
ORDER BY p.unit, p.current_price DESC;

-- =====================================================================
-- SQL S06 L03  Multi-row subqueries IN / ANY / ALL, NULLs in subqueries
-- =====================================================================
-- IN: products containing gluten (allergen 1).
SELECT name FROM products WHERE product_id IN (SELECT product_id FROM product_allergens WHERE allergen_id = 1) ORDER BY name;
-- > ANY: dearer than at least one drink sold per litre (= dearer than the cheapest drink).
SELECT name, current_price FROM products
WHERE current_price > ANY (SELECT current_price FROM products WHERE unit = 'l') AND unit <> 'l' ORDER BY current_price;
-- > ALL: dearer than every drink (= dearer than the dearest drink).
SELECT name, current_price FROM products
WHERE current_price > ALL (SELECT current_price FROM products WHERE unit = 'l') ORDER BY current_price;
-- NULL trap: the subquery contains a NULL (the top boss has supervisor_id NULL), so NOT IN is never true
-- and the query returns NO rows although some users supervise nobody.
SELECT username FROM users WHERE user_id NOT IN (SELECT supervisor_id FROM users);
-- Fix 1: remove the NULLs from the subquery.
SELECT username FROM users WHERE user_id NOT IN (SELECT supervisor_id FROM users WHERE supervisor_id IS NOT NULL) ORDER BY username;
-- Fix 2: NOT EXISTS is NULL-safe.
SELECT u.username FROM users u WHERE NOT EXISTS (SELECT 1 FROM users s WHERE s.supervisor_id = u.user_id) ORDER BY u.username;

-- =====================================================================
-- SQL S06 L04  WITH ... AS
-- =====================================================================
-- Two named subqueries (CTEs): revisions whose total is above the average revision total.
WITH item_totals AS (
  SELECT c.menu_id, c.revision_no, SUM(i.quantity * i.unit_price) AS total
  FROM menu_categories c JOIN menu_items i ON i.category_id = c.category_id
  GROUP BY c.menu_id, c.revision_no
), avg_total AS (
  SELECT AVG(total) AS avg_total FROM item_totals
)
SELECT t.menu_id, t.revision_no, t.total, ROUND(a.avg_total) AS average
FROM item_totals t CROSS JOIN avg_total a
WHERE t.total > a.avg_total ORDER BY t.total DESC FETCH FIRST 5 ROWS ONLY;
-- Recursive WITH (19c): the same folder tree as CONNECT BY, depth computed in the recursion.
WITH tree (node_id, name, depth) AS (
  SELECT node_id, name, 0 FROM project_nodes WHERE project_id = 1 AND parent_id IS NULL
  UNION ALL
  SELECT n.node_id, n.name, t.depth + 1 FROM project_nodes n JOIN tree t ON n.parent_id = t.node_id
)
SELECT depth, COUNT(*) AS nodes FROM tree GROUP BY depth ORDER BY depth;

-- =====================================================================
-- SQL S07 L01  INSERT: VALUES, column list, INSERT ... SELECT
-- =====================================================================
-- Scratch tables for the DML demos: CTAS copies structure and data (here: structure only for customers).
-- Structure only
CREATE TABLE tmp_customers AS SELECT * FROM customers WHERE 1 = 0;
-- Structure and all rows
CREATE TABLE tmp_products AS SELECT * FROM products;
CREATE TABLE tmp_projects AS SELECT * FROM projects;
-- INSERT ... VALUES with all columns in table order (customer_id, name, company_name, email, phone, city).
INSERT INTO tmp_customers VALUES (101, 'Test Zákazník', NULL, 'test@example.cz', '+420 111 222 333', 'Brno');
-- INSERT with a column list: unlisted nullable columns become NULL, order is free.
INSERT INTO tmp_customers (email, name, customer_id) VALUES ('minimal@example.cz', 'Minimal Zákazník', 102);
-- INSERT ... SELECT: copy all customers from Opava and Havířov in one statement.
INSERT INTO tmp_customers SELECT * FROM customers WHERE city IN ('Opava', 'Havířov');
SELECT customer_id, name, city FROM tmp_customers ORDER BY customer_id;

-- =====================================================================
-- SQL S07 L02  UPDATE, DELETE
-- =====================================================================
-- UPDATE with WHERE: move one customer to another city; without WHERE it would hit every row.
UPDATE tmp_customers SET city = 'Praha' WHERE customer_id = 101;
-- UPDATE with a subquery in SET: every customer without a city takes the most common city.
UPDATE tmp_customers SET city = (SELECT city FROM customers GROUP BY city ORDER BY COUNT(*) DESC, city FETCH FIRST 1 ROW ONLY)
WHERE city IS NULL;
-- UPDATE with an expression: raise all scratch prices of drinks by 10 percent (the real table, and its trigger, stay untouched).
UPDATE tmp_products SET current_price = ROUND(current_price * 1.10, 2) WHERE unit = 'l';
SELECT name, current_price FROM tmp_products WHERE unit = 'l' ORDER BY name;
-- DELETE with WHERE: remove the test customers again.
DELETE FROM tmp_customers WHERE customer_id IN (101, 102);
SELECT COUNT(*) AS customers_left FROM tmp_customers;

-- =====================================================================
-- SQL S07 L03  DEFAULT, MERGE, multi-table INSERT
-- =====================================================================
-- DEFAULT in a column definition, in INSERT VALUES (DEFAULT) and in UPDATE SET col = DEFAULT.
CREATE SEQUENCE tmp_seq_booking START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE TABLE tmp_booking (
  booking_id  NUMBER(6)          DEFAULT tmp_seq_booking.NEXTVAL NOT NULL,
  status      VARCHAR2(10 CHAR)  DEFAULT 'NEW' NOT NULL,
  guests      NUMBER(4)          DEFAULT 10,
  created_at  TIMESTAMP          DEFAULT SYSTIMESTAMP,
  created_by  VARCHAR2(30 CHAR)  DEFAULT USER
);
-- Other columns take their DEFAULT
INSERT INTO tmp_booking (guests) VALUES (50);
-- Explicit DEFAULT keyword
INSERT INTO tmp_booking (status, guests) VALUES ('PAID', DEFAULT);
-- Back to 'NEW'
UPDATE tmp_booking SET status = DEFAULT WHERE guests = 10;
SELECT booking_id, status, guests, created_by FROM tmp_booking ORDER BY booking_id;
-- MERGE: update products that exist in the source (price change), insert the ones that do not (new product).
MERGE INTO tmp_products t
USING (SELECT 1 AS product_id, 'Tatarák z hovězího' AS name, 'portion' AS unit, 109 AS current_price FROM dual
       UNION ALL SELECT 999, 'Test dezert', 'portion', 59 FROM dual) s
ON (t.product_id = s.product_id)
WHEN MATCHED THEN UPDATE SET t.current_price = s.current_price
WHEN NOT MATCHED THEN INSERT (product_id, name, unit, current_price, vat_rate) VALUES (s.product_id, s.name, s.unit, s.current_price, 12);
SELECT product_id, name, current_price FROM tmp_products WHERE product_id IN (1, 999) ORDER BY product_id;
-- Multi-table INSERT ALL (conditional): one pass over products fills a cheap and a dear table.
CREATE TABLE tmp_cheap  AS SELECT product_id, name, current_price FROM products WHERE 1 = 0;
CREATE TABLE tmp_pricey AS SELECT product_id, name, current_price FROM products WHERE 1 = 0;
INSERT ALL
  WHEN current_price < 100 THEN INTO tmp_cheap  (product_id, name, current_price) VALUES (product_id, name, current_price)
  WHEN current_price >= 100 THEN INTO tmp_pricey (product_id, name, current_price) VALUES (product_id, name, current_price)
SELECT product_id, name, current_price FROM products;
SELECT (SELECT COUNT(*) FROM tmp_cheap) AS cheap, (SELECT COUNT(*) FROM tmp_pricey) AS pricey FROM dual;
-- Unconditional INSERT ALL: the same row goes into two tables (a name list and a price list).
CREATE TABLE tmp_names AS SELECT product_id, name FROM products WHERE 1 = 0;
INSERT ALL
  INTO tmp_names (product_id, name) VALUES (product_id, name)
  INTO tmp_cheap (product_id, name, current_price) VALUES (product_id, name, current_price)
SELECT product_id, name, current_price FROM products WHERE product_id = 24;
SELECT (SELECT COUNT(*) FROM tmp_names) AS names, (SELECT COUNT(*) FROM tmp_cheap) AS cheap FROM dual;
COMMIT;

-- =====================================================================
-- SQL S08 L01  Objects, CREATE/ALTER/DROP/RENAME/TRUNCATE, synonym, external table
-- =====================================================================
-- All kinds of objects the schema owns: tables, indexes, sequences, views, triggers.
SELECT object_type, COUNT(*) AS objects FROM user_objects
WHERE object_name NOT LIKE 'TMP\_%' ESCAPE '\' AND object_name NOT LIKE 'BIN$%' GROUP BY object_type ORDER BY object_type;
-- CREATE TABLE with data types, DEFAULT and NOT NULL.
CREATE TABLE tmp_event (
  event_id    NUMBER(6)          NOT NULL,
  title       VARCHAR2(60 CHAR)  NOT NULL,
  starts_on   DATE               DEFAULT SYSDATE NOT NULL,
  budget      NUMBER(10, 2)      DEFAULT 0
);
INSERT INTO tmp_event (event_id, title) VALUES (1, 'Wedding');
INSERT INTO tmp_event (event_id, title, budget) VALUES (2, 'Conference', 150000);
-- RENAME a table (and the data survive).
RENAME tmp_event TO tmp_events;
SELECT event_id, title, budget FROM tmp_events ORDER BY event_id;
-- SYNONYM: a second name for an object (a public synonym needs a privilege the schema owner does not have).
CREATE SYNONYM tmp_syn_events FOR tmp_events;
SELECT COUNT(*) AS rows_through_synonym FROM tmp_syn_events;
-- TRUNCATE removes all rows at once (DDL, no rollback); the table stays. DROP removes the table itself.
TRUNCATE TABLE tmp_events;
SELECT COUNT(*) AS rows_after_truncate FROM tmp_events;
DROP SYNONYM tmp_syn_events;
-- External table (ORGANIZATION EXTERNAL, ORACLE_LOADER): read a CSV file as a table.
-- NOT EXECUTED here: CREATE DIRECTORY needs the CREATE ANY DIRECTORY privilege, which the CATERING user
-- does not have on the local database, and the CSV must exist on the DB server. The complete statements
-- (run them as a user with the privilege, put customers.csv into the directory) are:
/*
CREATE OR REPLACE DIRECTORY tmp_ext_dir AS '/tmp/catering_ext';
GRANT READ, WRITE ON DIRECTORY tmp_ext_dir TO CATERING;
CREATE TABLE tmp_ext_customers (
  name   VARCHAR2(100 CHAR),
  email  VARCHAR2(254 CHAR),
  city   VARCHAR2(60 CHAR)
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY tmp_ext_dir
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    SKIP 1
    FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
    MISSING FIELD VALUES ARE NULL
    (name, email, city)
  )
  LOCATION ('customers.csv')
)
REJECT LIMIT UNLIMITED;
SELECT * FROM tmp_ext_customers;
DROP TABLE tmp_ext_customers;
DROP DIRECTORY tmp_ext_dir;
*/

-- =====================================================================
-- SQL S08 L02  Data types
-- =====================================================================
-- The data types used by the real tables (dictionary): one example column of each kind.
SELECT table_name, column_name, data_type, data_length, data_precision, data_scale
FROM user_tab_columns
WHERE (table_name, column_name) IN (('PROJECTS', 'NOTE'), ('PROJECTS', 'EVENT_DURATION'), ('PROJECTS', 'RETENTION_PERIOD'),
      ('PRODUCTS', 'PHOTO'), ('PRODUCTS', 'CURRENT_PRICE'), ('USERS', 'CREATED_AT'), ('MENU_REVISIONS', 'CREATED_AT'),
      ('COMMENTS', 'CREATED_AT'), ('ROLES', 'ROLE_CODE'), ('ROLES', 'NAME'))
ORDER BY table_name, column_name;


-- One table with every type of the lesson; TIMESTAMP variants, INTERVALs, CHAR/VARCHAR2/CLOB, NUMBER, BLOB.
CREATE TABLE tmp_types (
  c_char       CHAR(5),
  c_varchar2   VARCHAR2(20 CHAR),
  c_clob       CLOB,
  c_number     NUMBER(8, 2),
  c_ts         TIMESTAMP(3),
  c_ts_tz      TIMESTAMP(3) WITH TIME ZONE,
  c_ts_ltz     TIMESTAMP(3) WITH LOCAL TIME ZONE,
  c_int_ym     INTERVAL YEAR(2) TO MONTH,
  c_int_ds     INTERVAL DAY(2) TO SECOND(0),
  c_blob       BLOB
);
INSERT INTO tmp_types VALUES ('ab', 'variable text', TO_CLOB('long note ') || TO_CLOB(RPAD('x', 5000, 'x')), 1234.567,
  TIMESTAMP '2027-06-14 16:30:00.123', TIMESTAMP '2027-06-14 16:30:00.123 +02:00', TIMESTAMP '2027-06-14 16:30:00.123',
  INTERVAL '5-3' YEAR TO MONTH, INTERVAL '2 06:30:00' DAY TO SECOND, UTL_RAW.CAST_TO_RAW('PNG-bytes'));
-- CHAR is blank-padded to 5 (length 5), VARCHAR2 keeps its length; NUMBER(8,2) rounded to 1234.57.
SELECT LENGTH(c_char) AS char_len, LENGTH(c_varchar2) AS varchar_len, c_number, DBMS_LOB.GETLENGTH(c_clob) AS clob_chars,
       DBMS_LOB.GETLENGTH(c_blob) AS blob_bytes FROM tmp_types;
-- The three TIMESTAMP kinds: the zone is stored (TZ), not stored but converted to the session zone (LTZ), or ignored.
SELECT c_ts, c_ts_tz, c_ts_ltz, EXTRACT(TIMEZONE_HOUR FROM c_ts_tz) AS tz_hour FROM tmp_types;
-- INTERVAL types: YEAR TO MONTH and DAY TO SECOND added to a date.
SELECT c_int_ym, c_int_ds, DATE '2027-01-15' + c_int_ym AS plus_ym, DATE '2027-01-15' + c_int_ds AS plus_ds,
       EXTRACT(MONTH FROM c_int_ym) AS months_part FROM tmp_types;

-- =====================================================================
-- SQL S08 L03  ALTER TABLE, DROP, FLASHBACK, COMMENT, SET UNUSED, DELETE vs TRUNCATE
-- =====================================================================
-- ALTER TABLE ADD: new column; MODIFY: widen it and add a default; DROP COLUMN: remove it; RENAME COLUMN.
ALTER TABLE tmp_events ADD (place VARCHAR2(20 CHAR), notes VARCHAR2(100 CHAR), temp_flag CHAR(1));
ALTER TABLE tmp_events MODIFY (place VARCHAR2(80 CHAR) DEFAULT 'Ostrava');
ALTER TABLE tmp_events RENAME COLUMN notes TO note;
ALTER TABLE tmp_events DROP COLUMN temp_flag;
-- SET UNUSED: hide a column quickly (cheap on big tables), physical removal later with DROP UNUSED COLUMNS.
ALTER TABLE tmp_events SET UNUSED (note);
SELECT table_name, count FROM user_unused_col_tabs WHERE table_name = 'TMP_EVENTS';
ALTER TABLE tmp_events DROP UNUSED COLUMNS;
-- COMMENT ON TABLE / COLUMN and reading it back from the dictionary.
COMMENT ON TABLE tmp_events IS 'Scratch table for the catalogue demo.';
COMMENT ON COLUMN tmp_events.budget IS 'Planned budget in CZK.';
SELECT table_name, comments FROM user_tab_comments WHERE table_name IN ('TMP_EVENTS', 'PROJECT_NODES', 'MENU_REVISIONS');
-- DELETE vs TRUNCATE: DELETE can be rolled back, TRUNCATE cannot.
INSERT INTO tmp_events (event_id, title) VALUES (10, 'One');
INSERT INTO tmp_events (event_id, title) VALUES (11, 'Two');
COMMIT;
DELETE FROM tmp_events;
ROLLBACK;
SELECT COUNT(*) AS rows_after_delete_rollback FROM tmp_events;
-- DROP TABLE without PURGE puts the table into the recycle bin (USER_RECYCLEBIN); FLASHBACK brings it back.
DROP TABLE tmp_events;
SELECT original_name, type, droptime FROM user_recyclebin WHERE original_name = 'TMP_EVENTS';
FLASHBACK TABLE tmp_events TO BEFORE DROP;
SELECT COUNT(*) AS rows_after_flashback FROM tmp_events;
-- Final drop with PURGE bypasses the recycle bin (done for all scratch objects at the end).
DROP TABLE tmp_events PURGE;
SELECT COUNT(*) AS in_recyclebin_after_purge FROM user_recyclebin WHERE original_name = 'TMP_EVENTS';

-- =====================================================================
-- SQL S10 L01  CREATE TABLE ... AS SELECT, NOT NULL / UNIQUE, constraint names
-- =====================================================================
-- CTAS with a filter (names the columns, renames one): copies data and the NOT NULL constraints only,
-- no PK/FK/UNIQUE/CHECK and no triggers or defaults of the source table.
CREATE TABLE tmp_big_projects (project_id, project_name, guest_count) AS
SELECT project_id, name, guest_count FROM projects WHERE guest_count >= 150;
SELECT COUNT(*) AS big_projects_copied FROM tmp_big_projects;
-- The copy has only the NOT NULL constraints (system-named); the source also has PK, FK, CHECK.
SELECT (SELECT COUNT(*) FROM user_constraints WHERE table_name = 'TMP_BIG_PROJECTS') AS ctas_constraints,
       (SELECT COUNT(*) FROM user_constraints WHERE table_name = 'PROJECTS') AS source_constraints FROM dual;
-- A table with NOT NULL and UNIQUE; one constraint is named by us (CONSTRAINT uq_...), the others get SYS_C names.
CREATE TABLE tmp_staff (
  staff_id  NUMBER(5)          NOT NULL,
  badge     VARCHAR2(10 CHAR)  NOT NULL,
  email     VARCHAR2(100 CHAR) NOT NULL,
  CONSTRAINT pk_tmp_staff PRIMARY KEY (staff_id),
  CONSTRAINT uq_tmp_staff_badge UNIQUE (badge),
  UNIQUE (email)
);
-- Own vs system-generated constraint names (GENERATED column): our PK/UNIQUE/CHECK/FK carry the prefixes
-- pk_/uq_/ck_/fk_, only NOT NULL (type C) and the unnamed UNIQUE got SYS_C... names.
SELECT constraint_name, constraint_type, generated FROM user_constraints WHERE table_name = 'TMP_STAFF' ORDER BY constraint_type, constraint_name;
-- The same summary for the whole real schema: type P/R/U/C and how many of them are system-named.
SELECT constraint_type, generated, COUNT(*) AS constraints
FROM user_constraints WHERE table_name NOT LIKE 'TMP\_%' ESCAPE '\' AND table_name NOT LIKE 'BIN$%'
GROUP BY constraint_type, generated ORDER BY constraint_type, generated;
-- A violation of a named constraint tells us the rule at once (ORA-00001 shows UQ_TMP_STAFF_BADGE).
INSERT INTO tmp_staff VALUES (1, 'B001', 'a@catering.cz');
INSERT INTO tmp_staff VALUES (2, 'B002', 'b@catering.cz');
BEGIN
  INSERT INTO tmp_staff VALUES (3, 'B001', 'c@catering.cz');
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Rejected: ' || SQLERRM);
END;
/

-- =====================================================================
-- SQL S10 L02  PK, FK, CHECK, ON DELETE options
-- =====================================================================
-- PRIMARY KEY, FOREIGN KEY (column REFERENCES table) and CHECK; three children show the ON DELETE options.
CREATE TABLE tmp_parent (
  parent_id  NUMBER(5) PRIMARY KEY,
  name       VARCHAR2(30 CHAR) NOT NULL,
  capacity   NUMBER(4) CONSTRAINT ck_tmp_parent_capacity CHECK (capacity BETWEEN 1 AND 500)
);
-- default (no clause) = restrict: a parent with children cannot be deleted.
CREATE TABLE tmp_child_restrict (
  child_id NUMBER(5) PRIMARY KEY,
  parent_id NUMBER(5) CONSTRAINT fk_tmp_child_restrict REFERENCES tmp_parent (parent_id)
);
-- ON DELETE CASCADE: deleting the parent deletes the children (like menu_items under menu_categories).
CREATE TABLE tmp_child_cascade (
  child_id NUMBER(5) PRIMARY KEY,
  parent_id NUMBER(5) CONSTRAINT fk_tmp_child_cascade REFERENCES tmp_parent (parent_id) ON DELETE CASCADE
);
-- ON DELETE SET NULL: the child stays, its FK becomes NULL. (Oracle has no ON UPDATE clause at all.)
CREATE TABLE tmp_child_setnull (
  child_id NUMBER(5) PRIMARY KEY,
  parent_id NUMBER(5) CONSTRAINT fk_tmp_child_setnull REFERENCES tmp_parent (parent_id) ON DELETE SET NULL
);
INSERT INTO tmp_parent VALUES (1, 'Hall A', 100);
INSERT INTO tmp_parent VALUES (2, 'Hall B', 200);
INSERT INTO tmp_child_restrict VALUES (1, 1);
INSERT INTO tmp_child_cascade VALUES (1, 1);
INSERT INTO tmp_child_cascade VALUES (2, 1);
INSERT INTO tmp_child_setnull VALUES (1, 1);
-- CHECK rejects capacity 900; RESTRICT rejects deleting parent 1 while a child uses it.
BEGIN
  INSERT INTO tmp_parent VALUES (3, 'Hall C', 900);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('CHECK rejected: ' || SQLERRM);
END;
/
BEGIN
  DELETE FROM tmp_parent WHERE parent_id = 1;
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('RESTRICT rejected: ' || SQLERRM);
END;
/
-- Remove the restricting child, then delete: CASCADE removes 2 children, SET NULL keeps one with NULL parent.
DELETE FROM tmp_child_restrict;
DELETE FROM tmp_parent WHERE parent_id = 1;
SELECT (SELECT COUNT(*) FROM tmp_child_cascade) AS cascade_children_left,
       (SELECT COUNT(*) FROM tmp_child_setnull WHERE parent_id IS NULL) AS setnull_children_orphaned FROM dual;
COMMIT;

-- =====================================================================
-- SQL S10 L03  USER_CONSTRAINTS
-- =====================================================================
-- All constraints of the scratch tables: type (P/R/U/C), the CHECK text, the referenced constraint, ON DELETE rule.
SELECT table_name, constraint_name, constraint_type, search_condition, r_constraint_name, delete_rule
FROM user_constraints WHERE table_name LIKE 'TMP\_PARENT' ESCAPE '\' OR table_name LIKE 'TMP\_CHILD%' ESCAPE '\'
ORDER BY table_name, constraint_type, constraint_name;
-- Columns of the constraints (USER_CONS_COLUMNS) of one real table: what protects menu_items.
SELECT c.constraint_name, c.constraint_type, cc.column_name, c.delete_rule
FROM user_constraints c JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
WHERE c.table_name = 'MENU_ITEMS' AND c.constraint_type IN ('P', 'R', 'C') AND c.generated = 'USER NAME'
ORDER BY c.constraint_type, c.constraint_name, cc.position;
-- The CHECK constraints of the real schema (ARC, subtype and so on): own-named CHECKs and their text.
SELECT table_name, constraint_name, search_condition FROM user_constraints
WHERE constraint_type = 'C' AND generated = 'USER NAME' AND table_name IN ('COMMENTS', 'PROJECTS', 'PRODUCTS')
ORDER BY table_name, constraint_name;
-- ALTER TABLE ... ADD/DROP CONSTRAINT: add a constraint later and drop it by its name.
ALTER TABLE tmp_staff ADD CONSTRAINT ck_tmp_staff_badge CHECK (REGEXP_LIKE(badge, '^B[0-9]{3}$'));
SELECT constraint_name FROM user_constraints WHERE table_name = 'TMP_STAFF' AND constraint_type = 'C' AND generated = 'USER NAME';
ALTER TABLE tmp_staff DROP CONSTRAINT ck_tmp_staff_badge;

-- =====================================================================
-- SQL S11 L01  Views: simple, complex, FORCE, WITH CHECK OPTION, WITH READ ONLY
-- =====================================================================
-- Simple view (one table, no aggregation): DML through it changes the base table.
CREATE OR REPLACE VIEW tmp_v_confirmed AS
SELECT project_id, name, status, guest_count FROM tmp_projects WHERE status = 'CONFIRMED';
UPDATE tmp_v_confirmed SET guest_count = guest_count + 10 WHERE project_id = 1;
SELECT project_id, guest_count FROM tmp_projects WHERE project_id = 1;
-- Complex view (join + GROUP BY + functions): read-only in practice. Compare with the real v_menu_revision_totals.
CREATE OR REPLACE VIEW tmp_v_status_summary AS
SELECT status, COUNT(*) AS projects, SUM(guest_count) AS guests FROM tmp_projects GROUP BY status;
SELECT * FROM tmp_v_status_summary ORDER BY status;
BEGIN
  INSERT INTO tmp_v_status_summary VALUES ('X', 1, 1);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Complex view DML rejected: ' || SQLERRM);
END;
/
-- WITH CHECK OPTION: a row changed through the view must still satisfy the view's WHERE.
CREATE OR REPLACE VIEW tmp_v_confirmed_chk AS
SELECT project_id, name, status, guest_count FROM tmp_projects WHERE status = 'CONFIRMED' WITH CHECK OPTION CONSTRAINT ck_tmp_v_confirmed;
BEGIN
  UPDATE tmp_v_confirmed_chk SET status = 'DONE' WHERE project_id = 1;   -- would leave the view
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('WITH CHECK OPTION rejected: ' || SQLERRM);
END;
/
-- WITH READ ONLY: no DML at all (the real v_menu_revision_totals is created the same way).
CREATE OR REPLACE VIEW tmp_v_readonly AS SELECT project_id, name, status FROM tmp_projects WITH READ ONLY;
BEGIN
  DELETE FROM tmp_v_readonly WHERE project_id = 1;
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('WITH READ ONLY rejected: ' || SQLERRM);
END;
/
-- NOFORCE (default): a view over a missing table is refused.
BEGIN
  EXECUTE IMMEDIATE 'CREATE VIEW tmp_v_noforce AS SELECT * FROM tmp_future';
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('NOFORCE rejected: ' || SQLERRM);
END;
/
-- FORCE: the view is created INVALID (with compilation errors) and becomes valid when the table exists.
CREATE FORCE VIEW tmp_v_force AS SELECT * FROM tmp_future;
SELECT object_name, status FROM user_objects WHERE object_name = 'TMP_V_FORCE';
CREATE TABLE tmp_future (id NUMBER(3), label VARCHAR2(10 CHAR));
INSERT INTO tmp_future VALUES (1, 'later');
SELECT * FROM tmp_v_force;
SELECT object_name, status FROM user_objects WHERE object_name = 'TMP_V_FORCE';
-- Views in the dictionary: real view and its WITH READ ONLY option.
SELECT view_name, read_only FROM user_views WHERE view_name IN ('V_MENU_REVISION_TOTALS', 'TMP_V_READONLY', 'TMP_V_CONFIRMED') ORDER BY view_name;
COMMIT;

-- =====================================================================
-- SQL S11 L03  Inline view
-- =====================================================================
-- Subquery in FROM: average guests per customer city, then filtered like an ordinary table.
SELECT city, avg_guests FROM (
  SELECT c.city, ROUND(AVG(p.guest_count)) AS avg_guests
  FROM projects p JOIN customers c ON c.customer_id = p.customer_id GROUP BY c.city
) city_stats WHERE avg_guests >= 100 ORDER BY avg_guests DESC;
-- Inline view for top-N: the three most expensive products (ROWNUM must be applied after ORDER BY).
SELECT * FROM (SELECT name, current_price FROM products ORDER BY current_price DESC) WHERE ROWNUM <= 3;

-- =====================================================================
-- SQL S12 L01  Sequences with all options, ALTER SEQUENCE
-- =====================================================================
-- INCREMENT BY, START WITH, MAXVALUE, MINVALUE, CYCLE, CACHE all at once; after 120 it cycles back to MINVALUE 1.
CREATE SEQUENCE tmp_seq_all INCREMENT BY 10 START WITH 100 MAXVALUE 120 MINVALUE 1 CYCLE CACHE 2;
SELECT tmp_seq_all.NEXTVAL AS n1, tmp_seq_all.NEXTVAL AS n2, tmp_seq_all.NEXTVAL AS n3, tmp_seq_all.NEXTVAL AS after_cycle FROM dual;
SELECT tmp_seq_all.CURRVAL AS current_value FROM dual;
-- NOMAXVALUE, NOMINVALUE, NOCYCLE, NOCACHE (the style of the schema sequences), and a descending one.
CREATE SEQUENCE tmp_seq_plain START WITH 1 INCREMENT BY 1 NOMAXVALUE NOMINVALUE NOCYCLE NOCACHE;
CREATE SEQUENCE tmp_seq_down START WITH 5 INCREMENT BY -1 MAXVALUE 5 MINVALUE 1 NOCYCLE;
SELECT tmp_seq_plain.NEXTVAL AS up, tmp_seq_down.NEXTVAL AS down1, tmp_seq_down.NEXTVAL AS down2 FROM dual;
-- ALTER SEQUENCE: change the step, limit and cycling (START WITH cannot be altered).
ALTER SEQUENCE tmp_seq_all INCREMENT BY 1 MAXVALUE 1000 NOCYCLE NOCACHE;
SELECT tmp_seq_all.NEXTVAL AS after_alter FROM dual;
SELECT sequence_name, min_value, max_value, increment_by, cycle_flag, cache_size, last_number
FROM user_sequences WHERE sequence_name LIKE 'TMP\_SEQ%' ESCAPE '\' ORDER BY sequence_name;
-- Sequence as column DEFAULT (the pattern of the real tables) but with a scratch sequence.
SELECT COUNT(*) AS rows_with_sequence_default, MIN(booking_id) AS first_id FROM tmp_booking;

-- =====================================================================
-- SQL S12 L02  Indexes and constraints that create indexes
-- =====================================================================
-- CREATE INDEX (non-unique), UNIQUE INDEX, composite and function-based index.
CREATE INDEX tmp_ix_proj_status ON tmp_projects (status);
CREATE INDEX tmp_ix_proj_status_date ON tmp_projects (status, event_date DESC);
CREATE UNIQUE INDEX tmp_ux_proj_name ON tmp_projects (name);
CREATE INDEX tmp_ix_proj_lower_place ON tmp_projects (LOWER(event_place));
-- PRIMARY KEY and UNIQUE create their own index automatically; FOREIGN KEY does not (index the FK yourself).
ALTER TABLE tmp_projects ADD CONSTRAINT pk_tmp_projects PRIMARY KEY (project_id);
ALTER TABLE tmp_projects ADD CONSTRAINT uq_tmp_projects_date_name UNIQUE (event_date, name);
ALTER TABLE tmp_projects ADD CONSTRAINT fk_tmp_projects_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id);
SELECT i.index_name, i.uniqueness, i.index_type, c.column_name, c.column_position
FROM user_indexes i JOIN user_ind_columns c ON c.index_name = i.index_name
WHERE i.table_name = 'TMP_PROJECTS' ORDER BY i.index_name, c.column_position;
-- The real schema has one index per FK used for lookups (ix_...) plus the function-based unique ux_project_nodes_root.
SELECT index_name, table_name, uniqueness, index_type FROM user_indexes
WHERE index_name LIKE 'IX\_%' ESCAPE '\' OR index_name LIKE 'UX\_%' ESCAPE '\' ORDER BY table_name, index_name;
DROP INDEX tmp_ix_proj_status;

-- =====================================================================
-- SQL S13 L01  GRANT, REVOKE
-- =====================================================================
-- Which privileges exist (Oracle's list; TABLE_PRIVILEGE_MAP): ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ...
-- Per object type: TABLE: ALTER DELETE INDEX INSERT REFERENCES SELECT UPDATE | VIEW: DELETE INSERT SELECT UPDATE
-- SEQUENCE: ALTER SELECT | PROCEDURE: EXECUTE (INDEX and REFERENCES apply to tables only).
SELECT name AS privilege FROM table_privilege_map WHERE name IN ('ALTER', 'DELETE', 'EXECUTE', 'INDEX', 'INSERT', 'REFERENCES', 'SELECT', 'UPDATE') ORDER BY name;
-- GRANT on a table, a view, a sequence and a procedure to PUBLIC (every database user).
CREATE OR REPLACE PROCEDURE tmp_proc_hello AS BEGIN DBMS_OUTPUT.PUT_LINE('hello'); END;
/
GRANT SELECT, INSERT, UPDATE ON tmp_booking TO PUBLIC;
GRANT SELECT ON tmp_v_confirmed TO PUBLIC;
GRANT SELECT, ALTER ON tmp_seq_plain TO PUBLIC;
GRANT EXECUTE ON tmp_proc_hello TO PUBLIC;
-- Privileges the owner has given away (USER_TAB_PRIVS_MADE).
SELECT grantee, table_name, privilege FROM user_tab_privs_made WHERE table_name LIKE 'TMP\_%' ESCAPE '\' ORDER BY table_name, privilege;
-- REVOKE takes some of them back (a privilege can be revoked one by one).
REVOKE INSERT, UPDATE ON tmp_booking FROM PUBLIC;
REVOKE EXECUTE ON tmp_proc_hello FROM PUBLIC;
SELECT grantee, table_name, privilege FROM user_tab_privs_made WHERE table_name LIKE 'TMP\_%' ESCAPE '\' ORDER BY table_name, privilege;
REVOKE ALL ON tmp_booking FROM PUBLIC;

-- =====================================================================
-- SQL S13 L03  Regular expressions
-- =====================================================================
-- REGEXP_LIKE: phones in the international format +420 xxx xxx xxx.
SELECT name, phone FROM customers WHERE REGEXP_LIKE(phone, '^\+420 [0-9]{3} [0-9]{3} [0-9]{3}$') FETCH FIRST 5 ROWS ONLY;
-- REGEXP_LIKE, case-insensitive: e-mails on gmail or seznam.
SELECT name, email FROM customers WHERE REGEXP_LIKE(email, '@(gmail|seznam)\.', 'i');
-- REGEXP_REPLACE: reformat the phone number with back-references to groups.
SELECT phone, REGEXP_REPLACE(phone, '^\+420 ([0-9]{3}) ([0-9]{3}) ([0-9]{3})$', '(\1) \2-\3') AS reformatted
FROM customers WHERE phone IS NOT NULL FETCH FIRST 4 ROWS ONLY;
-- REGEXP_INSTR: position of the first digit in a product name and of the first space.
SELECT name, REGEXP_INSTR(name, '[0-9]') AS first_digit_pos, REGEXP_INSTR(name, '[[:space:]]') AS first_space_pos
FROM products WHERE REGEXP_LIKE(name, '[0-9]');
-- REGEXP_SUBSTR: the domain of an e-mail (sub-expression 1) and its top-level domain.
SELECT email, REGEXP_SUBSTR(email, '@(.+)$', 1, 1, NULL, 1) AS domain, REGEXP_SUBSTR(email, '[^.]+$') AS tld
FROM customers FETCH FIRST 5 ROWS ONLY;
-- REGEXP_COUNT: number of words in a product description.
SELECT name, REGEXP_COUNT(description, '[^ ]+') AS words FROM products WHERE description IS NOT NULL FETCH FIRST 5 ROWS ONLY;

-- =====================================================================
-- SQL S14 L01  Transactions: COMMIT, ROLLBACK, SAVEPOINT
-- =====================================================================
-- Scratch table first: SAVEPOINT a, SAVEPOINT b, partial rollback to b, rollback to a, final COMMIT.
DELETE FROM tmp_customers;
COMMIT;
INSERT INTO tmp_customers (customer_id, name, email) VALUES (201, 'Savepoint One', 'one@example.cz');
SAVEPOINT after_one;
INSERT INTO tmp_customers (customer_id, name, email) VALUES (202, 'Savepoint Two', 'two@example.cz');
SAVEPOINT after_two;
INSERT INTO tmp_customers (customer_id, name, email) VALUES (203, 'Savepoint Three', 'three@example.cz');
SELECT COUNT(*) AS inserted_three FROM tmp_customers;
-- Undoes only row 203
ROLLBACK TO after_two;
SELECT COUNT(*) AS after_rollback_to_two FROM tmp_customers;
-- Undoes row 202, the savepoint after_two no longer exists
ROLLBACK TO after_one;
SELECT COUNT(*) AS after_rollback_to_one FROM tmp_customers;
-- Row 201 is now permanent
COMMIT;
SELECT customer_id, name FROM tmp_customers;
-- ROLLBACK undoes everything since the last COMMIT.
DELETE FROM tmp_customers;
SELECT COUNT(*) AS after_delete FROM tmp_customers;
ROLLBACK;
SELECT COUNT(*) AS after_rollback FROM tmp_customers;
-- The same on a real table, finished with ROLLBACK (a real change is never committed here).
-- No sequence is involved: only the phone column of one customer is changed.
SAVEPOINT real_start;
UPDATE customers SET phone = '+420 000 000 000' WHERE customer_id = 1;
SELECT phone AS phone_inside_transaction FROM customers WHERE customer_id = 1;
ROLLBACK TO real_start;
ROLLBACK;
SELECT phone AS phone_after_rollback FROM customers WHERE customer_id = 1;

-- =====================================================================
-- SQL S15 L01  Joins without JOIN (condition in WHERE), (+) outer joins
-- =====================================================================
-- Old-style inner join: tables listed in FROM, join condition in WHERE.
SELECT p.name AS project, c.name AS customer
FROM projects p, customers c
WHERE p.customer_id = c.customer_id AND p.status = 'CONFIRMED';
-- Left outer join with (+): the (+) goes on the side that may have no row; keeps all customers.
SELECT c.name AS customer, p.name AS project
FROM customers c, projects p
WHERE c.customer_id = p.customer_id (+) AND p.project_id IS NULL ORDER BY c.name FETCH FIRST 5 ROWS ONLY;
-- Right outer join with (+): keeps all users, also those with no project.
SELECT p.name AS project, u.username
FROM projects p, users u
WHERE p.responsible_user_id (+) = u.user_id AND p.project_id IS NULL ORDER BY u.username;
-- Self join in the old style: employee and supervisor.
SELECT e.username AS employee, s.username AS supervisor
FROM users e, users s WHERE e.supervisor_id = s.user_id (+) ORDER BY e.user_id;

-- =====================================================================
-- SQL S16 L03  Recap: everything not shown above
-- =====================================================================
-- Top-N and pagination (12c+): the 3 biggest projects, then the next 3.
SELECT name, guest_count FROM projects ORDER BY guest_count DESC FETCH FIRST 3 ROWS ONLY;
SELECT name, guest_count FROM projects ORDER BY guest_count DESC OFFSET 3 ROWS FETCH NEXT 3 ROWS ONLY;
-- LISTAGG: all allergens of one product in one text cell.
SELECT p.name, LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.allergen_id) AS allergens
FROM products p JOIN product_allergens pa ON pa.product_id = p.product_id JOIN allergens a ON a.allergen_id = pa.allergen_id
WHERE p.product_id IN (1, 5, 13) GROUP BY p.name ORDER BY p.name;
-- Analytic functions: rank of a project by guests inside its status, and running total of guests by date.
SELECT name, status, guest_count, RANK() OVER (PARTITION BY status ORDER BY guest_count DESC) AS rank_in_status,
       SUM(guest_count) OVER (ORDER BY event_date) AS running_guests
FROM projects ORDER BY event_date;
-- LAG: price journal with the previous price of the same product (history of changes over time).
SELECT product_id, changed_at, old_price, new_price, LAG(new_price) OVER (PARTITION BY product_id ORDER BY changed_at) AS prev_new_price
FROM product_price_history WHERE product_id IN (1, 24) ORDER BY product_id, changed_at;
-- PIVOT: projects per status as columns.
SELECT * FROM (SELECT status, guest_count FROM projects)
PIVOT (COUNT(*) AS projects FOR status IN ('IN_PROGRESS' AS in_progress, 'CONFIRMED' AS confirmed, 'DONE' AS done, 'ARCHIVED' AS archived));
-- CAST, EXTRACT, SYSTIMESTAMP, USER, CURRENT_DATE in one row.
SELECT CAST(current_price AS NUMBER(6)) AS price_int, EXTRACT(YEAR FROM SYSDATE) AS this_year, USER AS who, SYSTIMESTAMP AS now_with_zone
FROM products WHERE product_id = 7;
-- ROWNUM, NULLS LAST and a correlated scalar subquery: customers, number of their projects, empty cities last.
SELECT c.name, c.company_name, (SELECT COUNT(*) FROM projects p WHERE p.customer_id = c.customer_id) AS projects
FROM customers c ORDER BY projects DESC, c.company_name NULLS LAST, c.name FETCH FIRST 5 ROWS ONLY;
-- Data dictionary: tables of the schema with row estimates and comments (everything is in USER_* views).
SELECT table_name, num_rows FROM user_tables WHERE table_name NOT LIKE 'TMP\_%' ESCAPE '\' ORDER BY table_name FETCH FIRST 5 ROWS ONLY;

BEGIN
  FOR o IN (SELECT object_name, object_type FROM user_objects
            WHERE object_name LIKE 'TMP\_%' ESCAPE '\' AND object_type IN ('VIEW', 'SYNONYM', 'PROCEDURE', 'SEQUENCE')) LOOP
    EXECUTE IMMEDIATE 'DROP ' || o.object_type || ' ' || o.object_name;
  END LOOP;
  FOR t IN (SELECT table_name FROM user_tables WHERE table_name LIKE 'TMP\_%' ESCAPE '\') LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
  FOR r IN (SELECT object_name FROM user_recyclebin WHERE original_name LIKE 'TMP\_%' ESCAPE '\' AND type = 'TABLE') LOOP
    EXECUTE IMMEDIATE 'PURGE TABLE "' || r.object_name || '"';
  END LOOP;
END;
/
-- Final cleanup above: every scratch object is dropped with PURGE (no recycle bin).
-- Proof: no scratch object is left, and the row counts are the seed counts (10, 10, 77, 36, 346, 24, 12, 10).
SELECT (SELECT COUNT(*) FROM user_objects WHERE object_name LIKE 'TMP\_%' ESCAPE '\') AS scratch_objects_left,
       (SELECT COUNT(*) FROM user_recyclebin WHERE original_name LIKE 'TMP\_%' ESCAPE '\') AS scratch_in_recyclebin,
       (SELECT COUNT(*) FROM users) AS users, (SELECT COUNT(*) FROM projects) AS projects,
       (SELECT COUNT(*) FROM project_nodes) AS nodes, (SELECT COUNT(*) FROM menu_revisions) AS revisions,
       (SELECT COUNT(*) FROM menu_items) AS items, (SELECT COUNT(*) FROM comments) AS comments,
       (SELECT COUNT(*) FROM share_links) AS links, (SELECT COUNT(*) FROM product_price_history) AS price_history
FROM dual;
ROLLBACK;

