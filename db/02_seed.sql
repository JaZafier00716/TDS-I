-- =====================================================================
-- Catering IS - test data. Run after 01_schema.sql (it expects empty tables).
-- All user passwords are the test value 'heslo123' (salted PBKDF2 hash).
-- =====================================================================

SET DEFINE OFF

-- ---------------------------------------------------------------------
-- Roles, users
-- ---------------------------------------------------------------------
INSERT INTO roles (role_code, name) VALUES ('ADMIN', 'Administrator');
INSERT INTO roles (role_code, name) VALUES ('WORKER', 'Worker');
INSERT INTO roles (role_code, name) VALUES ('MANAGER', 'Manager');

-- user_id 1..10 (sequence starts at 1); supervisor_id builds the org chart
-- password of every seed user: heslo123 (PBKDF2WithHmacSHA256, 65536 iterations, salt per user)
INSERT INTO users (username, full_name, email, password_hash, supervisor_id)
  VALUES ('mkral', 'Martin Král', 'mkral@catering.cz', '65536:01010101010101010101010101010101:61bd7bc4ab621444f6170db41cb8b27b662c27022e8d463079d8ed85b5ec1d94', NULL);
INSERT INTO users (username, full_name, email, password_hash, supervisor_id)
  VALUES ('ehorakova', 'Eva Horáková', 'ehorakova@catering.cz', '65536:02020202020202020202020202020202:3f8f133ebe453cd8e1b3862c897beff386b6aa66264170952b02303d3a6c8e19', 1);
INSERT INTO users (username, full_name, email, password_hash, supervisor_id)
  VALUES ('tsvoboda', 'Tomáš Svoboda', 'tsvoboda@catering.cz', '65536:03030303030303030303030303030303:4a58f3f0117a03db66471624872c442cf4434bc004adcced087a58457ab3c119', 1);
INSERT INTO users (username, full_name, email, password_hash, supervisor_id)
  VALUES ('jzamostny', 'Jan Zámostný', 'jzamostny@catering.cz', '65536:04040404040404040404040404040404:54315d5f8224532759e38b47cfe4427f6fea4cd98fedbebcaa931d21929d8550', 1);
INSERT INTO users (username, full_name, email, password_hash, supervisor_id)
  VALUES ('pnovak', 'Petr Novák', 'pnovak@catering.cz', '65536:05050505050505050505050505050505:24ebb87d1395a73f3f770e716bffe7d3d7e5295ee0408cf474e231e11a9dfea4', 2);
INSERT INTO users (username, full_name, email, password_hash, supervisor_id)
  VALUES ('lcerna', 'Lucie Černá', 'lcerna@catering.cz', '65536:06060606060606060606060606060606:5a0a954ec1e8b28a64798e4b9e5e2c0d0441be4a22c3369e64f6a31ef53ec82d', 2);
INSERT INTO users (username, full_name, email, password_hash, supervisor_id)
  VALUES ('kpokorny', 'Karel Pokorný', 'kpokorny@catering.cz', '65536:07070707070707070707070707070707:006b5a4204ef7dccf90fd77f6b2e70424971306446adf6bab0ec1bed974b3d05', 3);
INSERT INTO users (username, full_name, email, password_hash, supervisor_id)
  VALUES ('avesela', 'Anna Veselá', 'avesela@catering.cz', '65536:08080808080808080808080808080808:fad7f872d7667c8d976231e40c609b915857e94301d5bd67293eed6614355d32', 3);
INSERT INTO users (username, full_name, email, password_hash, supervisor_id)
  VALUES ('mdvorakova', 'Marie Dvořáková', 'mdvorakova@catering.cz', '65536:09090909090909090909090909090909:5eae33ab2c151c4e8d3104408440f3e67b71375562b4de3199347ff042e361cd', 1);
INSERT INTO users (username, full_name, email, password_hash, supervisor_id, active)
  VALUES ('jbenes', 'Jiří Beneš', 'jbenes@catering.cz', '65536:0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a:608cf73ad3d88a13e23263b609e821db279ca6004800337fc5b2f470f6b5f5c9', 3, 'N');

