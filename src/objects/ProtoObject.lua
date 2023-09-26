local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Class = require(ReplicatedStorage.Shared.Proto.util.Class)
local ActorManager = require(script.Parent.Parent.util.ActorManager)
local Signal = require(script.Parent.Parent.Packages.Signal)

type Parallel = { Request: (target: string, ...any) -> (...any), Published: Signal.Signal }

local ProtoObject = Class()

function ProtoObject:__init()
    self.__parallelWorkers__ = {}
    self:__lockProperty("__parallelWorkers__")
end

function ProtoObject:ProtoInit()
end

function ProtoObject:ProtoStart()
end

function ProtoObject:RegisterParallelWorker(workerName: string, worker: ModuleScript, workerCount: number?): Parallel
    assert(type(workerName) == "string", "Argument 1 is expected to be a string!")
    assert(#workerName > 0, "Argument 1 must be a non-empty string!")
    self.__parallelWorkers__[workerName] = ActorManager(worker, workerCount, self.Name)
    return self.__parallelWorkers__[workerName]
end

function ProtoObject:GetParallelWorker(workerName: string): Parallel
    assert(#workerName > 0, "Argument 1 must be a non-empty string!")
    return assert(self.__parallelWorkers__[workerName], `Could not find worker "{ workerName }"`)
end

function ProtoObject:__sharedInternal_RegisterBridgeConnection(connectionCallback: () -> ()): () -> ()
    return self:__registerSpecialHandler__(connectionCallback)
end

return ProtoObject