# Catering IS – database design notes (TDS)

The schema in `01_schema.sql` is derived from the conceptual domain model in artefact 3 of the VIS
documentation (VIS project, `VIS/projekt/docs/artefacts/diagrams/domain-model.puml`). The same database is the
application database of the VIS project.

Scripts:

| File | Content |
|---|---|
| `01_schema.sql` | DDL: drop block (re-runnable), 10 sequences, 16 tables with named constraints, 9 indexes, 3 triggers, 1 view, table comments |
| `02_seed.sql` | test data (10 users, 20 customers, 10 projects, 65 folder/document nodes + 12 menu nodes, 24 products, 12 menus with 2–4 revisions, share links, comments, price history) |
| `03_checks.sql` | row counts, hierarchical query, view output, price journal, integrity checks, tests that the database rejects invalid data |
| `04_queries.sql` | query catalogue: one example per SQL topic of the assignment; read-only except scratch objects it drops; run after 02 |

The SQL uses only features available in Oracle 19c, so it runs on the school server
(`dbsys.cs.vsb.cz`) as well as on the local Oracle 23ai Free container.

## Tables

| Table | Meaning | Key |
|---|---|---|
| `roles` | user roles ADMIN, WORKER, MANAGER | `role_code` (natural key, CHAR) |
| `users` | user accounts; `supervisor_id` = who the user reports to | `user_id` (sequence) |
| `user_roles` | which user has which role (M:N without attributes) | `user_id, role_code` |
| `customers` | customers ordering catering | `customer_id` |
| `projects` | one catering order / event | `project_id` |
| `project_nodes` | folder tree with documents and menus (supertype/subtype in one table) | `node_id` |
| `products` | catalogue of dishes and drinks, small photo as BLOB | `product_id` |
| `allergens` | EU allergens 1–14 | `allergen_id` (natural key) |
| `product_allergens` | allergens of a product (M:N without attributes) | `product_id, allergen_id` |
| `product_price_history` | journal of previous product prices | `history_id` |
| `menus` | menus of a project; `node_id` links the menu to its MENU node in the tree (1:1) | `menu_id` |
| `menu_revisions` | saved versions of a menu (identifying relationship) | `menu_id, revision_no` |
| `menu_categories` | categories of one revision (starters, main course …) | `category_id` |
| `menu_items` | products in a category with quantity and price (M:N with attributes) | `category_id, product_id` |
| `share_links` | links that make a revision visible to the customer | `link_id` |
| `comments` | customer comments on a revision or on one item (ARC); a resolved comment stores note, who (`resolved_by`) and when | `comment_id` |

## TDS checklist (Database Design part) → where it is in the schema

