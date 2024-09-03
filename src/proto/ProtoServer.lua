local ProtoObject = require(script.Parent.Parent.objects.ProtoObject)
local ParallelObject = require(script.Parent.Parent.objects.ParallelObject)
local Promise = require(script.Parent.Parent.Packages.Promise)
local Network = require(script.Parent.Parent.networking)

type ServiceProps = { Name: string, HasNetworkModel: boolean }

local REMOTE_EVENT_MARKER = newproxy()
local REMOTE_FUNCTION_MARKER = newproxy()

local HasProtoStarted = false
local HasProtoStartedEvent = Instance.new("BindableEvent")
local ProtoServices = {}

local function getScriptNameRecursive(stack: number?)
    stack = stack or 3
    local curEnv = getfenv(stack)
    if curEnv.script ~= nil then
        return curEnv.script.Name
    else
        return getScriptNameRecursive(stack+1)
    end
end

--[=[
    @class ProtoServer
    @server
]=]
local ProtoServer = {
    RemoteEventMarker = REMOTE_EVENT_MARKER,
    RemoteFunctionMarker = REMOTE_FUNCTION_MARKER,
}

function ProtoServer.CreateService(serviceProps: ServiceProps): {any}
    if not serviceProps.Name or #serviceProps.Name <= 0 then
        serviceProps.Name = getScriptNameRecursive()
    end
    local object = ProtoObject.extend()
    object.Name = serviceProps.Name
    object.HasNetworkModel = if object.HasNetworkModel then object.HasNetworkModel else true
    ProtoServices[serviceProps.Name] = object
    return object
end

function ProtoServer.GetParallelFactory()
    return table.clone(ParallelObject)
end

function ProtoServer.GetService(serviceName: string): {any}
    assert(HasProtoStarted, "Proto has not started yet!")
    assert(#serviceName > 0, "Argument 1 must be a non-empty string!")
    return assert(ProtoServices[serviceName], `Could not find controller "{ serviceName }"`)
end

function ProtoServer.LoadDependencies(folder: Folder, deep: boolean?)
    local loaded = {}
    local function bulkImport(folder_: Folder)
        for _, moduleOrFolder in ipairs(folder_:GetChildren()) do
            if moduleOrFolder:IsA("ModuleScript") then
                table.insert(loaded, require(moduleOrFolder))
            elseif moduleOrFolder:IsA("Folder") and deep == true then
                bulkImport(moduleOrFolder)
            end
        end
    end
    bulkImport(folder)
    return loaded
end

function ProtoServer.Start()
    if HasProtoStarted then
        error("Proto has already started!", 2)
    end

    return Promise.new(function(resolve)
        local services = {}
        for name, service in pairs(ProtoServices) do
            table.insert(services, Promise.new(function(r)
                -- allow function overloading
                local serviceObject = service.new()
                serviceObject.Name = name

                if service.HasNetworkModel then
                    serviceObject.NetworkBridge = Network.new(name)
                end
--[[
                -- set up Network
                if service.Network and getSize(service.Network) > 0 then
                    Network.inherits(serviceObject)
                    local networkObject = Network.new(service.Name)
                    networkObject.Server = serviceObject
                    for key, networkType in pairs(service.Network) do
                        if networkType == REMOTE_FUNCTION_MARKER then
                            networkObject:__makeFunction(key)
                        elseif networkType == REMOTE_EVENT_MARKER then
                            networkObject:__makeEvent(key)
                        elseif type(networkType) == "function" then
                            networkObject:__makeMethod(key, service.Network, networkObject)
                        end
                    end
                    serviceObject.Network = networkObject
                end
]]
                if serviceObject.ProtoInit then
                    task.spawn(function()
                        serviceObject:ProtoInit()
                    end)
                end
                ProtoServices[name] = serviceObject
                r(serviceObject)
            end):catch(warn))
        end
        HasProtoStarted = true
        HasProtoStartedEvent:Fire()
        HasProtoStartedEvent:Destroy()
        Promise.all(services):catch(warn):andThen(function(initServices)
            for _, service in ipairs(initServices) do
                if service.ProtoStart then
                    task.spawn(function()
                        service:ProtoStart()
                    end)
                end
            end
        end)
        resolve()
    end)
end

function ProtoServer.OnStarted()
    if HasProtoStarted then
        return Promise.resolve()
    else
        return Promise.fromEvent(HasProtoStartedEvent.Event)
    end
end

return ProtoServer