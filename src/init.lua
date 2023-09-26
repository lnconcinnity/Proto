if game:GetService("RunService"):IsServer() then
    return require(script.proto.ProtoServer)
else
    if script.proto:FindFirstChild("ProtoServer") then
        script.proto.ProtoServer:Destroy()
    end
    return require(script.proto.ProtoClient)
end