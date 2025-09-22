
local http  = require "resty.http"
local cjson = require "cjson.safe"
local jwt   = require "resty.jwt"

local _M = {}

function _M.get_discovery(url)
    local httpc = http.new()
    local res, err = httpc:request_uri(url, { method = "GET", ssl_verify = false })
    if not res or res.status ~= 200 then
        return nil, "Failed to fetch discovery: " .. (err or tostring(res and res.status or "nil"))
    end
    return cjson.decode(res.body)
end

function _M.exchange_code(token_url, client_id, client_secret, code, redirect_uri)
    local httpc = http.new()
    local res, err = httpc:request_uri(token_url, {
        method = "POST",
        body = ngx.encode_args({
            grant_type = "authorization_code",
            code = code,
            redirect_uri = redirect_uri,
            client_id = client_id,
            client_secret = client_secret,
        }),
        headers = { ["Content-Type"] = "application/x-www-form-urlencoded" },
        ssl_verify = false,
    })
    if not res or res.status ~= 200 then
        return nil, "Failed to exchange code: " .. (err or tostring(res and res.status or "nil"))
    end
    return cjson.decode(res.body)
end

function _M.validate_jwt(id_token)
    local decoded, err = jwt:load_jwt(id_token)
    if not decoded or err then
        return nil, "Invalid JWT: " .. (err or "unknown")
    end
    return decoded
end

return _M
