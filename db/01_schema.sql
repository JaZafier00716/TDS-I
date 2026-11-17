-- =====================================================================
-- Catering IS - database schema (Oracle 19c and newer)
-- Shared by the VIS project (application database) and the TDS project.
-- Run as the schema owner (local: CATERING). The script can be re-run:
-- the first block drops all objects of this schema that it creates.
-- =====================================================================

SET DEFINE OFF

-- ---------------------------------------------------------------------
-- 0. Drop existing objects (idempotent, no IF EXISTS so it runs on 19c)
-- ---------------------------------------------------------------------
BEGIN
  FOR t IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('COMMENTS', 'SHARE_LINKS', 'MENU_ITEMS', 'MENU_CATEGORIES',
                                 'MENU_REVISIONS', 'MENUS', 'PRODUCT_PRICE_HISTORY',
                                 'PRODUCT_ALLERGENS', 'ALLERGENS', 'PRODUCTS', 'PROJECT_NODES',
                                 'PROJECTS', 'CUSTOMERS', 'USER_ROLES', 'USERS', 'ROLES')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
  FOR s IN (SELECT sequence_name FROM user_sequences
            WHERE sequence_name IN ('SEQ_USERS', 'SEQ_CUSTOMERS', 'SEQ_PROJECTS', 'SEQ_PROJECT_NODES',
                                    'SEQ_MENUS', 'SEQ_MENU_CATEGORIES', 'SEQ_PRODUCTS',
                                    'SEQ_PRICE_HISTORY', 'SEQ_SHARE_LINKS', 'SEQ_COMMENTS')) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
END;
/

-- ---------------------------------------------------------------------
-- 1. Sequences (surrogate keys)
-- ---------------------------------------------------------------------
CREATE SEQUENCE seq_users           START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_customers       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_projects        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_project_nodes   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_menus           START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_menu_categories START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_products        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_price_history   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_share_links     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_comments        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- ---------------------------------------------------------------------
-- 2. Users and roles
-- ---------------------------------------------------------------------
CREATE TABLE roles (
  role_code   CHAR(7)            NOT NULL,
  name        VARCHAR2(50 CHAR)  NOT NULL,
  CONSTRAINT pk_roles PRIMARY KEY (role_code),
  CONSTRAINT uq_roles_name UNIQUE (name),
  CONSTRAINT ck_roles_code CHECK (role_code IN ('ADMIN', 'WORKER', 'MANAGER'))
);

CREATE TABLE users (
  user_id        NUMBER(10)          DEFAULT seq_users.NEXTVAL NOT NULL,
  username       VARCHAR2(30 CHAR)   NOT NULL,
  full_name      VARCHAR2(100 CHAR)  NOT NULL,
  email          VARCHAR2(254 CHAR)  NOT NULL,
  password_hash  VARCHAR2(200 CHAR)  NOT NULL,          -- PBKDF2: iterations:salt:hash (hex)
  active         CHAR(1)             DEFAULT 'Y' NOT NULL,
  supervisor_id  NUMBER(10),                             -- recursive: who the user reports to
  created_at     TIMESTAMP           DEFAULT LOCALTIMESTAMP NOT NULL,
  CONSTRAINT pk_users PRIMARY KEY (user_id),
  CONSTRAINT uq_users_username UNIQUE (username),
  CONSTRAINT ck_users_active CHECK (active IN ('Y', 'N')),
  CONSTRAINT ck_users_email CHECK (REGEXP_LIKE(email, '^[^@ ]+@[^@ ]+\.[a-z]{2,}$', 'i')),
  CONSTRAINT ck_users_no_self_supervisor CHECK (supervisor_id <> user_id),
  CONSTRAINT fk_users_supervisor FOREIGN KEY (supervisor_id) REFERENCES users (user_id)
);

-- M:N without attributes
CREATE TABLE user_roles (
  user_id    NUMBER(10)  NOT NULL,
  role_code  CHAR(7)     NOT NULL,
  CONSTRAINT pk_user_roles PRIMARY KEY (user_id, role_code),
  CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_user_roles_role FOREIGN KEY (role_code) REFERENCES roles (role_code)
);