| Item | Where |
|---|---|
| **S01 L02 Data vs information** | Data: rows of `menu_items` (product 7, quantity 120, unit price 210). Information: "the wedding menu, revision 3, costs 115 750 CZK, i.e. 965 CZK per guest", computed by `v_menu_revision_totals`. |
| **S02 L02 Entities, instances, attributes, identifiers** | Entity `PROJECT`; instance "Svatba Novákovi"; attributes name, event date, place, guest count; identifier `project_id`. Natural identifiers: `roles.role_code`, `allergens.allergen_id`, `users.username` (unique), `share_links.token` (unique). |
| **S03 L01 Relationships (two sentences each)** | see "Relationships" below. |
| **SQL topics (queries)** | one example per SQL topic of the assignment in `04_queries.sql`. |
| **S03 L02 ER diagram** | to be drawn in SQL Developer Data Modeler (import `01_schema.sql`). |
| **S03/S30 L04 Matrix diagram** | see "Relationship matrix" below. |
| **S04 L01 Supertype and subtypes** | `PROJECT_NODE` with subtypes `FOLDER`, `DOCUMENT` and `MENU`, implemented as one table with the discriminator `node_type`; `ck_project_nodes_subtype` makes the document-only columns mandatory for documents and empty for folders. |
| **S04 L02 Business rules** | see "Business rules" below. |
| **S05 L01 Transferable / non-transferable relationship** | Transferable: `projects.responsible_user_id` (a project can be handed over to another worker). Non-transferable: `projects.customer_id` and `menus.project_id`; triggers `trg_projects_customer_fixed` and `trg_menus_project_fixed` reject changing them. |
| **S05 L03 M:N without attributes** | `user_roles` (users × roles), `product_allergens` (products × allergens). |
| **S05 L03 M:N with attributes** | `menu_items` (menu categories × products, with `quantity`, `unit_price`, `note`). |
| **S06 L01 Identifying 1:N (FK part of the PK)** | `menu_revisions` PK = (`menu_id`, `revision_no`): a revision only exists inside its menu. Also `user_roles`, `product_allergens`, `menu_items` (keys made of foreign keys). |
| **S06 L02–04 1NF, 2NF, 3NF** | see "Normal forms" below. |
| **S07 L01 ARC** | `comments`: a comment belongs either to a whole revision (`menu_id`, `revision_no`) or to one item (`category_id`, `product_id`), never both; `ck_comments_arc`. |
| **S07 L02 Hierarchical and recursive relationships** | Recursive: `project_nodes.parent_id → project_nodes.node_id` (folder tree), `users.supervisor_id → users.user_id` (org chart). Hierarchical: project → menu → revision → category → item. Query: `03_checks.sql` section 2 (`START WITH … CONNECT BY PRIOR`). |
| **S07 L03 Historical data** | Menus are never overwritten: every change creates a new row in `menu_revisions` with its own categories and items; `created_at`, `created_by` and `note` say when, who and why. Projects keep `retention_period` (INTERVAL YEAR TO MONTH) after which they may be deleted. |
| **S09 L01 Changes over time** | `menu_revisions` (whole menu versions over time), `share_links.valid_until`, `comments.resolved` with `resolved_at`/`resolved_by`. |
| **S09 L02 Journaling** | `product_price_history`: trigger `trg_products_price_history` writes the old and new price, time and database user for every price change. |
| **S10 L01 Readability conventions** | Plural table names in English, `snake_case`, PK `<table>_id`, constraint prefixes `pk_`, `fk_`, `uq_`, `ck_`, indexes `ix_`/`ux_`, sequences `seq_`, triggers `trg_`, views `v_`. |
| **S10 L02 Generic modelling** | Considered for product properties (allergens, dietary labels) as an entity–attribute–value table. Not used: allergens are a fixed EU list of 14, so the specific M:N table is simpler, keeps foreign keys and is easier to query. The generic approach would pay off only if users defined new kinds of properties themselves. |
| **S11 L01 Integrity constraints** | Entity: primary keys, `NOT NULL`. Referential: foreign keys with `ON DELETE CASCADE` for dependent data (nodes, menus, revisions, items), restrict for the rest. Attribute (domain): `ck_projects_guests`, `ck_menu_items_quantity`, `ck_products_vat`, `ck_users_email` (regular expression), `ck_users_no_self_supervisor`. User-defined: one root folder per project (`ux_project_nodes_root`), unique names in a folder (also between folders, documents and menus), ARC, `ck_comments_resolution`, STI subtype check, non-transferable triggers. |
| **S11 L02–04 Relational schema from the conceptual model** | Changes against the domain model: M:N relationships became tables (`user_roles`, `product_allergens`); `MenuItem` became the associative table between category and product; the subtype hierarchy became one table with a discriminator; composition of `Menu`–`MenuRevision` became an identifying relationship with a composite key; the comment's optional link to an item became an ARC; attributes needed only by the database were added (`created_at`, `vat_rate`, `retention_period`, `event_duration`). |

All data types required by the TDS assignment are used:

| Type | Columns |
|---|---|
| `VARCHAR2` | names, e-mails, notes |
| `CHAR` | `roles.role_code`, `users.active`, `share_links.token` |
| `NUMBER` | keys, prices, quantities |
| `DATE` | `projects.event_date` |
| `TIMESTAMP` | `projects.created_at`, `project_nodes.created_at`, `product_price_history.changed_at` |
| `TIMESTAMP WITH TIME ZONE` | `menu_revisions.created_at`, `share_links.created_at`, `share_links.valid_until` |
| `TIMESTAMP WITH LOCAL TIME ZONE` | `comments.created_at` |
| `INTERVAL DAY TO SECOND` | `projects.event_duration` |
| `INTERVAL YEAR TO MONTH` | `projects.retention_period` |
| `CLOB` | `projects.note` |
| `BLOB` | `products.photo` |

