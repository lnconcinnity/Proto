local Signal = require(script.Parent.Parent.Packages.Signal)

local IS_SERVER = game:GetService("RunService"):IsServer()

local DEFAULT_ACTOR_COUNT = 12
local ACTOR_TEMPLATE = Instance.new("Actor") do
    local src = (if IS_SERVER then script.Parent.Parent.parallel.server else script.Parent.Parent.parallel.client):Clone()
    src.Name = "Subscriber"
    src.Disabled = true
    src.Parent = ACTOR_TEMPLATE

    local publish = Instance.new("BindableEvent")
    publish.Name = "Publish"
    publish.Parent = ACTOR_TEMPLATE
    
    local request = Instance.new("BindableEvent")
    request.Name = "Request"
    request.Parent = ACTOR_TEMPLATE

    local pointerRef = Instance.new("ObjectValue")
    pointerRef.Name = "Pointer"
    pointerRef.Parent = ACTOR_TEMPLATE
end

local ancestor = if IS_SERVER then game:GetService("ServerScriptService") else game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts")
local container = ancestor:FindFirstChild("ActorContainer") or Instance.new("Folder")
container.Name = "ActorContainer"
container.Parent = ancestor

local function makeActor(actorName: string, filter: Folder, pointer: ModuleScript, appendTo: {any}?)
    local actor = ACTOR_TEMPLATE:Clone()
    actor.Name = actorName
    actor.Pointer.Value = pointer
    actor.Subscriber.Disabled = false
    actor.Subscriber.Name = `{actorName}Subscriber`
    actor.Parent = filter
    if appendTo then
        table.insert(appendTo, actor)
    end
    return actor
end

local ActorManagerAPI = {}
function ActorManagerAPI:_waitForActor(): Actor
    self.CurrentActorIndex = self.CurrentActorIndex % self.ActorCount + 1
    return self.Actors[self.CurrentActorIndex]
end

function ActorManagerAPI:Request(target: string, ...: any): (...any)
    local thread = coroutine.running()

    local actor = self:_waitForActor()
    task.spawn(function(...)
        actor.Publish.Event:Once(function(...)
            self.Published:Fire(target, ...)
            task.spawn(thread, ...)
        end)
        actor.Request:Fire(target, ...)
    end, ...)

    return coroutine.yield()
end

function ActorManagerAPI:Perform(target: string, ...: any)
    local actor = self:_waitForActor()
    task.spawn(function(...)
        actor.Request:Fire(target, ...)
    end, ...)
end

return function(sourceScript: ModuleScript, actorCount: number?, nameExtension: string?): Actor
    local filterName = sourceScript.Name
    local filter = container:FindFirstChild(filterName)
    if not filter then
        filter = Instance.new("Folder")
        filter.Name = filterName
        filter.Parent = container
    end

    local actors = {}

    local actorName = if nameExtension then string.format("%s(%s)", filterName, nameExtension) else filterName
    for _ = 1, (actorCount or DEFAULT_ACTOR_COUNT) do
        task.spawn(makeActor, actorName, filter, sourceScript, actors)
    end

    local self = {}
    setmetatable(self, {__index = ActorManagerAPI})
    self._name = actorName
    self._filter = filter
    self._pointer = sourceScript
    self.CurrentActorIndex = 1
    self.ActorCount = #actors
    self.Actors = actors
    self.Published = Signal.new()
    self.ActorRestored = Signal.new()
    return self
end