-- ---------------------------------------------------------------------
-- 3. Customers and projects
-- ---------------------------------------------------------------------
CREATE TABLE customers (
  customer_id   NUMBER(10)          DEFAULT seq_customers.NEXTVAL NOT NULL,
  name          VARCHAR2(100 CHAR)  NOT NULL,
  company_name  VARCHAR2(100 CHAR),
  email         VARCHAR2(254 CHAR)  NOT NULL,
  phone         VARCHAR2(20 CHAR),
  city          VARCHAR2(60 CHAR),
  CONSTRAINT pk_customers PRIMARY KEY (customer_id),
  CONSTRAINT uq_customers_email UNIQUE (email),
  CONSTRAINT ck_customers_phone CHECK (phone IS NULL OR REGEXP_LIKE(phone, '^\+?[0-9 ]{9,20}$'))
);

CREATE TABLE projects (
  project_id           NUMBER(10)           DEFAULT seq_projects.NEXTVAL NOT NULL,
  customer_id          NUMBER(10)           NOT NULL,   -- non-transferable (see trigger)
  responsible_user_id  NUMBER(10)           NOT NULL,   -- transferable
  name                 VARCHAR2(120 CHAR)   NOT NULL,
  event_date           DATE                 NOT NULL,
  event_duration       INTERVAL DAY(1) TO SECOND(0) DEFAULT INTERVAL '0 06:00:00' DAY TO SECOND NOT NULL,
  event_place          VARCHAR2(200 CHAR)   NOT NULL,
  guest_count          NUMBER(5)            NOT NULL,
  status               VARCHAR2(12 CHAR)    DEFAULT 'IN_PROGRESS' NOT NULL,
  retention_period     INTERVAL YEAR(2) TO MONTH DEFAULT INTERVAL '5-0' YEAR TO MONTH NOT NULL,
  note                 CLOB,
  created_at           TIMESTAMP            DEFAULT LOCALTIMESTAMP NOT NULL,
  CONSTRAINT pk_projects PRIMARY KEY (project_id),
  CONSTRAINT fk_projects_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
  CONSTRAINT fk_projects_user FOREIGN KEY (responsible_user_id) REFERENCES users (user_id),
  CONSTRAINT ck_projects_guests CHECK (guest_count > 0),
  CONSTRAINT ck_projects_status CHECK (status IN ('IN_PROGRESS', 'CONFIRMED', 'DONE', 'ARCHIVED'))
);

-- Project content: folder tree (Single Table Inheritance, subtypes FOLDER and DOCUMENT;
-- recursive relationship through parent_id). Document content lives in the file storage,
-- the row keeps only its metadata and storage key.
CREATE TABLE project_nodes (
  node_id       NUMBER(10)          DEFAULT seq_project_nodes.NEXTVAL NOT NULL,
  project_id    NUMBER(10)          NOT NULL,
  parent_id     NUMBER(10),                              -- NULL = root folder of the project
  node_type     VARCHAR2(8 CHAR)    NOT NULL,            -- discriminator
  name          VARCHAR2(255 CHAR)  NOT NULL,
  created_at    TIMESTAMP           DEFAULT LOCALTIMESTAMP NOT NULL,
  content_type  VARCHAR2(100 CHAR),                      -- DOCUMENT only
  size_bytes    NUMBER(12),                              -- DOCUMENT only
  storage_key   VARCHAR2(200 CHAR),                      -- DOCUMENT only
  CONSTRAINT pk_project_nodes PRIMARY KEY (node_id),
  CONSTRAINT fk_project_nodes_project FOREIGN KEY (project_id) REFERENCES projects (project_id) ON DELETE CASCADE,
  CONSTRAINT fk_project_nodes_parent FOREIGN KEY (parent_id) REFERENCES project_nodes (node_id) ON DELETE CASCADE,
  CONSTRAINT uq_project_nodes_sibling UNIQUE (parent_id, name),
  CONSTRAINT uq_project_nodes_storage UNIQUE (storage_key),
  CONSTRAINT ck_project_nodes_type CHECK (node_type IN ('FOLDER', 'DOCUMENT', 'MENU')),
  CONSTRAINT ck_project_nodes_subtype CHECK (
       (node_type IN ('FOLDER', 'MENU') AND content_type IS NULL AND size_bytes IS NULL AND storage_key IS NULL
        AND (node_type = 'FOLDER' OR parent_id IS NOT NULL))
    OR (node_type = 'DOCUMENT' AND parent_id IS NOT NULL AND content_type IS NOT NULL
        AND size_bytes BETWEEN 0 AND 20971520 AND storage_key IS NOT NULL)),
  CONSTRAINT ck_project_nodes_no_self CHECK (parent_id IS NULL OR parent_id <> node_id)
);

