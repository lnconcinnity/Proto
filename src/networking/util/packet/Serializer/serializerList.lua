--!strict

local serializers = { }
local deserializers = { }

-- TODO: add axes
local typeToId = {
	CFrame = "C",
	Vector3 = "V",
	Color3 = "C3",
	EnumItem = "E",
	BrickColor = "B",
	TweenInfo = "T",
	Vector2 = "V2",
	Vector2int16 = "V2i",
	Vector3int16 = "Vi",
	UDim2 = "U2",
	UDim = "U",
	Axes = "A",
	Rect = "R",
	PhysicalProperties = "P",
	NumberRange = "N",
	Ray = "RA",
	DockWidgetPluginGuiInfo = "D",
	PathWaypoint = "PW",
	Region3 = "R3",

	Region3int16 = "R3i",
	Font = "F",
	Tuple = "TU",	
}

local idToType = {
	C = "CFrame",
	V = "Vector3",
	C3 = "Color3",
	E = "EnumItem",
	B = "BrickColor",
	T = "TweenInfo",
	V2 = "Vector2",
	V2i = "Vector2int16",
	Vi = "Vector3int16",
	U = "UDim",
	U2 = "UDim2",
	R = "Rect",
	N = "NumberRange",
	P = "PhysicalProperties",
	RA = "Ray",
	D = "DockWidgetPluginGuiInfo",
	PW = "PathWaypoint",
	R3 = "Region3",
	R3i = "Region3int16",
	A = "Axes",
	F = "Font",
	TU = "Tuple"

}

type serializedCFrame = {typeof(typeToId.CFrame) | number}
type serializedColor3 = {typeof(typeToId.Color3) | number}
type serializedEnumItem = {typeof(typeToId.EnumItem) | number}
type serializedBrickColor = {typeof(typeToId.BrickColor) | string}
type serializedTweenInfo = {typeof(typeToId.TweenInfo) | number | Enum.EasingStyle | Enum.EasingDirection | boolean}
type serializedVector2 = {typeof(typeToId.Vector2) | number}
type serializedVector3 = {typeof(typeToId.Vector3) | number}
type serializedVector2int16 = {typeof(typeToId.Vector2int16) | number}
type serializedVector3int16 = {typeof(typeToId.Vector3int16) | number}
type serializedUDim = {typeof(typeToId.UDim) | number}
type serializedUDim2 = {typeof(typeToId.UDim2) | number}
type serializedRect = {typeof(typeToId.Rect) | number}
type serializedNumberRange = {typeof(typeToId.NumberRange) | number}
type serializedPhysicalProperties = {typeof(typeToId.PhysicalProperties) | number}
type serializedRay = {typeof(typeToId.Ray) | serializedVector3}
type serializedDockWidgetPluginGuiInfo = {typeof(typeToId.Ray) | boolean | number}
type serializedPathWaypoint = {typeof(typeToId.PathWaypoint) | serializedVector3 | serializedEnumItem | string}
type serializedRegion3int16 = {typeof(typeToId.Region3int16) | serializedVector3int16}

type serializedFont = {typeof(typeToId.Font) | string | serializedEnumItem}
type serializedTuple = {typeof(typeToId.Tuple) | any}

type serializedAxes = {typeof(typeToId.Axes)}

-- serializers
function serializers.CFrame(value: CFrame): serializedCFrame
	return {type = typeToId.CFrame, value = {value:GetComponents()}}
end

function serializers.Color3(value: Color3): serializedColor3
	return {type = typeToId.Color3, value = {value.R, value.G, value.B}}
end

function serializers.EnumItem(value: EnumItem): serializedEnumItem
	return {type = typeToId.EnumItem, value = {tostring(value.EnumType), value.Name}}
end

function serializers.BrickColor(value: BrickColor): serializedBrickColor
	return {type = typeToId.BrickColor, value = {value.Name}}
end

function serializers.TweenInfo(value: TweenInfo): serializedTweenInfo
	return {type = typeToId.TweenInfo, value = {value.Time, value.EasingStyle, value.EasingDirection, value.RepeatCount, value.Reverses, value.DelayTime}}
end

function serializers.Vector2(value: Vector2): serializedVector2
	return {type = typeToId.Vector2, value = {value.X, value.Y}}
end

function serializers.Vector2int16(value: Vector2int16): serializedVector2int16
	return {type = typeToId.Vector2int16, value = {value.X, value.Y}}
end

function serializers.Vector3(value: Vector3): serializedVector3
	return {type = typeToId.Vector3, value = {value.X, value.Y, value.Z}} -- it has to be hard
end

function serializers.Vector3int16(value: Vector3int16): serializedVector3int16
	return {type = typeToId.Vector3int16, value = {value.X, value.Y, value.Z}}
end

function serializers.UDim(value: UDim): serializedUDim
	return {type = typeToId.UDim, value = {value.Scale, value.Offset}}
end

function serializers.UDim2(value: UDim2): serializedUDim2
	return {type = typeToId.UDim2, value = {value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset}}
end

function serializers.Rect(value: Rect): serializedRect
	return {type = typeToId.Rect, value = {value.Min.X, value.Min.Y, value.Max.X, value.Max.Y}}
end

function serializers.NumberRange(value: NumberRange): serializedNumberRange
	return {type = typeToId.NumberRange, value = {value.Min, value.Max}}