## Relationships

- Each **user** may have one or more **roles**. Each **role** may be assigned to one or more **users**.
- Each **user** may supervise one or more **users**. Each **user** may report to one and only one **user**.
- Each **customer** may order one or more **projects**. Each **project** must be ordered by one and only one **customer** (non-transferable).
- Each **user** may be responsible for one or more **projects**. Each **project** must have one and only one responsible **user** (transferable).
- Each **project** must contain one or more **project nodes**. Each **project node** must belong to one and only one **project**.
- Each **folder** may contain one or more **project nodes**. Each **project node** may be placed in one and only one **folder**.
- Each **project** may have one or more **menus**. Each **menu** must belong to one and only one **project** (non-transferable).
- Each **menu node** (project node of type MENU) may be the placement of one and only one **menu**. Each **menu** must be placed in one and only one **menu node** (1:1, `fk_menus_node`, `uq_menus_node`).
- Each **menu** must have one or more **menu revisions**. Each **menu revision** must belong to one and only one **menu** (identifying).
- Each **user** may create one or more **menu revisions**. Each **menu revision** must be created by one and only one **user**.
- Each **menu revision** must contain one or more **menu categories**. Each **menu category** must belong to one and only one **menu revision**.
- Each **menu category** may contain one or more **menu items**. Each **menu item** must belong to one and only one **menu category**.
- Each **product** may be used in one or more **menu items**. Each **menu item** must be based on one and only one **product**.
- Each **product** may contain one or more **allergens**. Each **allergen** may be contained in one or more **products**.
- Each **product** may have one or more **price history records**. Each **price history record** must belong to one and only one **product**.
- Each **menu revision** may be shared through one or more **share links**. Each **share link** must point to one and only one **menu revision**.
- Each **menu revision** may have one or more **comments**. Each **comment** must be about either one **menu revision** or one **menu item** (ARC).
- Each **menu item** may have one or more **comments**.
- Each **user** may resolve one or more **comments**. Each **comment** may be resolved by one and only one **user** (`fk_comments_resolved_by`).

## Relationship matrix

| | User | Role | Customer | Project | ProjectNode | Menu | MenuRevision | MenuCategory | Product | Allergen | PriceHistory | ShareLink | Comment |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **User** | supervises | has | | is responsible for | | | creates | | | | | | resolves |
| **Role** | is assigned to | | | | | | | | | | | | |
| **Customer** | | | | orders | | | | | | | | | |
| **Project** | has responsible | | is ordered by | | contains | has | | | | | | | |
| **ProjectNode** | | | | belongs to | contains (folder) | is placement of | | | | | | | |
| **Menu** | | | | belongs to | is placed in | | has | | | | | | |
| **MenuRevision** | is created by | | | | | belongs to | | contains | | | | is shared by | has |
| **MenuCategory** | | | | | | | belongs to | | contains (item) | | | | has (via item) |
| **Product** | | | | | | | | is used in (item) | | contains | has | | has (via item) |
| **Allergen** | | | | | | | | | is in | | | | |
| **PriceHistory** | | | | | | | | | belongs to | | | | |
| **ShareLink** | | | | | | | points to | | | | | | |
| **Comment** | is resolved by | | | | | | is about (arc) | | is about (via item) | | | | |

## Business rules

1. Every project belongs to exactly one customer and has exactly one responsible worker; the
   responsible worker may change, the customer may not.
2. Every project has exactly one root folder; a document is always inside a folder; two nodes in one
   folder cannot have the same name.
3. A document is at most 20 MB; its content is stored in the file storage, the database keeps only
   its name, type, size and storage key.
4. Every saved change of a menu creates a new revision with the next number; older revisions are
   never changed.
5. A shared revision is read-only; sharing a revision deactivates the older links of the same menu,
   so a menu has at most one active link.
