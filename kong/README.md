# Kong + Keycloak OIDC — Auto Bootstrap (Local Dev)

This starter spins up **Keycloak** with a pre-imported realm and a **Kong** gateway.
A one-shot `bootstrap` service configures a demo upstream and enables an **OIDC plugin**
(Enterprise `openid-connect`, community `oidc`, or your custom `kong-keycloak-oidc`).

## Quick start

```bash
# 1) Adjust ports/vars if needed
cp .env .env.local  # optional
# (compose reads .env by default; edit it)

# 2) Bring everything up
docker compose -f docker-compose.dev.proxy.yml up --build -d

# 3) Watch logs (first run will import realm + run bootstrap)
docker compose logs -f bootstrap kong

# 4) Test the proxy
# Open in browser (or curl -v):
 http://host.docker.internal:8000/
 
 # 5) Test the admin gui
 http://host.docker.internal:8002/admin/
 
```
## What gets created

- **Keycloak** (port `${KEYCLOAK_HTTP_PORT}`), Realm: `demo`
    - Client: `kong-client` (confidential), secret `kong-secret`
    - Redirect URIs:
        - `http://host.docker.internal:8000/oidc/callback`
        - `https://host.docker.internal:8443/oidc/callback`
    - User: `alice / alicepass`

- **Kong**
    - Service → `https://httpbin.org/anything`
    - Route → `/demo`
    - OIDC plugin → name from `.env` as `OIDC_PLUGIN_NAME`
        - `openid-connect` (Enterprise) **or**
        - `oidc` (community) **or**
        - `kong-keycloak-oidc` (your custom plugin)

## Switch plugin

Edit `.env`:

```
OIDC_PLUGIN_NAME=openid-connect   # Enterprise
# OIDC_PLUGIN_NAME=oidc           # Community
# OIDC_PLUGIN_NAME=kong-keycloak-oidc  # Your custom
```

Then:

```bash
docker compose up -d --force-recreate bootstrap
```

(Or delete the plugin via Admin API and re-run bootstrap.)

## Notes

- This is intended for local development. `sslRequired` is `NONE` in Keycloak.
- If you terminate TLS on Kong (`8443/8444`), update the redirect URIs in the realm and `.env`.
- If your Keycloak uses the legacy base path (`/auth/realms/...`), change the healthcheck and `DISCOVERY` URL accordingly.
- If the community `oidc` plugin is not installed in your image, the plugin creation will be a no-op. Set `OIDC_PLUGIN_NAME` appropriately.

## Teardown

```bash
docker compose down -v
```


## Troubleshooting “missing code”

If you see an error like **missing code** from your OIDC plugin, check:

1) **Callback route exists**: this starter now creates a dedicated `/oidc/callback` route and attaches the plugin there too.
2) **Redirect URI EXACT match** between Keycloak client and plugin config:
    - Used here: `http://host.docker.internal:${KONG_PROXY_HTTP}/oidc/callback`
    - Make sure you visit the gateway using the **same host** (`host.docker.internal`, not `localhost`).
3) **Discovery URL** matches your Keycloak version:
    - Modern: `/realms/<realm>/.well-known/openid-configuration`
    - Legacy: `/auth/realms/<realm>/.well-known/openid-configuration` (adjust compose + bootstrap if needed)
4) **Cookies**: If you test under HTTPS with self-signed certs, set proper cookie flags or allow self-signed; under HTTP keep `SameSite=Lax`.
5) **Multiple plugins**: Ensure no other auth plugin intercepts `/oidc/callback` first.
6)  If none of the above helps, login in to Keycloak directly to delete and re-create the client(kong-client).


Via Nginx  (with Admin API access):http://host.docker.internal:3001/admin
Via Nginx  (with Proxy access):http://host.docker.internal:3001/
Proxy : http://host.docker.internal:8000
Admin GUI:http://host.docker.internal:8002/admin
Admin API:http://host.docker.internal:8001
Admin API Metrics :http://host.docker.internal:8001/metrics

Prometheus :http://host.docker.internal:9090/targets?search=
