local Class = require(script.Parent.Parent.Parent.Parent.util.Class)
local Signal = require(script.Parent.Parent.Parent.Parent.Packages.Signal)

local Value = Class {}
function Value:__init<T>(initialValue: T)
    self._v = initialValue
    self.Changed = Signal.new()
end

function Value:set<T>(newValue: T, forceValue: boolean)
    local old = self._v
    if old ~= newValue or forceValue == true then
        self._v = newValue
        self.Changed:Fire(newValue, old)
    end
end

function Value:get()
    return self._v
end

return Value