-- exactly one root folder per project
CREATE UNIQUE INDEX ux_project_nodes_root ON project_nodes (CASE WHEN parent_id IS NULL THEN project_id END);

-- ---------------------------------------------------------------------
-- 4. Product catalogue
-- ---------------------------------------------------------------------
CREATE TABLE products (
  product_id     NUMBER(10)          DEFAULT seq_products.NEXTVAL NOT NULL,
  name           VARCHAR2(100 CHAR)  NOT NULL,
  description    VARCHAR2(500 CHAR),
  unit           VARCHAR2(10 CHAR)   NOT NULL,
  current_price  NUMBER(10, 2)       NOT NULL,
  vat_rate       NUMBER(4, 2)        DEFAULT 12 NOT NULL,
  photo          BLOB,
  CONSTRAINT pk_products PRIMARY KEY (product_id),
  CONSTRAINT uq_products_name UNIQUE (name),
  CONSTRAINT ck_products_price CHECK (current_price >= 0),
  CONSTRAINT ck_products_vat CHECK (vat_rate IN (0, 12, 21)),
  CONSTRAINT ck_products_unit CHECK (unit IN ('pcs', 'portion', 'kg', 'l', 'set'))
);

CREATE TABLE allergens (
  allergen_id  NUMBER(2)          NOT NULL,              -- EU allergen number 1-14
  name         VARCHAR2(60 CHAR)  NOT NULL,
  CONSTRAINT pk_allergens PRIMARY KEY (allergen_id),
  CONSTRAINT ck_allergens_id CHECK (allergen_id BETWEEN 1 AND 14)
);

-- M:N without attributes
CREATE TABLE product_allergens (
  product_id   NUMBER(10)  NOT NULL,
  allergen_id  NUMBER(2)   NOT NULL,
  CONSTRAINT pk_product_allergens PRIMARY KEY (product_id, allergen_id),
  CONSTRAINT fk_product_allergens_product FOREIGN KEY (product_id) REFERENCES products (product_id) ON DELETE CASCADE,
  CONSTRAINT fk_product_allergens_allergen FOREIGN KEY (allergen_id) REFERENCES allergens (allergen_id)
);

