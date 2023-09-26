local ParallelObject = {}
function ParallelObject.new(actor: Actor)
    local self = setmetatable({}, {__index = ParallelObject})
    self.__actor__ = actor
    return self
end

function ParallelObject:GetActor()
    return self.__actor__
end

function ParallelObject:WorkerSubscribed() -- the init of parallel objects
end

return ParallelObject