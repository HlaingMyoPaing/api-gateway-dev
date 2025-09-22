#!/bin/bash
set -euo pipefail

KC_URL=${KC_URL:-http://host.docker.internal:${KEYCLOAK_HTTP_PORT:-8081}}
ADMIN_USER=${KEYCLOAK_ADMIN:-admin}
ADMIN_PASS=${KEYCLOAK_ADMIN_PASSWORD:-admin}
REALM_NAME=${REALM_NAME:-demo}

echo "[init] Waiting for Keycloak to be healthy before running bootstrap..."

/opt/keycloak/bin/kcadm.sh config credentials   --server "$KC_URL" --realm master --user "$ADMIN_USER" --password "$ADMIN_PASS"

if /opt/keycloak/bin/kcadm.sh get "realms/${REALM_NAME}" >/dev/null 2>&1; then
  /opt/keycloak/bin/kcadm.sh update "realms/${REALM_NAME}" -s sslRequired=NONE || true
  echo "[init] Realm '${REALM_NAME}' found. sslRequired set to NONE."
else
  echo "[init][WARN] Realm '${REALM_NAME}' not found after --import-realm."
  exit 1
fi
