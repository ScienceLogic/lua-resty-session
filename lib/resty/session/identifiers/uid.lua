local random   = require "resty.random".bytes

local defaults = {
    length = 10
}

return function(session)
    local length = defaults.length
    local uid = ''
    local pad = random(length, true) or random(length)
    if session.data and session.data.user then
        uid = session.data.user.email
        local id_encoded = session.encoder.encode(uid .. pad)
        ngx.log(ngx.DEBUG, "new session: " .. id_encoded .. " old session: " .. session.encoder.encode(session.id))
        ngx.log(
                ngx.WARN, "authenticated session created for " .. uid)
    else
        ngx.log(ngx.DEBUG, "non authenticated session id: " .. session.encoder.encode(pad))
        ngx.log(ngx.WARN, "session create for non authenticated user")
    end

    -- return uid if avalible with padding
    return (uid .. pad)
end