-- org chart for the manager web (A-17): every manager supervises at least one worker with projects
-- (mkral: jzamostny, ehorakova: pnovak + lcerna, tsvoboda: avesela + jbenes, mdvorakova: kpokorny)
UPDATE users SET supervisor_id = 9 WHERE username = 'kpokorny';

INSERT INTO user_roles (user_id, role_code) VALUES (1, 'ADMIN');
INSERT INTO user_roles (user_id, role_code) VALUES (1, 'MANAGER');
INSERT INTO user_roles (user_id, role_code) VALUES (4, 'ADMIN');
INSERT INTO user_roles (user_id, role_code) VALUES (4, 'WORKER');
INSERT INTO user_roles (user_id, role_code) VALUES (7, 'ADMIN');
INSERT INTO user_roles (user_id, role_code) VALUES (7, 'WORKER');
INSERT INTO user_roles (user_id, role_code) VALUES (2, 'MANAGER');
INSERT INTO user_roles (user_id, role_code) VALUES (3, 'MANAGER');
INSERT INTO user_roles (user_id, role_code) VALUES (5, 'WORKER');
INSERT INTO user_roles (user_id, role_code) VALUES (6, 'WORKER');
INSERT INTO user_roles (user_id, role_code) VALUES (8, 'WORKER');
INSERT INTO user_roles (user_id, role_code) VALUES (9, 'MANAGER');
INSERT INTO user_roles (user_id, role_code) VALUES (10, 'WORKER');

-- ---------------------------------------------------------------------
-- Customers (customer_id 1..20)
-- ---------------------------------------------------------------------
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Jana Nováková', NULL, 'jana.novakova@email.cz', '+420 603 111 222', 'Ostrava');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Pavel Dostál', 'ABC Logistics s.r.o.', 'dostal@abclogistics.cz', '+420 596 123 456', 'Ostrava');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Lenka Marková', 'Statutární město Opava', 'markova@opava-city.cz', '+420 553 756 111', 'Opava');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Ondřej Kučera', NULL, 'ondrej.kucera@seznam.cz', '+420 777 345 678', 'Frýdek-Místek');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Hana Procházková', 'VŠB - TU Ostrava', 'hana.prochazkova@vsb.cz', '+420 597 321 000', 'Ostrava');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Radek Malý', 'Malý & syn, a.s.', 'maly@malyasyn.cz', '+420 558 444 333', 'Třinec');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Petra Šimková', NULL, 'petra.simkova@gmail.com', '+420 732 909 808', 'Havířov');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Michal Urban', 'Urban Events s.r.o.', 'urban@urbanevents.cz', '+420 605 222 777', 'Ostrava');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Kateřina Holá', NULL, 'katerina.hola@email.cz', '+420 720 111 000', 'Karviná');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Zdeněk Říha', 'Hotel Imperial Ostrava', 'riha@imperial.cz', '+420 599 099 099', 'Ostrava');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Veronika Kopecká', NULL, 'v.kopecka@centrum.cz', '+420 739 456 123', 'Nový Jičín');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Jakub Fiala', 'Fiala Consulting', 'fiala@fialaconsulting.cz', NULL, 'Ostrava');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Tereza Sedláčková', NULL, 'tereza.sedlackova@email.cz', '+420 604 333 444', 'Bohumín');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Lukáš Zeman', 'Moravskoslezský kraj', 'zeman@msk.cz', '+420 595 622 222', 'Ostrava');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Barbora Kolářová', NULL, 'barbora.kolarova@gmail.com', '+420 776 555 666', 'Kopřivnice');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('David Navrátil', 'Navrátil Stavby s.r.o.', 'navratil@navratilstavby.cz', '+420 556 777 888', 'Příbor');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Simona Bartošová', NULL, 'simona.bartosova@email.cz', NULL, 'Orlová');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Filip Vlček', 'Sportovní klub Poruba', 'vlcek@skporuba.cz', '+420 608 121 212', 'Ostrava');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Alena Matějková', NULL, 'alena.matejkova@seznam.cz', '+420 731 343 434', 'Studénka');
INSERT INTO customers (name, company_name, email, phone, city) VALUES ('Roman Pospíšil', 'Pospíšil Auto a.s.', 'pospisil@pospisilauto.cz', '+420 597 565 656', 'Ostrava');

