#!/usr/bin/env bash
set -euo pipefail


KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-admin}"
KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin}"
KC_PORT="${KC_PORT:-8080}"
REL_PATH="${KC_HTTP_RELATIVE_PATH:-}" # e.g. /auth if you enabled it
BASE_URL="http://127.0.0.1:${KC_PORT}${REL_PATH}"

# 1. Start Keycloak in background
/opt/keycloak/bin/kc.sh start-dev \
--http-port="${KC_PORT}" \
${REL_PATH:+--http-relative-path="${REL_PATH}"} &

# 2. Wait for Keycloak to accept admin credentials
echo "[entrypoint] Waiting for Keycloak at ${BASE_URL} ..."
for i in $(seq 1 90); do
if /opt/keycloak/bin/kcadm.sh config credentials \
--server "${BASE_URL}" \
--realm master \
--user "${KEYCLOAK_ADMIN}" \
--password "${KEYCLOAK_ADMIN_PASSWORD}" >/dev/null 2>&1; then
echo "[entrypoint] Keycloak is ready (attempt $i)"
break
fi
sleep 2
done


# 3. Run your setup script if present
if [ -x /opt/keycloak/init/create-oidc-client.sh ]; then
echo "[entrypoint] Running create-oidc-client.sh ..."
/opt/keycloak/init/create-oidc-client.sh
fi

# 4. Keep Keycloak in foreground
wait -n
