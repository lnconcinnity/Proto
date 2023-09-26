local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Class = require(script.Parent.Parent.util.Class)
local packet = require(script.Parent.util.packet)
local identity = require(script.Parent.util.identity)

local IS_SERVER = RunService:IsServer()

local Bridge = Class {}

function Bridge:__init(bridgeKey: string, source: {}?)
    self.Identity = identity.GetIdentity(bridgeKey)
    self._source = source
    self._remotes = {}

    packet.ConnectBridgeToPacketNetwork(self)
end

function Bridge:__getEvent(eventName: string)
    local event = self._remotes[eventName]
    assert(event._type == 0, eventName .. " is not an Event object")
    return if event then event.callback else nil
end

function Bridge:__getMethod(methodName: string)
    local method = self._remotes[methodName]
    assert(method._type == 1, methodName .. " is not a Method object")
    return if method then method.callback else nil
end

function Bridge:__bindToRemoteObject__(remoteName: string, remoteType: number, options: {} | nil, callback: (...any) -> ()): () -> ()
    self._remotes[remoteName] = {
        _options = options,
        _type = remoteType,
        callback = if self._source then self._source:__sharedInternal_RegisterBridgeConnection(callback) else callback,
        timeCreated = os.clock()
    }
    return function()
        table.clear(self._events[remoteName])
        self._events[remoteName] = nil
    end
end

function Bridge:BindToRemoteMethod(methodName: string, options: {} | nil, callback: (...any) -> ()): () -> ()
    return self:__bindToRemoteObject__(methodName, 1, options, callback)
end

function Bridge:BindToRemoteEvent(eventName: string, options: {} | nil, callback: (...any) -> ()): () -> ()
    return self:__bindToRemoteObject__(eventName, 0, options, callback)
end

if IS_SERVER then
    function Bridge:FireEventFor(targetRemote: string, player: Player, ...: any)
        packet.FireFromBridge(self.Identity, targetRemote, player, ...)
    end

    function Bridge:FireEventFromPredicate(targetRemote: string, predicate: (player: Player) -> (boolean) | nil, ...: any)
        for _, player in ipairs(Players:GetPlayers()) do
            if predicate == nil or predicate(player) == true then
                packet.FireFromBridge(self.Identity, targetRemote, player, ...)
            end
        end
    end

    function Bridge:FireEventAll(targetRemote: string, ...: any)
        self:FireEventFromPredicate(targetRemote, nil, ...)
    end

    function Bridge:FireEventExcept(targetRemote: string, except: Player, ...: any)
        self:FireEventFromPredicate(targetRemote, function(player)
            return player ~= except
        end, ...)
    end

    function Bridge:FireEventForPlayers(targetRemote: string, players: {Player}, ...: any)
        self:FireEventFromPredicate(targetRemote, function(player)
            return table.find(players, player) ~= nil
        end, ...)
    end

    function Bridge:TryInvokeFor(targetRemote: string, player: Player, timeOut: number?, ...: any)
        return packet.TryInvokeFromBridge(self.Identity, targetRemote, player, timeOut, ...)
    end
else
    function Bridge:FireEvent(targetRemote: string, ...: any)
        packet.FireFromBridge(self.Identity, targetRemote, ...)
    end

    function Bridge:InvokeServer(targetRemote: string, timeOut: number?, ...: any)
        return packet.InvokeFromBridge(self.Identity, targetRemote, timeOut, ...)
    end
end

return Bridge