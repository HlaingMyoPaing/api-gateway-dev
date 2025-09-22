# Keycloak Dev (Postgres) with One Client and Documented Dockerfile
This is a **development-only** setup for running Keycloak with Postgres inside Docker Compose.

## Realm & Client
- Realm: `demo`
- Client: `demo-client`
  - Redirect URI: `http://localhost:3001/*`
  - Web Origins: `http://localhost:3001`
  - Public client, Authorization Code + PKCE enabled

## Run
```bash
docker compose up --build
```
Or
```bash
.\keycloak-startup.sh
```

Admin Console:http://host.docker.internal/:8080/auth  
Login: admin / admin

Use this in your frontend app:
- Issuer: http://host.docker.internal/auth/realms/demo
- Client ID: demo-client
- Redirect URI: http://localhost:3001/*

## Notes
- Dockerfile is heavily commented to explain each step (dev-only decisions, why no curl/wget, why sslRequired=NONE).
- **Dev only**: This setup runs Keycloak over plain HTTP (`KC_HTTP_ENABLED=true`) and disables SSL enforcement. Do not expose this setup to the public internet.
- The Postgres data is stored in a named volume (`keycloak_db_data`) so data persists between restarts. To reset everything:

  ```bash
  docker compose down -v
  ```

- You can add more realm exports to the `realms/` folder and extend `init/bootstrap.sh` to import them automatically.

## Next Steps

- For production: put Keycloak behind a reverse proxy (Kong, Nginx, Traefik) that terminates TLS.
- Switch `sslRequired` back to `external` or `all`.
- Use stronger, non-default admin/DB credentials.

---