-- ---------------------------------------------------------------------
-- Projects (project_id 1..10)
-- ---------------------------------------------------------------------
INSERT INTO projects (customer_id, responsible_user_id, name, event_date, event_duration, event_place, guest_count, status, note)
  VALUES (1, 4, 'Svatba Novákovi', DATE '2027-06-14', INTERVAL '0 10:00:00' DAY TO SECOND, 'Zámek Hradec nad Moravicí', 120, 'CONFIRMED',
          'Svatební hostina, rautová večeře o půlnoci. Nevěsta je vegetariánka.');
INSERT INTO projects (customer_id, responsible_user_id, name, event_date, event_duration, event_place, guest_count, status, note)
  VALUES (2, 5, 'Firemní večírek ABC Logistics', DATE '2026-12-11', INTERVAL '0 05:00:00' DAY TO SECOND, 'Clarion Congress Hotel Ostrava', 200, 'IN_PROGRESS', NULL);
INSERT INTO projects (customer_id, responsible_user_id, name, event_date, event_duration, event_place, guest_count, status, note)
  VALUES (3, 6, 'Novoroční raut radnice', DATE '2027-01-08', INTERVAL '0 04:00:00' DAY TO SECOND, 'Slezské divadlo Opava', 150, 'IN_PROGRESS', 'Požadavek na regionální suroviny.');
INSERT INTO projects (customer_id, responsible_user_id, name, event_date, event_duration, event_place, guest_count, status, note)
  VALUES (5, 4, 'Konference VŠB 2026', DATE '2026-11-20', INTERVAL '2 00:00:00' DAY TO SECOND, 'Aula VŠB-TUO, Ostrava-Poruba', 300, 'CONFIRMED', 'Dva dny, coffee break dopoledne a odpoledne, obědy.');
INSERT INTO projects (customer_id, responsible_user_id, name, event_date, event_duration, event_place, guest_count, status, note)
  VALUES (6, 7, 'Výročí firmy Malý & syn', DATE '2026-09-25', INTERVAL '0 06:00:00' DAY TO SECOND, 'Hotel Steel, Třinec', 80, 'DONE', NULL);
INSERT INTO projects (customer_id, responsible_user_id, name, event_date, event_duration, event_place, guest_count, status, note)
  VALUES (7, 8, 'Narozeninová oslava 50', DATE '2026-12-05', INTERVAL '0 08:00:00' DAY TO SECOND, 'Restaurace Na Stezce, Havířov', 45, 'IN_PROGRESS', NULL);
INSERT INTO projects (customer_id, responsible_user_id, name, event_date, event_duration, event_place, guest_count, status, note)
  VALUES (10, 5, 'Gala večer Hotel Imperial', DATE '2027-02-14', INTERVAL '0 06:00:00' DAY TO SECOND, 'Hotel Imperial Ostrava', 180, 'IN_PROGRESS', 'Valentýnský galavečer, menu o 5 chodech.');
INSERT INTO projects (customer_id, responsible_user_id, name, event_date, event_duration, event_place, guest_count, status, note)
  VALUES (14, 6, 'Setkání starostů kraje', DATE '2026-10-02', INTERVAL '0 05:00:00' DAY TO SECOND, 'Krajský úřad MSK, Ostrava', 90, 'ARCHIVED', NULL);
INSERT INTO projects (customer_id, responsible_user_id, name, event_date, event_duration, event_place, guest_count, status, note)
  VALUES (18, 8, 'Ples SK Poruba', DATE '2027-01-30', INTERVAL '0 07:00:00' DAY TO SECOND, 'Dům kultury Poklad, Ostrava-Poruba', 250, 'IN_PROGRESS', NULL);
