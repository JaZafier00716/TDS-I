# TDS – semester project (Oracle database of the catering IS)

This folder holds the Oracle database of the catering information system: the schema, test data,
checks and the design notes for the TDS checklist. The assignment PDF is `Semestrální projekt TDS I.pdf` in this folder.

| File | Content |
|---|---|
| `db/01_schema.sql` | DDL (re-runnable: drops its own objects first) |
| `db/02_seed.sql` | test data (run on an empty schema, i.e. right after `01`) |
| `db/03_checks.sql` | row counts, sample queries, integrity checks, rejected-change tests |
| `db/04_queries.sql` | query catalogue: one example per SQL topic of the assignment; read-only except scratch objects it drops; run after 02 |
| `db/tds-design-notes.md` | TDS checklist mapping, relationships, matrix, business rules, normal forms |
| `db/README-local-oracle.md` | the local Oracle container (connection details) |
| `model/catering.dmd` + `model/catering/` | Data Modeler design: logical model (Barker, supertype/subtypes, ARC) and relational model imported from `01_schema.sql` |
| `model/Logical.pdf`, `model/relational.pdf` | exported diagrams (hand-in) |

## Database server

The scripts run on Oracle 19c or newer. Two setups are used. Placeholders like `<SYS password>` stand for your own values (the real local ones are in `db/local-oracle.secrets.md`, which is not in git).

### A) Local Oracle in Docker (development)

Container `vis-oracle`, image `gvenzl/oracle-free:23.7-slim`, port `1521`, service `FREEPDB1`, schema user `CATERING`, data volume `vis-oracle-data`. Details are in `db/README-local-oracle.md`.

First start. This creates the database and the `CATERING` user:

```bash
docker run -d --name vis-oracle -p 1521:1521 -v vis-oracle-data:/opt/oracle/oradata \
  -e ORACLE_PASSWORD=<SYS password> -e APP_USER=CATERING -e APP_USER_PASSWORD=<CATERING password> \
  --restart unless-stopped gvenzl/oracle-free:23.7-slim
docker logs -f vis-oracle            # wait for "DATABASE IS READY TO USE!"
```

Everyday use: `docker start vis-oracle`, `docker stop vis-oracle`, `docker ps --filter name=vis-oracle`. To reset, run `docker rm -f vis-oracle && docker volume rm vis-oracle-data` and then the first-start command again.

Run the scripts:

```bash
cd db
for f in 01_schema.sql 02_seed.sql 03_checks.sql 04_queries.sql; do docker cp "$f" vis-oracle:/tmp/; done
printf 'SET SERVEROUTPUT ON\n@/tmp/01_schema.sql\n@/tmp/02_seed.sql\n@/tmp/03_checks.sql\n@/tmp/04_queries.sql\nexit\n' \
  | docker exec -i vis-oracle sqlplus -S CATERING/<CATERING password>@//localhost:1521/FREEPDB1
```

Or in SQL Developer: connection `localhost:1521`, service `FREEPDB1`, user `CATERING`. Open each script and run it with F5 (Run Script).

### B) University server dbsys.cs.vsb.cz

The scripts are handed in on the school server, using your own school schema.

| Setting | Value |
|---|---|
| Host | `dbsys.cs.vsb.cz` |
| Port | `1521` `<to confirm>` |
| Service name | `<to confirm>` |
| User / password | `<login>` / `<password>` |

From outside the university network, connect to the VŠB VPN first `<to confirm>`.

SQL Developer (required by the assignment): create a new connection with these values, then "Test" and "Connect". Run `01_schema.sql`, `02_seed.sql`, `03_checks.sql` and `04_queries.sql` with F5. With sqlplus: `sqlplus <login>/<password>@//dbsys.cs.vsb.cz:1521/<service name>`, then `@01_schema.sql` and the rest in order.

The scripts use only Oracle 19c features. Two blocks in `04_queries.sql` are commented out because they need extra privileges (`CREATE ANY DIRECTORY` for the external table, `CREATE PUBLIC SYNONYM`). Enable them only if your account has these.

The VIS application connects with the JDBC URL `jdbc:oracle:thin:@//localhost:1521/FREEPDB1` (Docker) or `jdbc:oracle:thin:@//dbsys.cs.vsb.cz:1521/<service name>` (school). Only `db.url`, `db.user` and `db.password` in its `config/db.properties` change.

## Relation to the VIS project

The VIS application (Java) uses this schema only at runtime, over JDBC. It reads the JDBC URL,
user and password from its own configuration file; no files are shared between the two folders.
