# Konga + Postgres 11 + Nginx Proxy

This setup uses **pantsel/konga:next** with a working `konga-prepare` step via docker-compose.

## Usage

```bash
docker compose down -v
docker compose up --build -d
```

Then open: **http://localhost:${ADMIN_PROXY_PORT:-8083}/**

## Verify DB schema

```bash
docker exec -it konga-db psql -U konga -d konga -c "\dt"
```

You should see tables like `konga_users`, `konga_sessions`, etc.

## Notes
- Konga DB data persists in the `konga_pgdata` volume.
- Adjust `kong_admin_api` upstream in `nginx/admin.conf` if your Kong container name differs.