INSERT INTO projects (customer_id, responsible_user_id, name, event_date, event_duration, event_place, guest_count, status, note)
  VALUES (13, 4, 'Svatba Sedláčková', DATE '2027-08-21', INTERVAL '0 12:00:00' DAY TO SECOND, 'Statek Bohumín', 70, 'IN_PROGRESS', 'Venkovní svatba, záložní varianta pod stanem.');

-- Folder tree and documents: root, Smlouvy, Podklady (with a nested Fotky folder)
DECLARE
  v_root     NUMBER;
  v_contract NUMBER;
  v_docs     NUMBER;
  v_photos   NUMBER;
BEGIN
  FOR p IN (SELECT project_id, name FROM projects ORDER BY project_id) LOOP
    INSERT INTO project_nodes (project_id, parent_id, node_type, name)
      VALUES (p.project_id, NULL, 'FOLDER', p.name) RETURNING node_id INTO v_root;
    INSERT INTO project_nodes (project_id, parent_id, node_type, name)
      VALUES (p.project_id, v_root, 'FOLDER', 'Smlouvy') RETURNING node_id INTO v_contract;
    INSERT INTO project_nodes (project_id, parent_id, node_type, name)
      VALUES (p.project_id, v_root, 'FOLDER', 'Podklady') RETURNING node_id INTO v_docs;
    INSERT INTO project_nodes (project_id, parent_id, node_type, name, content_type, size_bytes, storage_key)
      VALUES (p.project_id, v_contract, 'DOCUMENT', 'smlouva.pdf', 'application/pdf',
              180000 + p.project_id * 1234, 'p' || p.project_id || '/smlouva.pdf');
    INSERT INTO project_nodes (project_id, parent_id, node_type, name, content_type, size_bytes, storage_key)
      VALUES (p.project_id, v_docs, 'DOCUMENT', 'pudorys-salu.pdf', 'application/pdf',
              950000 + p.project_id * 5000, 'p' || p.project_id || '/pudorys-salu.pdf');
    IF MOD(p.project_id, 2) = 1 THEN
      INSERT INTO project_nodes (project_id, parent_id, node_type, name)
        VALUES (p.project_id, v_docs, 'FOLDER', 'Fotky') RETURNING node_id INTO v_photos;
      INSERT INTO project_nodes (project_id, parent_id, node_type, name, content_type, size_bytes, storage_key)
        VALUES (p.project_id, v_photos, 'DOCUMENT', 'prostory-1.jpg', 'image/jpeg', 2400000, 'p' || p.project_id || '/prostory-1.jpg');
      INSERT INTO project_nodes (project_id, parent_id, node_type, name, content_type, size_bytes, storage_key)
        VALUES (p.project_id, v_photos, 'DOCUMENT', 'prostory-2.jpg', 'image/jpeg', 2150000, 'p' || p.project_id || '/prostory-2.jpg');
    END IF;
  END LOOP;
END;
/

-- ---------------------------------------------------------------------
-- Product catalogue (product_id 1..24) and allergens
-- ---------------------------------------------------------------------
INSERT INTO allergens (allergen_id, name) VALUES (1, 'Obiloviny obsahující lepek');
INSERT INTO allergens (allergen_id, name) VALUES (2, 'Korýši');
INSERT INTO allergens (allergen_id, name) VALUES (3, 'Vejce');
INSERT INTO allergens (allergen_id, name) VALUES (4, 'Ryby');
INSERT INTO allergens (allergen_id, name) VALUES (5, 'Arašídy');
INSERT INTO allergens (allergen_id, name) VALUES (6, 'Sójové boby');
INSERT INTO allergens (allergen_id, name) VALUES (7, 'Mléko');
INSERT INTO allergens (allergen_id, name) VALUES (8, 'Skořápkové plody');
INSERT INTO allergens (allergen_id, name) VALUES (9, 'Celer');
INSERT INTO allergens (allergen_id, name) VALUES (10, 'Hořčice');
INSERT INTO allergens (allergen_id, name) VALUES (11, 'Sezamová semena');
INSERT INTO allergens (allergen_id, name) VALUES (12, 'Oxid siřičitý a siřičitany');
INSERT INTO allergens (allergen_id, name) VALUES (13, 'Vlčí bob');
INSERT INTO allergens (allergen_id, name) VALUES (14, 'Měkkýši');

