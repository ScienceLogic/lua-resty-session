local function hmac_sha256(secret, input)
    local hmac = require("resty.hmac")
    local digest = hmac:new(secret, hmac.ALGOS.SHA256)

    return digest:final(input, false)
end

return hmac_sha256
