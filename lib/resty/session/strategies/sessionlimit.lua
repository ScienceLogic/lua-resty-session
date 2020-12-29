local tonumber = tonumber
local default = require "resty.session.strategies.default"
local regenerate = require "resty.session.strategies.regenerate"

local concat  = table.concat

local defaults = {
    concurrent_limit = tonumber(ngx.var.session_concurrent_limit) or 0
}

local strategy = {
  start   = regenerate.start,
  destroy = regenerate.destroy,
  close   = regenerate.close,
  open    = regenerate.open,
  touch   = regenerate.touch
}

local function key(source)
  if source.usebefore then
    return concat{ source.id, source.usebefore }
  end

  return source.id
end

local function check_open_sessions(session)
    -- set configuration
    local config = session.sessionlimit or defaults
    -- check for current user session
    if config.concurrent_limit > 0 then
        ngx.log(ngx.DEBUG, "concurrent limit being checked...")
        if session.data and session.data.user then
            ngx.log(ngx.DEBUG, "user email: " .. session.encoder.encode(session.data.user.email))
            -- take encoded email and slice to -2 to account for the padding flipping the last char exclude locks
            -- TODO: could the -2 chars on the hash cause collisions? needs exploration
            local encoded_name = session.encoder.encode(session.data.user.email)
            local res = session.storage:scan(string.sub(encoded_name, 1, #encoded_name-2) .. "*[^.lock]")
            if res and #res[2] >= config.concurrent_limit then
                ngx.log(ngx.ERR, "session limit reached for user: " .. session.data.user.email)
                return nil
            end
            ngx.log(ngx.DEBUG, "Limit not reached for user ID: " .. session.data.user.email .. " res: " .. type(res))
            return true
        end
    end
    ngx.log(ngx.DEBUG, "Session limits not configured")
    return true
end

function strategy.save(session, close)
    local storage = session.storage
    ngx.log(ngx.DEBUG, "Strategy save process...")
    if session.present then
        if storage.ttl then
            storage:ttl(session.encoder.encode(session.id), session.cookie.discard, true)
        elseif storage.close then
            storage:close(session.encoder.encode(session.id))
        end

        session.id = session:identifier()
    end
    if check_open_sessions(session) then
        ngx.log(ngx.DEBUG, "Saving session")
        return default.modify(session, "save", close, key(session))
    else
        ngx.log(ngx.STDERR, "Session limit reach session can not be saved")
        return nil
    end
end

return strategy