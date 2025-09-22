local typedefs = require "kong.db.schema.typedefs"

return {
    name = "keycloak-oidc",
    fields = {
        { consumer = typedefs.no_consumer },
        { protocols = typedefs.protocols_http },
        {
            config = {
                type = "record",
                fields = {
                    { client_id      = { type = "string", required = true } },
                    { client_secret  = { type = "string", required = true } },
                    { discovery      = { type = "string", required = true } },
                    { redirect_uri   = { type = "string", required = true } },
                    { session_secret = { type = "string", required = true } },
                    { scopes         = { type = "array", elements = { type = "string" }, default = { "openid" } } },
                },
            },
        },
    },
}