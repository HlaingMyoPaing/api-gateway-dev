# Unified appnet (with Keycloak realm import)

This bundle runs Kong, oauth2-proxy, NGINX (admin proxy), and Keycloak on the same
user-defined network `appnet`. Keycloak auto-imports a `demo` realm with a client
`kong-client` (secret `kong-secret`) and a demo user `demo` / `password`.

## Run
1. `cp .env.sample .env` (adjust if needed)
2. `docker compose up -d`
3. Open:
   - Keycloak: http://host.docker.internal:8080/
   - Kong Admin GUI (via NGINX + OIDC): http://host.docker.internal:8083/admin/
   - Kong Admin API (via NGINX + OIDC): http://host.docker.internal:8083/admin-api/

## Demo Realm
- Realm: `demo`
- Client: `kong-client` (confidential), secret `kong-secret`
- Redirect URI: `http://host.docker.internal:8083/oauth2/callback`
- Web Origins: `*`
- Demo user: `demo` / `password`

## Connectivity check
```
docker compose exec admin-proxy sh -lc 'getent hosts oauth2-proxy && wget -qO- http://oauth2-proxy:4180/healthz && echo OK'
```

## Notes
- All inter-service calls use service names: `keycloak:8080`, `kong:8001/8002`, `oauth2-proxy:4180`.
- Do not use host ports for internal calls.