-- starters 1-6, main courses 7-12, desserts 13-18, drinks 19-24
INSERT INTO products (name, description, unit, current_price) VALUES ('Tatarák z hovězího', 'Hovězí tatarák s topinkou a česnekem', 'portion', 95);
INSERT INTO products (name, description, unit, current_price) VALUES ('Caprese', 'Rajčata, mozzarella, bazalka, olivový olej', 'portion', 70);
INSERT INTO products (name, description, unit, current_price) VALUES ('Paštika z kachních jater', 'S brusinkami a brioškou', 'portion', 85);
INSERT INTO products (name, description, unit, current_price) VALUES ('Chlebíčky s vlašským salátem', 'Tradiční obložené chlebíčky', 'pcs', 35);
INSERT INTO products (name, description, unit, current_price) VALUES ('Uzený losos na rösti', 'Losos, křenová pěna, bramborové rösti', 'portion', 110);
INSERT INTO products (name, description, unit, current_price) VALUES ('Grilovaná zelenina s kozím sýrem', 'Vegetariánský předkrm', 'portion', 80);
INSERT INTO products (name, description, unit, current_price) VALUES ('Svíčková na smetaně', 'Hovězí svíčková, houskový knedlík, brusinky', 'portion', 210);
INSERT INTO products (name, description, unit, current_price) VALUES ('Kuřecí supreme', 'Kuřecí prso, bramborové pyré, demi-glace', 'portion', 195);
INSERT INTO products (name, description, unit, current_price) VALUES ('Rizoto s hříbky', 'Vegetariánské rizoto s parmazánem', 'portion', 180);
INSERT INTO products (name, description, unit, current_price) VALUES ('Pečená vepřová panenka', 'Panenka, gratinované brambory, zelené fazolky', 'portion', 220);
INSERT INTO products (name, description, unit, current_price) VALUES ('Filet z candáta', 'Candát na másle, bylinkové brambory', 'portion', 245);
INSERT INTO products (name, description, unit, current_price) VALUES ('Selečí pečínka s knedlíkem', 'Selečí bůček, zelí, karlovarský knedlík', 'portion', 205);
INSERT INTO products (name, description, unit, current_price) VALUES ('Svatební dort', 'Třípatrový dort dle výběru', 'pcs', 6500);
INSERT INTO products (name, description, unit, current_price) VALUES ('Svatební koláčky', 'Tvarohové, makové a povidlové', 'pcs', 12);
INSERT INTO products (name, description, unit, current_price) VALUES ('Panna cotta s lesním ovocem', NULL, 'portion', 65);
INSERT INTO products (name, description, unit, current_price) VALUES ('Čokoládový fondán', 'S vanilkovou zmrzlinou', 'portion', 75);
INSERT INTO products (name, description, unit, current_price) VALUES ('Ovocný talíř', 'Sezónní ovoce', 'portion', 55);
INSERT INTO products (name, description, unit, current_price) VALUES ('Mini zákusky', 'Výběr minizákusků', 'pcs', 25);
INSERT INTO products (name, description, unit, current_price, vat_rate) VALUES ('Prosecco', 'Na přípitek', 'l', 280, 21);
INSERT INTO products (name, description, unit, current_price, vat_rate) VALUES ('Bílé víno Ryzlink rýnský', 'Moravské zemské víno', 'l', 240, 21);
INSERT INTO products (name, description, unit, current_price, vat_rate) VALUES ('Červené víno Frankovka', 'Moravské zemské víno', 'l', 250, 21);
INSERT INTO products (name, description, unit, current_price, vat_rate) VALUES ('Pivo Radegast 12', 'Sudové pivo', 'l', 90, 21);
INSERT INTO products (name, description, unit, current_price) VALUES ('Nealkoholické nápoje', 'Džusy, minerální voda, limonády', 'l', 60);
INSERT INTO products (name, description, unit, current_price) VALUES ('Káva a čaj', 'Káva z kávovaru, výběr čajů', 'set', 45);

