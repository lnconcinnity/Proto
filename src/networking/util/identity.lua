local hash = require(script.Parent.hash)

local identities = {}

return table.freeze({
    GetIdentity = function(key: string): string
        if #key >= 32 then
            error("Key is too long")
        end
        if identities[key] then
            return identities[key]
        end
        local identity = hash.sha256(key)
        identities[key] = identity
        return identity
    end,
})