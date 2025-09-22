#!/bin/sh
set -eu

# ---------- Config (env-overridable) ----------
REALM="${REALM:-demo}"
ADMIN_USER="${KEYCLOAK_ADMIN:-admin}"
ADMIN_PASS="${KEYCLOAK_ADMIN_PASSWORD:-admin}"

# Demo user
USER_NAME="${OIDC_USER_NAME:-demo}"
USER_EMAIL="${OIDC_USER_EMAIL:-deni@example.com}"
USER_PASS="${OIDC_USER_PASS:-password}"

# Grafana redirect
GRAFANA_REDIRECT="${GRAFANA_REDIRECT:-http://host.docker.internal:3000/login/generic_oauth}"

# JSON payloads (always OBJECT, never ARRAY)
KONG_CLIENT_JSON=$(cat <<'JSON'
{
"clientId": "kong-client",
"protocol": "openid-connect",
"publicClient": false,
"secret": "Y5a9BdyNApDFr4rsiOAlKdt8VJ79un8F",
"standardFlowEnabled": true,
"directAccessGrantsEnabled": false,
"serviceAccountsEnabled": false,
"attributes": { "pkce.code.challenge.method": "S256" },
"redirectUris": [
"http://host.docker.internal:3001/*",
"http://host.docker.internal:3000/*",
"http://host.docker.internal:8000/*",
"http://host.docker.internal:8083/*"
],
"webOrigins": ["+"]
}
JSON
)

GRAFANA_CLIENT_JSON=$(cat <<JSON
{
"clientId": "grafana-oidc",
"protocol": "openid-connect",
"publicClient": true,
"standardFlowEnabled": true,
"directAccessGrantsEnabled": false,
"serviceAccountsEnabled": false,
"attributes": { "pkce.code.challenge.method": "S256" },
"redirectUris": [ "${GRAFANA_REDIRECT}" ],
"webOrigins": ["+"]
}
JSON
)

VUE_CLIENT_JSON=$(cat <<JSON
{
"clientId": "vue-client",
"protocol": "openid-connect",
"publicClient": true,
"standardFlowEnabled": true,
"directAccessGrantsEnabled": false,
"serviceAccountsEnabled": false,
"attributes": { "pkce.code.challenge.method": "S256" },
"redirectUris": [
"http://host.docker.internal:3001/*",
"http://host.docker.internal:3000/*"
],
"webOrigins": ["+"]
}
hg
JSON
)

# JSON payloads (always OBJECT, never ARRAY)
KONG_CLIENT_JSON=$(cat <<'JSON'
{
"clientId": "kong-client",
"protocol": "openid-connect",
"publicClient": false,
"secret": "Y5a9BdyNApDFr4rsiOAlKdt8VJ79un8F",
"standardFlowEnabled": true,
"directAccessGrantsEnabled": false,
"serviceAccountsEnabled": false,
"attributes": { "pkce.code.challenge.method": "" },
"redirectUris": [
"http://host.docker.internal:3001/*",
"http://host.docker.internal:3000/*",
"http://host.docker.internal:8000/*",
"http://host.docker.internal:8083/*"
],
"webOrigins": ["+"]
}
JSON
)
log() { echo "[init] $*"; }
kc() { /opt/keycloak/bin/kcadm.sh "$@"; }

# Try both base paths; loop until login works
detect_and_login() {
base1="http://127.0.0.1:8080"
base2="http://127.0.0.1:8080/auth"
i=1
while [ "$i" -le 60 ]; do
if kc config credentials --server "$base1" --realm master \
--user "$ADMIN_USER" --password "$ADMIN_PASS" >/dev/null 2>&1; then
echo "$base1"; return 0
fi
if kc config credentials --server "$base2" --realm master \
--user "$ADMIN_USER" --password "$ADMIN_PASS" >/dev/null 2>&1; then
echo "$base2"; return 0
fi
log "Keycloak not ready yet... ($i/60)"
i=$((i+1))
sleep 2
done
echo "[init][error] Unable to login to Keycloak" >&2
exit 1
}

ensure_realm() {
if ! kc get "realms/${REALM}" >/dev/null 2>&1; then
kc create realms -s realm="$REALM" -s enabled=true -s sslRequired=NONE
fi
}

# Upsert a client from a JSON OBJECT string
upsert_client() {
client_id="$1"
json="$2"
ids="$(kc get clients -r "$REALM" -q clientId="$client_id" --fields id --format csv --noquotes || true)"
# pack to single line
ids="$(echo "$ids" | sed '/^$/d' | tr '\n' ' ')"
set -- $ids
count=$#

if [ "$count" -eq 0 ]; then
log "[create] client $client_id"
printf '%s' "$json" | kc create clients -r "$REALM" -f -
else
first="$1"
# delete duplicates if any
if [ "$count" -gt 1 ]; then
shift
for dup in "$@"; do
log "[cleanup] duplicate $client_id id=$dup"
kc delete "clients/$dup" -r "$REALM" || true
done
fi
log "[update] client $client_id id=$first"
printf '%s' "$json" | kc update "clients/$first" -r "$REALM" -f -
fi
}

# Upsert a user (set password every time to keep it deterministic)
upsert_user() {
uname="$1"; email="$2"; pass="$3"
ids="$(kc get users -r "$REALM" -q username="$uname" --fields id --format csv --noquotes || true)"
ids="$(echo "$ids" | sed '/^$/d' | tr '\n' ' ')"
set -- $ids
count=$#

if [ "$count" -eq 0 ]; then
log "[create] user $uname"
uid="$(kc create users -r "$REALM" -s username="$uname" -s enabled=true -s email="$email" -s emailVerified=true --id)"
kc set-password -r "$REALM" --userid "$uid" --new-password "$pass"
else
uid="$1"
log "[update] user $uname id=$uid"
kc update "users/$uid" -r "$REALM" -s email="$email" -s enabled=true -s emailVerified=true || true
kc set-password -r "$REALM" --userid "$uid" --new-password "$pass"
fi
}


# ---------------- Main ----------------
BASE="$(detect_and_login)"
log "Logged in via base: $BASE"
ensure_realm
upsert_client "kong-client" "$KONG_CLIENT_JSON"
upsert_client "grafana-oidc" "$GRAFANA_CLIENT_JSON"
upsert_client "vue-client" "$VUE_CLIENT_JSON"
upsert_user "$USER_NAME" "$USER_EMAIL" "$USER_PASS"
log "✅ done (realm=$REALM, clients: kong-client, grafana-oidc, user: $USER_NAME)"