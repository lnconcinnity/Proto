local ProtoObject = require(script.Parent.Parent.objects.ProtoObject)
local ParallelObject = require(script.Parent.Parent.objects.ParallelObject)
local Promise = require(script.Parent.Parent.Packages.Promise)
local Network = require(script.Parent.Parent.networking)

type ControllerProps = { any }?
type ProtoController = { Name: string, [any]: any }
type ProtoService = { [string]: {Fire: (...any) -> (), Invoke: (...any) -> (...any), OnInvoked: (...any) -> (...any), Connect: ((Signal: any, callback: (...any) -> ()) -> {Disconnect: () -> ()})}, OnCalled: () -> (...any) }

local HasProtoStarted = false
local HasProtoStartedEvent = Instance.new("BindableEvent")

local ProtoServices = {}
local ProtoControllers = {}

local function getScriptNameRecursive(stack: number?)
    stack = stack or 3
    local curEnv = getfenv(stack)
    if curEnv.script ~= nil then
        return curEnv.script.Name
    else
        return getScriptNameRecursive(stack+1)
    end
end

local ProtoClient = {}
function ProtoClient.GetService(serviceName: string)
    local bridge = ProtoServices[serviceName]
    if not bridge then
        bridge = Network.new(serviceName)
        ProtoServices[serviceName] = bridge
    end
    return bridge
end

function ProtoClient.CreateController(controllerProps: ControllerProps): {any}
    if not controllerProps.Name or #controllerProps.Name <= 0 then
        controllerProps.Name = getScriptNameRecursive()
    end
    local object = ProtoObject.extend()
    object.Name = controllerProps.Name
    ProtoControllers[controllerProps.Name] = object
    return object
end

function ProtoClient.GetParallelFactory()
    return table.clone(ParallelObject)
end

function ProtoClient.GetController(controllerName: string): ProtoController
    assert(HasProtoStarted, "Proto has not started yet!")
    assert(#controllerName > 0, "Argument 1 must be a non-empty string!")
    return assert(ProtoControllers[controllerName], `Could not find controller "{ controllerName }"`)
end

function ProtoClient.AddControllers(folder: Folder, deep: boolean?)
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

function ProtoClient.Start()
    if HasProtoStarted then
        error("Proto has already started!", 2)
    end

    return Promise.new(function(resolve)
        local controllers = {}
        for name, controller in pairs(ProtoControllers) do
            table.insert(controllers, Promise.new(function(r)
                -- allow function overloading
                local controllerObject = controller.new()
                controllerObject.Name = name
                controllerObject:ProtoInit()
                if controllerObject.ProtoInit then
                    task.spawn(function()
                        controllerObject:ProtoInit()
                    end)
                end
                ProtoControllers[name] = controllerObject
                r(controllerObject)
            end):catch(warn))
        end
        HasProtoStarted = true
        HasProtoStartedEvent:Fire()
        HasProtoStartedEvent:Destroy()
        Promise.all(controllers):catch(warn):andThen(function(initControllers)
            for _, controller in ipairs(initControllers) do
                if controller.ProtoStart then
                    task.spawn(function()
                        controller:ProtoStart()
                    end)
                end
            end
        end)
        resolve()
    end)
end

function ProtoClient.OnStarted()
    if HasProtoStarted then
        return Promise.resolve()
    else
        return Promise.fromEvent(HasProtoStartedEvent.Event)
    end
end

return ProtoClient