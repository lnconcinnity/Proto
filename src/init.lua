--[=[
    @class Proto

    Proto is the container module for both `ProtoClient` and `ProtoServer`
]=]

--[=[
    Alias for the `ActorManager`
    @interface Parallel
    @within Proto
    @tag proto-parallel
    .Request (self: Parallel, target: string, ...: any) -> (...any) -- yields until the parallel actor is done
    .Perform (self: Parallel, target: string, ...: any) -> ()

    :::caution
    `ParallelWorker:Request()` yields the current thread until it completes its task, unlike `ParallelWorker:Perform()`, which does not halt the active thread.
    :::
]=]
--[=[
    An interface for the template `ParallelObject` for parallelization compabilities.
    @interface ParallelObject
    @tag proto-parallel
    @within Proto
    .WorkerSubscribed (self: ParallelObject) -> ()
    .GetActor (self: ParallelObject) -> (Actor)
]=]
--[=[
    An interface for the template `ProtoObject` that `ProtoController` and `ProtoService` extends from.
    @interface ProtoObject
    @tag proto-object
    @within Proto
    .ProtoStart (self: ProtoObject) -> ()
    .ProtoInit (self: ProtoObject) -> ()
    .RegisterParallelWorker (self: ProtoObject, workerName: string, worker: ModuleScript, workerCount: number?) -> (Parallel)
    .GetParallelWorker (self: ProtoObject, workerName: string) -> (Parallel)
]=]
--[=[
    Client extension of a `ProtoObject`.
    @interface ProtoController
    @tag proto-object
    @within ProtoClient
    .Name string -- The identifier of the object
]=]

if game:GetService("RunService"):IsServer() then
    return require(script.proto.ProtoServer)
else
    if script.proto:FindFirstChild("ProtoServer") then
        script.proto.ProtoServer:Destroy()
    end
    return require(script.proto.ProtoClient)
end