-- Journal of previous prices (filled by trigger trg_products_price_history)
CREATE TABLE product_price_history (
  history_id  NUMBER(10)     DEFAULT seq_price_history.NEXTVAL NOT NULL,
  product_id  NUMBER(10)     NOT NULL,
  old_price   NUMBER(10, 2)  NOT NULL,
  new_price   NUMBER(10, 2)  NOT NULL,
  changed_at  TIMESTAMP      DEFAULT LOCALTIMESTAMP NOT NULL,
  changed_by  VARCHAR2(128 CHAR) DEFAULT USER NOT NULL,
  CONSTRAINT pk_product_price_history PRIMARY KEY (history_id),
  CONSTRAINT fk_price_history_product FOREIGN KEY (product_id) REFERENCES products (product_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- 5. Menus and their revisions (history of changes over time)
-- ---------------------------------------------------------------------
CREATE TABLE menus (
  menu_id     NUMBER(10)          DEFAULT seq_menus.NEXTVAL NOT NULL,
  project_id  NUMBER(10)          NOT NULL,              -- non-transferable (see trigger)
  node_id     NUMBER(10)          NOT NULL,              -- MENU node in the project tree (1:1)
  name        VARCHAR2(100 CHAR)  NOT NULL,
  CONSTRAINT pk_menus PRIMARY KEY (menu_id),
  CONSTRAINT fk_menus_project FOREIGN KEY (project_id) REFERENCES projects (project_id) ON DELETE CASCADE,
  CONSTRAINT uq_menus_node UNIQUE (node_id),
  CONSTRAINT fk_menus_node FOREIGN KEY (node_id) REFERENCES project_nodes (node_id) ON DELETE CASCADE
);

-- Identifying 1:N: menu_id (FK) is part of the primary key
CREATE TABLE menu_revisions (
  menu_id      NUMBER(10)        NOT NULL,
  revision_no  NUMBER(4)         NOT NULL,
  state        VARCHAR2(8 CHAR)  DEFAULT 'WORKING' NOT NULL,
  note         VARCHAR2(500 CHAR),
  created_by   NUMBER(10)        NOT NULL,
  created_at   TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,
  CONSTRAINT pk_menu_revisions PRIMARY KEY (menu_id, revision_no),
  CONSTRAINT fk_menu_revisions_menu FOREIGN KEY (menu_id) REFERENCES menus (menu_id) ON DELETE CASCADE,
  CONSTRAINT fk_menu_revisions_user FOREIGN KEY (created_by) REFERENCES users (user_id),
  CONSTRAINT ck_menu_revisions_no CHECK (revision_no >= 1),
  CONSTRAINT ck_menu_revisions_state CHECK (state IN ('WORKING', 'SHARED'))
);

CREATE TABLE menu_categories (
  category_id  NUMBER(10)         DEFAULT seq_menu_categories.NEXTVAL NOT NULL,
  menu_id      NUMBER(10)         NOT NULL,
  revision_no  NUMBER(4)          NOT NULL,
  name         VARCHAR2(60 CHAR)  NOT NULL,
  position     NUMBER(3)          NOT NULL,
  CONSTRAINT pk_menu_categories PRIMARY KEY (category_id),
  CONSTRAINT fk_menu_categories_revision FOREIGN KEY (menu_id, revision_no)
    REFERENCES menu_revisions (menu_id, revision_no) ON DELETE CASCADE,
  CONSTRAINT uq_menu_categories_name UNIQUE (menu_id, revision_no, name),
  CONSTRAINT ck_menu_categories_position CHECK (position >= 1)
);

-- M:N with attributes (category of a revision x product: quantity, price)
CREATE TABLE menu_items (
  category_id  NUMBER(10)     NOT NULL,
  product_id   NUMBER(10)     NOT NULL,
  quantity     NUMBER(8, 2)   NOT NULL,
  unit_price   NUMBER(10, 2)  NOT NULL,
  note         VARCHAR2(200 CHAR),
  CONSTRAINT pk_menu_items PRIMARY KEY (category_id, product_id),
  CONSTRAINT fk_menu_items_category FOREIGN KEY (category_id) REFERENCES menu_categories (category_id) ON DELETE CASCADE,
  CONSTRAINT fk_menu_items_product FOREIGN KEY (product_id) REFERENCES products (product_id),
  CONSTRAINT ck_menu_items_quantity CHECK (quantity > 0),
  CONSTRAINT ck_menu_items_price CHECK (unit_price >= 0)
);

-- ---------------------------------------------------------------------
-- 6. Sharing with the customer and comments
-- ---------------------------------------------------------------------
CREATE TABLE share_links (
  link_id      NUMBER(10)  DEFAULT seq_share_links.NEXTVAL NOT NULL,
  menu_id      NUMBER(10)  NOT NULL,
  revision_no  NUMBER(4)   NOT NULL,
  token        CHAR(32)    NOT NULL,
  created_at   TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,
  valid_until  TIMESTAMP WITH TIME ZONE NOT NULL,
  active       CHAR(1)     DEFAULT 'Y' NOT NULL,
  CONSTRAINT pk_share_links PRIMARY KEY (link_id),
  CONSTRAINT uq_share_links_token UNIQUE (token),
  CONSTRAINT fk_share_links_revision FOREIGN KEY (menu_id, revision_no)
    REFERENCES menu_revisions (menu_id, revision_no) ON DELETE CASCADE,
  CONSTRAINT ck_share_links_active CHECK (active IN ('Y', 'N')),
  CONSTRAINT ck_share_links_validity CHECK (valid_until > created_at)
);

-- ARC: a comment is about the whole menu revision OR about one menu item, never both
CREATE TABLE comments (
  comment_id   NUMBER(10)          DEFAULT seq_comments.NEXTVAL NOT NULL,
  menu_id      NUMBER(10),
  revision_no  NUMBER(4),
  category_id  NUMBER(10),
  product_id   NUMBER(10),
  author_name  VARCHAR2(100 CHAR)  NOT NULL,
  body         VARCHAR2(2000 CHAR) NOT NULL,
  created_at   TIMESTAMP WITH LOCAL TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,
  resolved     CHAR(1)             DEFAULT 'N' NOT NULL,
  resolution_note VARCHAR2(200 CHAR),
  resolved_by  NUMBER(10),
  resolved_at  TIMESTAMP,
  CONSTRAINT pk_comments PRIMARY KEY (comment_id),
  CONSTRAINT fk_comments_revision FOREIGN KEY (menu_id, revision_no)
    REFERENCES menu_revisions (menu_id, revision_no) ON DELETE CASCADE,
  CONSTRAINT fk_comments_item FOREIGN KEY (category_id, product_id)
    REFERENCES menu_items (category_id, product_id) ON DELETE CASCADE,
  CONSTRAINT ck_comments_resolved CHECK (resolved IN ('Y', 'N')),
  CONSTRAINT fk_comments_resolved_by FOREIGN KEY (resolved_by) REFERENCES users (user_id),
  CONSTRAINT ck_comments_resolution CHECK (
       (resolved = 'N' AND resolved_by IS NULL AND resolved_at IS NULL AND resolution_note IS NULL)
    OR (resolved = 'Y' AND resolved_by IS NOT NULL AND resolved_at IS NOT NULL)),
  CONSTRAINT ck_comments_arc CHECK (
       (menu_id IS NOT NULL AND revision_no IS NOT NULL AND category_id IS NULL AND product_id IS NULL)
    OR (menu_id IS NULL AND revision_no IS NULL AND category_id IS NOT NULL AND product_id IS NOT NULL))
);

-- ---------------------------------------------------------------------
-- 7. Indexes on foreign keys used for lookups
-- ---------------------------------------------------------------------
CREATE INDEX ix_projects_customer   ON projects (customer_id);
CREATE INDEX ix_projects_event_date ON projects (event_date);
CREATE INDEX ix_project_nodes_proj  ON project_nodes (project_id);
CREATE INDEX ix_menus_project       ON menus (project_id);
CREATE INDEX ix_menu_items_product  ON menu_items (product_id);
CREATE INDEX ix_comments_revision   ON comments (menu_id, revision_no);
CREATE INDEX ix_comments_item       ON comments (category_id, product_id);
CREATE INDEX ix_share_links_menu    ON share_links (menu_id, active);

-- ---------------------------------------------------------------------
-- 8. Triggers
-- ---------------------------------------------------------------------
-- Journaling: every price change of a product is written to the price history.
CREATE OR REPLACE TRIGGER trg_products_price_history
  AFTER UPDATE OF current_price ON products
  FOR EACH ROW
  WHEN (OLD.current_price <> NEW.current_price)
BEGIN
  INSERT INTO product_price_history (product_id, old_price, new_price)
  VALUES (:OLD.product_id, :OLD.current_price, :NEW.current_price);
END;
/

-- Non-transferable relationships: a project cannot move to another customer
-- and a menu cannot move to another project.
CREATE OR REPLACE TRIGGER trg_projects_customer_fixed
  BEFORE UPDATE OF customer_id ON projects
  FOR EACH ROW
  WHEN (OLD.customer_id <> NEW.customer_id)
BEGIN
  RAISE_APPLICATION_ERROR(-20001, 'A project cannot be moved to another customer.');
END;
/

CREATE OR REPLACE TRIGGER trg_menus_project_fixed
  BEFORE UPDATE OF project_id ON menus
  FOR EACH ROW
  WHEN (OLD.project_id <> NEW.project_id)
BEGIN
  RAISE_APPLICATION_ERROR(-20002, 'A menu cannot be moved to another project.');
END;
/

-- ---------------------------------------------------------------------
-- 9. View: totals of every menu revision (used by the application lists)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_menu_revision_totals AS
SELECT r.menu_id,
       r.revision_no,
       m.project_id,
       m.name                                   AS menu_name,
       r.state,
       r.created_at,
       COUNT(i.product_id)                      AS item_count,
       NVL(SUM(i.quantity * i.unit_price), 0)   AS total_price,
       ROUND(NVL(SUM(i.quantity * i.unit_price), 0) / p.guest_count, 2) AS price_per_guest
FROM menu_revisions r
JOIN menus m           ON m.menu_id = r.menu_id
JOIN projects p        ON p.project_id = m.project_id
LEFT JOIN menu_categories c ON c.menu_id = r.menu_id AND c.revision_no = r.revision_no
LEFT JOIN menu_items i ON i.category_id = c.category_id
GROUP BY r.menu_id, r.revision_no, m.project_id, m.name, r.state, r.created_at, p.guest_count
WITH READ ONLY;

COMMENT ON TABLE project_nodes IS 'Project content tree: folders and documents (single table inheritance).';
COMMENT ON TABLE product_price_history IS 'Journal of previous product prices, filled by trigger.';
COMMENT ON TABLE menu_revisions IS 'Every saved change of a menu is a new revision; revisions are never overwritten.';
