# ---- Base Image ----
#FROM quay.io/keycloak/keycloak:26.0
FROM quay.io/keycloak/keycloak:26.3.3

# ---- Run as default non-root user (UID 1000) ----
# Keycloak image provides a safe non-root user by default.
USER root

# ---- Environment variables ----
# KC_HTTP_ENABLED=true → enable HTTP listener (for dev only).
ENV KC_HTTP_ENABLED=true

COPY init/docker-entrypont.sh /opt/keycloak/docker-entrypont.sh
RUN chmod +x /opt/keycloak/docker-entrypont.sh

COPY init/create-oidc-client.sh /opt/keycloak/init/create-oidc-client.sh
RUN chmod +x /opt/keycloak/init/create-oidc-client.sh


# ---- Entrypoint ----
# - Start Keycloak in dev mode with --import-realm (auto-import JSON).
# - No curl/wget health probe here (handled by docker-compose healthcheck instead).
# - "wait" ensures logs remain attached in foreground.
#ENTRYPOINT ["/bin/bash","-lc","/opt/keycloak/bin/kc.sh start-dev"]
ENTRYPOINT ["/opt/keycloak/docker-entrypont.sh"]

# ---- Ports ----
# Expose only the dev HTTP port.
EXPOSE 8080

USER 1000