-- small photos (1x1 px PNG as a placeholder for the BLOB column)
UPDATE products
SET photo = HEXTORAW('89504E470D0A1A0A0000000D49484452000000010000000108060000001F15C4890000000D4944415478DA63F8CFC0F01F0005000201E0C2FEB50000000049454E44AE426082')
WHERE product_id IN (1, 7, 13);

INSERT INTO product_allergens (product_id, allergen_id) VALUES (1, 1);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (1, 3);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (1, 10);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (2, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (3, 1);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (3, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (4, 1);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (4, 3);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (4, 10);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (5, 4);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (5, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (6, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (7, 1);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (7, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (7, 9);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (8, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (9, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (9, 9);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (10, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (11, 4);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (11, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (12, 1);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (13, 1);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (13, 3);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (13, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (14, 1);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (14, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (15, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (16, 1);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (16, 3);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (16, 7);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (18, 1);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (18, 8);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (19, 12);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (20, 12);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (21, 12);
INSERT INTO product_allergens (product_id, allergen_id) VALUES (22, 1);

-- ---------------------------------------------------------------------
-- Menus (menu_id 1..12) and their revisions
-- ---------------------------------------------------------------------
-- Each menu is a MENU node in the root folder of its project (STI) plus a row in menus.
DECLARE
  PROCEDURE add_menu(p_project NUMBER, p_name VARCHAR2) IS
    v_root NUMBER;
    v_node NUMBER;
  BEGIN
    SELECT node_id INTO v_root FROM project_nodes WHERE project_id = p_project AND parent_id IS NULL;
    INSERT INTO project_nodes (project_id, parent_id, node_type, name)
      VALUES (p_project, v_root, 'MENU', p_name) RETURNING node_id INTO v_node;
    INSERT INTO menus (project_id, node_id, name) VALUES (p_project, v_node, p_name);
  END;
BEGIN
  add_menu(1, 'Svatební menu');
  add_menu(1, 'Půlnoční raut');
  add_menu(2, 'Večerní raut');
  add_menu(3, 'Novoroční raut');
  add_menu(4, 'Coffee break');
  add_menu(4, 'Obědové menu');
  add_menu(5, 'Slavnostní večeře');
  add_menu(6, 'Oslava 50');
  add_menu(7, 'Galavečeře o 5 chodech');
  add_menu(8, 'Pracovní oběd');
  add_menu(9, 'Plesové menu');
  add_menu(10, 'Svatební menu');
END;
/

-- Revision 1 has four categories with 2-3 products each. Every next revision copies the
-- previous one, raises one quantity, removes one item and adds another product.
-- Menus with 3+ revisions have the last-but-one revision shared with the customer,
-- menus with 4 revisions also share the newest one.
DECLARE
  TYPE t_names IS VARRAY(4) OF VARCHAR2(30);
  c_names CONSTANT t_names := t_names('Předkrmy', 'Hlavní chod', 'Dezerty', 'Nápoje');
  v_revs     PLS_INTEGER;
  v_guests   NUMBER;
  v_cat      NUMBER;
  v_new_cat  NUMBER;
  v_prod     NUMBER;
  v_author   NUMBER;
BEGIN
  FOR m IN (SELECT m.menu_id, p.guest_count, p.responsible_user_id
            FROM menus m JOIN projects p ON p.project_id = m.project_id ORDER BY m.menu_id) LOOP
    v_revs   := 2 + MOD(m.menu_id, 3);
    v_guests := m.guest_count;
    v_author := m.responsible_user_id;

    -- revision 1
    INSERT INTO menu_revisions (menu_id, revision_no, note, created_by, created_at)
      VALUES (m.menu_id, 1, 'První návrh', v_author, SYSTIMESTAMP - NUMTODSINTERVAL(40, 'DAY'));
    FOR c IN 1 .. 4 LOOP
      INSERT INTO menu_categories (menu_id, revision_no, name, position)
        VALUES (m.menu_id, 1, c_names(c), c) RETURNING category_id INTO v_cat;
      FOR k IN 0 .. 1 + MOD(m.menu_id + c, 2) LOOP
        v_prod := (c - 1) * 6 + 1 + MOD(m.menu_id + k * 2, 6);
        INSERT INTO menu_items (category_id, product_id, quantity, unit_price)
          SELECT v_cat, product_id,
                 CASE WHEN unit IN ('l') THEN ROUND(v_guests * 0.4)
                      WHEN product_id = 13 THEN 1
                      ELSE v_guests END,
                 current_price
          FROM products WHERE product_id = v_prod;
      END LOOP;
    END LOOP;

    -- revisions 2..v_revs
    FOR r IN 2 .. v_revs LOOP
      INSERT INTO menu_revisions (menu_id, revision_no, note, created_by, created_at)
        VALUES (m.menu_id, r, 'Úprava dle připomínek zákazníka (' || r || ')', v_author,
                SYSTIMESTAMP - NUMTODSINTERVAL(40 - r * 8, 'DAY'));
      FOR c IN (SELECT category_id, name, position FROM menu_categories
                WHERE menu_id = m.menu_id AND revision_no = r - 1 ORDER BY position) LOOP
        INSERT INTO menu_categories (menu_id, revision_no, name, position)
          VALUES (m.menu_id, r, c.name, c.position) RETURNING category_id INTO v_new_cat;
        INSERT INTO menu_items (category_id, product_id, quantity, unit_price, note)
          SELECT v_new_cat, product_id, quantity, unit_price, note
          FROM menu_items WHERE category_id = c.category_id;
        IF c.position = 1 THEN       -- starters: raise the quantity of the cheapest item by 10 %
          UPDATE menu_items SET quantity = ROUND(quantity * 1.1), note = 'Navýšeno'
          WHERE category_id = v_new_cat
            AND product_id = (SELECT MIN(product_id) FROM menu_items WHERE category_id = v_new_cat);
        ELSIF c.position = 2 THEN    -- main course: add the vegetarian risotto if missing
          INSERT INTO menu_items (category_id, product_id, quantity, unit_price, note)
            SELECT v_new_cat, 9, ROUND(v_guests * 0.2), 180, 'Vegetariánská varianta'
            FROM dual
            WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE category_id = v_new_cat AND product_id = 9);
        ELSIF c.position = 3 THEN    -- desserts: drop the last item if more than one remain
          DELETE FROM menu_items
          WHERE category_id = v_new_cat
            AND product_id = (SELECT MAX(product_id) FROM menu_items WHERE category_id = v_new_cat)
            AND (SELECT COUNT(*) FROM menu_items WHERE category_id = v_new_cat) > 1;
        END IF;
      END LOOP;
    END LOOP;

    IF v_revs >= 3 THEN
      UPDATE menu_revisions SET state = 'SHARED' WHERE menu_id = m.menu_id AND revision_no = v_revs - 1;
    END IF;
    IF v_revs = 4 THEN
      UPDATE menu_revisions SET state = 'SHARED' WHERE menu_id = m.menu_id AND revision_no = v_revs;
    END IF;
  END LOOP;
END;
/

-- Share links: every shared revision has a link; only the newest link of a menu is active.
-- Older links are inactive; one active link is already expired (for the alternative flow).
INSERT INTO share_links (menu_id, revision_no, token, created_at, valid_until, active)
SELECT r.menu_id, r.revision_no,
       LOWER(RAWTOHEX(STANDARD_HASH('token-' || r.menu_id || '-' || r.revision_no, 'MD5'))),
       r.created_at + INTERVAL '1' HOUR,
       r.created_at + INTERVAL '1' HOUR + INTERVAL '14' DAY,
       CASE WHEN r.revision_no = (SELECT MAX(x.revision_no) FROM menu_revisions x
                                  WHERE x.menu_id = r.menu_id AND x.state = 'SHARED') THEN 'Y' ELSE 'N' END
FROM menu_revisions r
WHERE r.state = 'SHARED';

-- Comments: on shared revisions, one about the whole revision and one about an item (ARC)
INSERT INTO comments (menu_id, revision_no, author_name, body, created_at, resolved,
                      resolution_note, resolved_by, resolved_at)
SELECT r.menu_id, r.revision_no, c.name,
       CASE MOD(r.menu_id, 3)
         WHEN 0 THEN 'Prosíme o vegetariánskou variantu hlavního chodu.'
         WHEN 1 THEN 'Můžeme posunout podávání dezertů až po 22. hodině?'
         ELSE 'Celkově se nám menu líbí, jen bychom ubrali na předkrmech.' END,
       r.created_at + INTERVAL '2' DAY,
       CASE WHEN r.revision_no < (SELECT MAX(x.revision_no) FROM menu_revisions x WHERE x.menu_id = r.menu_id)
            THEN 'Y' ELSE 'N' END,
       CASE WHEN r.revision_no < (SELECT MAX(x.revision_no) FROM menu_revisions x WHERE x.menu_id = r.menu_id)
            THEN 'Upraveno v revizi č. ' || (r.revision_no + 1) END,
       CASE WHEN r.revision_no < (SELECT MAX(x.revision_no) FROM menu_revisions x WHERE x.menu_id = r.menu_id)
            THEN p.responsible_user_id END,
       CASE WHEN r.revision_no < (SELECT MAX(x.revision_no) FROM menu_revisions x WHERE x.menu_id = r.menu_id)
            THEN CAST(r.created_at AS TIMESTAMP) + INTERVAL '4' DAY END
FROM menu_revisions r
JOIN menus m ON m.menu_id = r.menu_id
JOIN projects p ON p.project_id = m.project_id
JOIN customers c ON c.customer_id = p.customer_id
WHERE r.state = 'SHARED';

INSERT INTO comments (category_id, product_id, author_name, body, created_at, resolved)
SELECT i.category_id, i.product_id, cu.name,
       'Této položky stačí o deset méně.',
       r.created_at + INTERVAL '3' DAY, 'N'
FROM menu_revisions r
JOIN menus m ON m.menu_id = r.menu_id
JOIN projects p ON p.project_id = m.project_id
JOIN customers cu ON cu.customer_id = p.customer_id
JOIN menu_categories c ON c.menu_id = r.menu_id AND c.revision_no = r.revision_no AND c.position = 1
JOIN menu_items i ON i.category_id = c.category_id
WHERE r.state = 'SHARED'
  AND i.product_id = (SELECT MIN(product_id) FROM menu_items WHERE category_id = c.category_id);

-- ---------------------------------------------------------------------
-- Price changes over time (the trigger writes them into product_price_history)
-- ---------------------------------------------------------------------
UPDATE products SET current_price = 99  WHERE product_id = 1;
UPDATE products SET current_price = 105 WHERE product_id = 1;
UPDATE products SET current_price = 225 WHERE product_id = 7;
UPDATE products SET current_price = 75  WHERE product_id = 2;
UPDATE products SET current_price = 6900 WHERE product_id = 13;
UPDATE products SET current_price = 295 WHERE product_id = 19;
UPDATE products SET current_price = 260 WHERE product_id = 20;
UPDATE products SET current_price = 95  WHERE product_id = 22;
UPDATE products SET current_price = 50  WHERE product_id = 24;
UPDATE products SET current_price = 45  WHERE product_id = 24;

-- spread the journal over the last months instead of "now"
UPDATE product_price_history SET changed_at = SYSTIMESTAMP - NUMTODSINTERVAL(200 - history_id * 15, 'DAY');

COMMIT;
