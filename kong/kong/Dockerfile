#FROM kong/kong:3.9.1
FROM kong:latest

USER root
# -----------------------------------------------------------------------------
# Install required libraries for Kong plugins
# - build-essential: required to compile some Lua modules
# - git: needed if luarocks fetches modules from Git sources
# - luarocks: already included in Kong image
#
# After installation, we remove build tools to keep the final image small.
RUN apt-get update

COPY ./plugins/kong-keycloak-oidc  /usr/local/share/lua/5.1/kong/plugins/kong-keycloak-oidc

USER kong