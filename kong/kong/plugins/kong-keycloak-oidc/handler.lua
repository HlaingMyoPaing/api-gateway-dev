local utils   = require "kong.plugins.kong-keycloak-oidc.utils"
local sessionStorage = require "resty.session"
local kong    = kong

local plugin = {
    PRIORITY = 1000,
    VERSION  = "0.0.1",
}

local function build_auth_url(discovery, conf, state)
    local url = discovery.authorization_endpoint ..
            "?response_type=code" ..
            "&client_id=" .. ngx.escape_uri(conf.client_id) ..
            "&redirect_uri=" .. ngx.escape_uri(conf.redirect_uri) ..
            "&scope=" .. ngx.escape_uri(table.concat(conf.scopes or {"openid"}, " ")) ..
            "&state=" .. ngx.escape_uri(state or "/")
    return url
end

function plugin:access(conf)
    local req_path_qs = kong.request.get_path_with_query()
    local path        = kong.request.get_path()
    local session     = sessionStorage:start({
        secret = conf.session_secret,
        cookie = { samesite = "Lax" },
        lifetime = 60,
        idletimeout = 60
    })

    if path == "/oidc/callback" then
        local args = kong.request.get_query()
        if not args.code then
            return kong.response.exit(400, { message = "Missing authorization code" })
        end

        local discovery, err = utils.get_discovery(conf.discovery)
        if not discovery then
            return kong.response.exit(500, { message = err })
        end

        local token_data, terr = utils.exchange_code(
                discovery.token_endpoint,
                conf.client_id,
                conf.client_secret,
                args.code,
                conf.redirect_uri
        )

        if not token_data or not token_data.id_token then
            return kong.response.exit(500, { message = terr or "Token exchange failed" })
        end

        local id_token, verr = utils.validate_jwt(token_data.id_token)
        if not id_token then
            return kong.response.exit(401, { message = verr or "Invalid ID token" })
        end

        session.data.user         = id_token.payload
        session.data.id_token     = token_data.id_token
        session.data.access_token = token_data.access_token
        local redirect_back    = args.state or session.data.original_uri or "/"
        session:save()
        kong.log("redirect_back : from kong : ", redirect_back)
        return kong.response.exit(302,{message="Redirecting"},{["Location"] = redirect_back})
    end

    if session.data and session.data.user then
        if session.data.access_token then
            kong.log("Authorization , Bearer : ", session.data.access_token)
            kong.service.request.set_header("Authorization", "Bearer " .. session.data.access_token)
        end
        return
    end

    local discovery, err = utils.get_discovery(conf.discovery)
    if not discovery then
        return kong.response.exit(500, { message = err })
    end

    session.data.original_uri = req_path_qs
    session:save()
    local auth_url = build_auth_url(discovery, conf, req_path_qs)
    return kong.response.exit(302,{message="Redirecting"},{["Location"] = auth_url})
end

return plugin