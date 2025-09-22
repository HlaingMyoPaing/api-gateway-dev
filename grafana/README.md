# Grafana OSS + Keycloak (OIDC) with Postgres DB

> **Important**: Grafana **OSS does not support SAML**. If you need **SAML 2.0**, use Grafana **Enterprise**. For OSS, the supported federated login is **OIDC** (Generic OAuth), which is configured here with Keycloak.

## What’s included
- **Grafana OSS** using a dedicated **Postgres** database (no SQLite)
- **Keycloak** as the IdP
- **OIDC** wired between Grafana and Keycloak
- Auto-provision script to create the Keycloak realm and the Grafana OIDC client

## Run it

```bash
cp .env.example .env
docker compose up -d
```

- Grafana: http://localhost:${GRAFANA_HTTP_PORT}  (admin/admin)
- Keycloak: http://localhost:8081  (admin/admin)

## Where is SAML?
Grafana OSS cannot use SAML. If you absolutely require SAML with Keycloak, switch to **grafana/grafana-enterprise** and configure `[auth.saml]` in `grafana.ini` (Enterprise license required).

## Customization
- Change realm and client names in `.env` and `keycloak/init/keycloak-setup.sh`
- Lock down passwords and enable HTTPS in real deployments.
