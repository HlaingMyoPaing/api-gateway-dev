 #!/usr/bin/env sh
 set -eu

 # ===== envs expected (can be from .env via docker-compose) =====
 : "${KONG_HOSTNAME:=kong}" # where kong admin & keycloak are reachable from container
 : "${KONG_ADMIN_HTTP:=8001}"
 : "${KONG_PROXY_HTTP:=8000}"
 : "${KC_HOSTNAME:=keycloak}"
 : "${KEYCLOAK_HTTP_PORT:=8081}"
 : "${KEYCLOAK_AUTH_PREFIX:=/auth}" # set to "" if your Keycloak has no /auth
 : "${REALM:=demo}"
 : "${KC_CLIENT_ID:=kong-client}"
 : "${KC_CLIENT_SECRET:=kong-secret}"
 : "${UPSTREAM_URL:=http://kong:8002/admin}"
 : "${ROUTE_PATH:=/admin}"
 : "${OIDC_PLUGIN_NAME:=keycloak-oidc}"
 : "${OIDC_SERVICE_NAME:=demo-svc}"
 : "${SESSION_NAME:=kc_sess}"
 : "${SESSION_SECRET:=}" # if empty we’ll generate one
 : "${SESSION_LIFETIME_S:=86400}" # 24h
 : "${SESSION_IDLE_TIMEOUT:=900}" # 15m
 : "${SESSION_ROLLING:=true}"
 : "${SESSION_COOKIE_SECURE:=false}" # true if your proxy is https
 : "${SESSION_COOKIE_SAMESITE:=Lax}"

 KONG_ADMIN="http://${KONG_SERVICE_NAME}:${KONG_ADMIN_HTTP}"
 KEYCLOAK_BASE="http://${KC_HOSTNAME}:${KEYCLOAK_HTTP_PORT}${KEYCLOAK_AUTH_PREFIX}"
 DISCOVERY="${KEYCLOAK_BASE}/realms/${REALM}/.well-known/openid-configuration"
 REDIRECT_URI="http://${KONG_HOSTNAME}:${KONG_PROXY_HTTP}/oidc/callback" # <-- scheme added

 # ===== helper: retry until HTTP 200 =====
 wait_for() {
 url="$1"; name="$2"; tries="${3:-60}"; delay="${4:-2}"
 echo "==> Waiting for ${name} at ${url}"
 i=0
 while [ $i -lt "$tries" ]; do
 if /usr/bin/curl -sf "${url}" >/dev/null 2>&1; then
 echo " ${name} is up."
 return 0
 fi
 i=$((i+1))
 sleep "$delay"
 done
 echo "ERROR: ${name} not reachable: ${url}" >&2
 exit 1
 }

 # ===== generate session secret if not provided =====
 if [ -z "${SESSION_SECRET}" ]; then
 if command -v openssl >/dev/null 2>&1; then
 SESSION_SECRET="$(openssl rand -hex 32)"
 else
 # fallback (less ideal than openssl, but fine for dev)
 SESSION_SECRET="$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n')"
 fi
 fi

 wait_for "${KONG_ADMIN}" "Kong Admin API"
 wait_for "${DISCOVERY}" "Keycloak Discovery"

 echo "==> Creating service & routes"
 # service
 /usr/bin/curl -s -k -X POST "${KONG_ADMIN}/services" \
 --data "name=${OIDC_SERVICE_NAME}" \
 --data "url=${UPSTREAM_URL}" >/dev/null || true

 # main route (your admin gui)
 /usr/bin/curl -s -k -X POST "${KONG_ADMIN}/services/${OIDC_SERVICE_NAME}/routes" \
 --data "paths[]=${ROUTE_PATH}" \
 --data "paths[]=/oidc/callback" \
 --data "paths[]=~/.*\.(js|css|png|jpg|jpeg|gif|svg|woff2?|ttf|eot)$" \
 --data "strip_path=false" >/dev/null || true

 echo "==> Enabling OIDC plugin (${OIDC_PLUGIN_NAME}) on ${OIDC_SERVICE_NAME}"
 # NOTE: These fields match the schema/handler we prepared earlier:
 # - introspection_endpoint (not introspection_url)
 # - session_* names from your schema

  /usr/bin/curl -s -k -X POST http://kong:8001/services/"${OIDC_SERVICE_NAME}"/plugins \
 --data "name=${OIDC_PLUGIN_NAME}" \
 --data "config.client_id=${KC_CLIENT_ID}" \
 --data "config.client_secret=${KC_CLIENT_SECRET}" \
 --data "config.discovery=${DISCOVERY}" \
 --data "config.redirect_uri=${REDIRECT_URI}" \
 --data "config.session_secret=aaaa" >/dev/null || true

   # CORS route (for admin gui XHR requests)
   echo "==> Creating CORS plugins"
# Replace ROUTE_ID_OR_NAME below (e.g. kong-admin-api-route)
  /usr/bin/curl -s -k -X POST http://kong:8001/routes/"${ROUTE_PATH}"/plugins \
--data name=cors \
--data "config.origins=*" \
--data "config.methods=GET,POST,PUT,PATCH,DELETE,OPTIONS" \
--data "config.headers=Accept,Authorization,Content-Type,Kong-Admin-Token" \
--data "config.exposed_headers=*" \
--data "config.credentials=true" \
--data "config.max_age=3600" \
--data "config.preflight_continue=false" >/dev/null || true

 echo "==> Enabled OIDC plugin (${OIDC_PLUGIN_NAME}) on ${OIDC_SERVICE_NAME}"

 echo "==> Done. Visit via Kong proxy: ${ROUTE_PATH} (Callback: ${REDIRECT_URI})"