end

function serializers.PhysicalProperties(value: PhysicalProperties): serializedPhysicalProperties
	return {type = typeToId.PhysicalProperties, value = {value.Density, value.Friction, value.Elasticity, value.FrictionWeight, value.ElasticityWeight}}
end

function serializers.Ray(value: Ray): serializedRay
	return {type = typeToId.Ray, value = {serializers.Vector3(value.Origin), serializers.Vector3(value.Direction)}}
end

function serializers.DockWidgetPluginGuiInfo(value: DockWidgetPluginGuiInfo): serializedDockWidgetPluginGuiInfo
	return {type = typeToId.Ray, value.InitialEnabled, value = {value.InitialEnabledShouldOverrideRestore, value.FloatingXSize, value.FloatingYSize, value.MinWidth, value.MinHeight}}
end

function serializers.PathWaypoint(value: PathWaypoint): serializedPathWaypoint
	return {type = typeToId.PathWaypoint, value = {serializers.Vector3(value.Position), serializers.EnumItem(value.Action), value.Label}}
end

function serializers.Region3int16(value: Region3int16): serializedRegion3int16
	return {type = typeToId.Region3int16, value = {serializers.Vector3int16(value.Min), serializers.Vector3int16(value.Max)}}
end


function serializers.Font(value: Font): serializedFont
	return {type = typeToId.Font, value = {value.Family, serializers.EnumItem(value.Weight), serializers.EnumItem(value.Style)}}
end

function serializers.Tuple<T>(...: T): serializedTuple
	return {type = typeToId.Tuple, value = {...}}
end

-- deserializers (Note these does NOT Check for the type of table's value, if you want it to, use init.lua)

function serializers.Axes(value: Axes) : serializedAxes
	return {
		typeToId.Axes,
		value.X,
		value.Y,
		value.Z,
		value.Back,
		value.Bottom,
		value.Front,
		value.Left,
		value.Right,
		value.Top
	}
end

-- deserializers

function deserializers.CFrame(value: serializedCFrame): CFrame
	return CFrame.new(unpack(value.value))
end

function deserializers.Vector3(value: serializedVector3): Vector3
	return Vector3.new(unpack(value.value))
end

function deserializers.Color3(value: serializedColor3): Color3
	return Color3.new(unpack(value.value))
end

function deserializers.EnumItem(value: serializedEnumItem): EnumItem
	return Enum[value.value[1]][value.value[2]]
end

function deserializers.BrickColor(value: serializedBrickColor): BrickColor
	return BrickColor.new(value.value[1])
end

function deserializers.TweenInfo(value: serializedTweenInfo): TweenInfo
	return TweenInfo.new(unpack(value.value))
end

function deserializers.Vector2(value: serializedVector2): Vector2
	return Vector2.new(unpack(value.value))
end

function deserializers.Vector2int16(value: serializedVector2int16): Vector2int16
	return Vector2int16.new(unpack(value.value))
end

function deserializers.Vector3int16(value: serializedVector3int16): Vector3int16
	return Vector3int16.new(unpack(value.value))
end

function deserializers.UDim(value: serializedUDim): UDim
	return UDim.new(unpack(value.value))
end

function deserializers.UDim2(value: serializedUDim2): UDim2
	return UDim2.new(unpack(value.value))
end

function deserializers.Rect(value: serializedRect): Rect
	return Rect.new(unpack(value))
end

function deserializers.NumberRange(value: serializedNumberRange): NumberRange
	return NumberRange.new(unpack(value.value))
end

function deserializers.PhysicalProperties(value: serializedPhysicalProperties): PhysicalProperties
	return PhysicalProperties.new(unpack(value.value))
end

function deserializers.Ray(value: serializedRay): Ray
	return Ray.new(deserializers.Vector3(value.value[1]), deserializers.Vector3(value.value[2])) -- we deserialize here because we serialized those values
end

function deserializers.DockWidgetPluginGuiInfo(value: serializedDockWidgetPluginGuiInfo): DockWidgetPluginGuiInfo
	return DockWidgetPluginGuiInfo.new(nil, unpack(value.value))
end

function deserializers.PathWaypoint(value: serializedPathWaypoint): PathWaypoint
	return PathWaypoint.new(deserializers.Vector3(value.value[1]), deserializers.EnumItem(value.value[2])) -- we deserialize here because we serialized those values
end

function deserializers.Region3int16(value: serializedRegion3int16): Region3int16
	return Region3int16.new(deserializers.Vector3int16(value.value[1]), deserializers.Vector3int16(value.value[2])) -- we deserialize here because we serialized those values
end


function deserializers.Font(value: serializedFont): Font
	return Font.new(value.value[2], deserializers.EnumItem(value.value[2]), deserializers.EnumItem(value.value[3]))
end

function deserializers.Tuple<T>(value: serializedTuple): ...T
	return unpack(value.value, 2)
end
function deserializers.Axes(value: serializedAxes): Axes
	local valueWithoutTheType = table.unpack(value.value)
	table.remove(valueWithoutTheType, 1)
	return Axes.new(valueWithoutTheType)

end

return table.freeze({
	serializers = table.freeze(serializers),
	deserializers = table.freeze(deserializers),
	typeToId = table.freeze(typeToId),
	idToType = table.freeze(idToType),
})