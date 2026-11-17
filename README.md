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
| `model/REVIEW.md`, `model/GUIDE-logical.md` | review of the models and how they were fixed (working notes, not for hand-in) |

## Run locally (Docker container `vis-oracle`)

```bash
cd db
for f in 01_schema.sql 02_seed.sql 03_checks.sql 04_queries.sql; do docker cp "$f" vis-oracle:/tmp/; done
printf '@/tmp/01_schema.sql\n@/tmp/02_seed.sql\n@/tmp/03_checks.sql\n@/tmp/04_queries.sql\nexit\n' \
  | docker exec -i vis-oracle sqlplus -S CATERING/***REMOVED***@//localhost:1521/FREEPDB1
```

Or in SQL Developer: connection `localhost:1521`, service `FREEPDB1`, user `CATERING`, then open
each script and run it with F5 (Run Script).

## Run on the school server

In SQL Developer, connect to your own schema on `dbsys.cs.vsb.cz` and run `01_schema.sql`,
`02_seed.sql`, `03_checks.sql` and `04_queries.sql` with F5. The scripts use only Oracle 19c features.

## Relation to the VIS project

The VIS application (Java) uses this schema only at runtime, over JDBC. It reads the JDBC URL,
user and password from its own configuration file; no files are shared between the two folders.
# TDS-I
