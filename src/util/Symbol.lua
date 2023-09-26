return function(name: string): any
    local proxy = newproxy(true)
    getmetatable(proxy).__index = function()
        return string.format("Symbol<%s>", name)
    end
    return proxy
end