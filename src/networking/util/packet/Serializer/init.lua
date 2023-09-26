--!strict

local blueSerializer = { }
local serializerList = require(script.serializerList)

function blueSerializer.serialize<T>(value) : {} | T
	local valueType = typeof(value)
	
	local serializer = serializerList.serializers[valueType]
	if serializer then
		return serializer(value)
	end
	
	return value
end

function blueSerializer.deserialize<T>(value : {}) : T | {}
	local deserializer = serializerList.deserializers[serializerList.idToType[value.type]]
	
	if deserializer then
		return deserializer(value)
	end
	
	return value
end

-- alias
blueSerializer.Deserialize = blueSerializer.deserialize
blueSerializer.Serialize = blueSerializer.serialize
blueSerializer.SerializeTable = function(src: {any}): {any}
    local tbl = {}
    local function deepSerialize(src_: {any}, dst: {any})
        for key, value in next, src_ do
            if type(value) == "table" then
                dst[key] = {}
                deepSerialize(value, dst[key])
            else
                dst[key] = blueSerializer.serialize(value)
            end
        end
    end
    deepSerialize(src, tbl)
    return tbl
end
blueSerializer.DeserializeTable = function(src: {any}): {any}
    local tbl = {}
    local function deepDeserialize(src_: {any}, dst: {any})
        for key, value in next, src_ do
            if type(value) == "table" and (value.type) == nil then
                dst[key] = {}
                deepDeserialize(value, dst[key])
            elseif type(value) == "table" and (value.type) ~= nil then
                dst[key] = blueSerializer.deserialize(value)
            else
                dst[key] = value
            end
        end
    end
    deepDeserialize(src, tbl)
    return tbl
end

return table.freeze(blueSerializer)