# Local Oracle database (development only)

Oracle Database 23ai Free (23.7) runs in Docker. It is for local development only; the TDS
submission must run on the school server (dbsys.cs.vsb.cz).

| Setting | Value |
|---|---|
| Docker image | `gvenzl/oracle-free:23.7-slim` |
| Container | `vis-oracle` (restart policy `unless-stopped`) |
| Data volume | `vis-oracle-data` (mounted at `/opt/oracle/oradata`) |
| Host / port | `localhost` / `1521` |
| Service name | `FREEPDB1` |
| App user / password | `CATERING` / `<CATERING password>` |
| SYS / SYSTEM password | `<SYS password>` |
| JDBC URL | `jdbc:oracle:thin:@//localhost:1521/FREEPDB1` |

These passwords are local-only test values. Do not reuse them anywhere else.

## Everyday commands

Docker Desktop must be running (`systemctl --user start docker-desktop`); the Docker CLI context
is `desktop-linux`.

```bash
docker start vis-oracle                 # start (after a reboot, if not running)
docker stop vis-oracle                  # stop
docker logs -f vis-oracle               # wait for "DATABASE IS READY TO USE!"
docker exec -it vis-oracle sqlplus CATERING/<CATERING password>@//localhost:1521/FREEPDB1
```

SQL Developer / Data Modeler: new connection, user `CATERING`, host `localhost`, port `1521`,
service name `FREEPDB1`.

Reset everything (deletes all data): `docker rm -f vis-oracle && docker volume rm vis-oracle-data`,
then run the `docker run` command below again.

```bash
docker run -d --name vis-oracle -p 1521:1521 -v vis-oracle-data:/opt/oracle/oradata \
  -e ORACLE_PASSWORD=<SYS password> -e APP_USER=CATERING -e APP_USER_PASSWORD=<CATERING password> \
  --restart unless-stopped gvenzl/oracle-free:23.7-slim
```

The real local passwords are kept in `db/local-oracle.secrets.md` (untracked, see `.gitignore`).