6. A link is valid for 14 days; an expired or deactivated link does not show the revision.
7. A comment is about the whole revision or about one item of it, never both, and starts as unresolved.
8. Quantities are greater than 0, prices are not negative, VAT is 0, 12 or 21 %.
9. Every change of a product price is recorded in the price history.
10. The system always has at least one active administrator (checked by the application,
    `03_checks.sql` verifies it).

Rules 1–3, 7–9 are enforced by the database (constraints, unique index, triggers); rules 4–6 and 10
by the application, and `03_checks.sql` verifies them on the data. The tree rules (the parent of a node is a
folder of the same project) are also enforced by the application and checked by `03_checks.sql` section 5;
the database only guarantees one root folder and a parent for every document.

## Normal forms

- **1NF:** every column holds one atomic value; there are no repeating groups. Roles and allergens
  are separate rows in `user_roles` and `product_allergens`, not lists in one column. The event
  duration is one INTERVAL value, not a text.
- **2NF:** in tables with composite keys every non-key column depends on the whole key:
  `menu_items.quantity` and `unit_price` depend on the category **and** the product;
  `menu_revisions.state` depends on the menu **and** the revision number. Product name and
  description are in `products`, not in `menu_items`.
- **3NF:** no non-key column depends on another non-key column. The customer's name is not copied
  into `projects`; the menu total is not stored but computed in `v_menu_revision_totals`.
  `menu_items.unit_price` is deliberately stored (not taken from `products.current_price`),
  because it is the price agreed in that revision and must not change when the catalogue price
  changes; it depends on the item, not on the product.
- **Controlled denormalisation:** `menus.project_id` and `menus.name` repeat facts of the MENU node
  (`project_nodes.project_id`, `project_nodes.name` via `menus.node_id`). `project_id` is kept for the
  non-transferable trigger and fast lookups, `name` so simple queries need no join. The copy is not
  enforced by a constraint, the application writes both together and `03_checks.sql` section 5 verifies
  that every menu points to a MENU node of the same project with the same name (0 violations).

## Notes for the school server

- Run the scripts in SQL Developer as your own schema: `01_schema.sql`, `02_seed.sql`, then
  `03_checks.sql` (F5 "Run Script").
- The schema needs the privileges CREATE TABLE, CREATE SEQUENCE, CREATE TRIGGER and CREATE VIEW.
- The ER and relational diagrams are created in SQL Developer Data Modeler by importing the DDL
  (File → Import → DDL File) and then arranging and annotating them (ARC, subtypes).

## Change log

- 2026-11-13: `project_nodes` gained the `MENU` subtype and `menus.node_id` (FK, unique) so a menu sits in a folder; `uq_menus_name` dropped (sibling uniqueness covers it); `comments` gained `resolution_note`, `resolved_by`, `resolved_at` with `ck_comments_resolution` (needed by the VIS app, UC13).
- 2026-11-15: `users.password_hash` is `VARCHAR2(200)` holding a salted PBKDF2 hash (`iterations:salt:hash`, computed by the app); the seed contains precomputed values for the password `heslo123`.
- 2026-11-16: `ck_users_no_self_supervisor` (CHECK on `users`), index `ix_comments_item` (FK `fk_comments_item`, now 9 indexes); `03_checks.sql` gained integrity checks "parent is not a FOLDER" and "menu does not match its MENU node" and a rejection test for a self-supervising user; `04_queries.sql` (query catalogue) added; controlled denormalisation of `menus.project_id/name` documented.
- 2026-11-16 (A-18): `users.created_at`, `projects.created_at`, `project_nodes.created_at` and `product_price_history.changed_at` (plain `TIMESTAMP`) default to `LOCALTIMESTAMP` instead of `SYSTIMESTAMP`, so the session time zone (set by the JDBC driver to the JVM zone) is used and the application shows no zone shift. The `WITH TIME ZONE` / `WITH LOCAL TIME ZONE` columns keep `SYSTIMESTAMP`.
- 2026-11-16 (A-17): seed org chart: `kpokorny` now reports to `mdvorakova`, so every manager (`mkral`, `ehorakova`, `tsvoboda`, `mdvorakova`) supervises at least one worker. The VIS manager web lists only projects whose `responsible_user_id` has `users.supervisor_id` = the logged-in manager.
