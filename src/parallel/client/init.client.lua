local PublishEvent = script.Parent.Publish :: BindableEvent
local RequestEvent = script.Parent.Request :: BindableEvent

local Pointer = (script.Parent.Pointer :: ObjectValue).Value :: ModuleScript?
assert(Pointer:IsA("ModuleScript"), `Pointer(?) {Pointer} must be a ModleScript`)

local Worker = require(Pointer)
local staticCallFunctions = true

if Worker.new then
    staticCallFunctions = false
    Worker = Worker.new(script:GetActor())
    task.spawn(function()
        if Worker.WorkerSubscribed then
            Worker:WorkerSubscribed()
        end
    end)
end

RequestEvent.Event:ConnectParallel(function(target: string, ...)
    local returnValues = table.pack(if staticCallFunctions then Worker[target](...) else Worker[target](Worker, ...))
    PublishEvent:Fire(if returnValues.n > 0 then table.unpack(returnValues) else nil)
end)