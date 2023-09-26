local RunService = game:GetService("RunService")
local PRIVATE_MARKER = newproxy() -- only the class and inherited class can access it
local PROTECTED_MARKER = newproxy() -- only the class and inherited can read and write; will only be read-only for other sources
local INHERITED_MARKER = newproxy()
local INHERITS_MARKER = newproxy()
local STRICTIFIY_VALUE_MARKER = newproxy()
local INTERNAL_MARKER = newproxy()
local PUBLIC_MARKER = newproxy()
local LOCKED_MARKER = newproxy() -- cant change after runtime fr
local SPECIAL_HANDLER_MARKER = newproxy()
local PROP_CHANGED_SIGNALS_MARKER = newproxy()
local FUNCTION_OVERLOAD_MARKER = newproxy()

local EXPLICIT_PRIVATE_PREFIX = "_"
local EXPLICIT_PROTECTED_PREFIX = "__"

local READ_PRIVATE_NO_ACCESS = "Attempted to read private \"%s\""
local READ_INTERNAL_FAILED = "Cannot read internal property \"%s\""
local WRITE_PRIVATE_NO_ACCESS = "Attempted to write private \"%s\" with the value \"%s\""
local WRITE_PROTECTED_NO_ACCESS = "Attempted to write protected \"%s\" with the value \"%s\""
local WRITE_INTERNAL_FAILED = "Cannot write internal property \"%s\""
local CANNOT_WRITE_CONSTANT = "Attempted to overwrite constant \"%s\""
local CANNOT_WRITE_LOCKED = "Attempt to overwrite locked property \"%s\""

local CLONE_IGNORE_PROPERTIES = {'new', 'extend', 'inherits'}
local IGNORE_OVERLOADS_OF = {'OnPropertyChanged', '__wrapSignal', '__lockProperty', '__unlockProperty', '__strictifyProperty__', '__canStrictifyProperties__', '__canMakeConstants__', '__propChangedSignals__', '__wrapCoroutine', '__wrapTask', '__registerSpecialHandler__'}
local AUTOLOCK_PROPERTIES = {'__wrapSignal', '__lockProperty', '__unlockProperty', '__strictifyProperty__', '__canStrictifyProperties__', '__canMakeConstants__', '__propChangedSignals__', '__wrapCoroutine', '__wrapTask', '__registerSpecialHandler__', 'OnPropertyChanged', '__canOverloadFunctions__'}

local IS_STUDIO = RunService:IsStudio()

local NO_READING_METATABLE = { __tostring = if IS_STUDIO then nil else function()
	return "{}"
end, __metatable = if IS_STUDIO then nil else {} }
local NO_READING_METATABLE_WITH_WEAK_KEY_MODE = { __tostring = if IS_STUDIO then nil else function()
	return "{}"
end, __metatable = if IS_STUDIO then nil else {}, __mode = 'k' }

local function hasFunction(class, method)
	for _, fn in pairs(class) do
		if type(fn) == "function" and fn == method then
			return true
		end
	end
	return false
end

local function canAccessViaInheritance(class, methodOrClass)
	for inherited in pairs(class[INHERITED_MARKER]) do
		if (type(methodOrClass) == "table" and inherited == methodOrClass) or hasFunction(inherited, methodOrClass) then
			return true
		end
	end
	return false
end

local function evaluateValueForOverloading(self, value)
	if typeof(value) ~= "function" then
		return value
	end
	
	local ok, methodName = pcall(debug.info, value, 'n')
	if ok then
		local overloads = rawget(self, FUNCTION_OVERLOAD_MARKER)
		return overloads[methodName] or value
	end
end

local function isWithinClassScope(class, self, includeInherited)
	local level = 3--skip pcall, debug.info and __index or __newindex
	local within = false
	local calledWithinFunction = false
	repeat
		level += 1
		local _, method = pcall(debug.info, level, 'f')
		local _, methodName = pcall(debug.info, level, 'n')
		if not method then break end

		if hasFunction(class, method) or class[methodName] == method or rawget(self, SPECIAL_HANDLER_MARKER)[method] ~= nil or rawget(self, FUNCTION_OVERLOAD_MARKER)[methodName] ~= nil then
			calledWithinFunction = true
		end

		local result = calledWithinFunction or (if includeInherited then canAccessViaInheritance(class, method) else false)
		if result then
			within = true
		end
	until within
	return within
end

local function isSpecialKey(key)
	return type(key) == "userdata"
end

local function isAConstant(str: string)
	if isSpecialKey(str) then return false end
	str = str:gsub('_', '') -- remove underscores
	local compare = str:gsub('(%l)', '')
	return #compare == #str
end

local function isAccessingInternal(key)
	return not isSpecialKey(key) and key:sub(1, 2) == EXPLICIT_PROTECTED_PREFIX and key:sub(#key - #EXPLICIT_PROTECTED_PREFIX+1) == EXPLICIT_PROTECTED_PREFIX
end

local function isAccessingProtected(key)
	return not isSpecialKey(key) and key:sub(1, 2) == EXPLICIT_PROTECTED_PREFIX and key:sub(#key - #EXPLICIT_PROTECTED_PREFIX) ~= EXPLICIT_PROTECTED_PREFIX
end

local function isAccessingPrivate(key)
	return not isSpecialKey(key) and key:sub(1, 2) ~= EXPLICIT_PROTECTED_PREFIX and key:sub(#key - #EXPLICIT_PROTECTED_PREFIX) ~= EXPLICIT_PROTECTED_PREFIX and key:sub(1, 1) == EXPLICIT_PRIVATE_PREFIX
end

local function initSelf(class, defaultProps, classProps)
	local markers, realProps = {
		[PRIVATE_MARKER] = setmetatable({}, NO_READING_METATABLE),
		[PROTECTED_MARKER] = setmetatable({}, NO_READING_METATABLE),
		[LOCKED_MARKER] = setmetatable({}, NO_READING_METATABLE),
		[INTERNAL_MARKER] = setmetatable({}, NO_READING_METATABLE),
		[STRICTIFIY_VALUE_MARKER] = setmetatable({}, NO_READING_METATABLE_WITH_WEAK_KEY_MODE),
		[PUBLIC_MARKER] = setmetatable({}, NO_READING_METATABLE),
		[PROP_CHANGED_SIGNALS_MARKER] = setmetatable({}, NO_READING_METATABLE),
		[SPECIAL_HANDLER_MARKER] = setmetatable({}, NO_READING_METATABLE_WITH_WEAK_KEY_MODE),
	}, {}

	local function insert(source)
		for key, value in pairs(source) do
			if CLONE_IGNORE_PROPERTIES[key] then continue end
			if isSpecialKey(key) then
				markers[key] = value
			else
				realProps[key] = value
			end
		end
	end

	insert(class)
	insert(classProps)
	if defaultProps then
		insert(defaultProps)
	end

	return markers, realProps
end

local function pasteSelf(self, props)
	for key, value in pairs(props) do
		self[key] = value
	end
end

local function Class(defaultProps: {}?)
	local properties = {}
	local meta = {}
	local class = {}
	class[FUNCTION_OVERLOAD_MARKER] = setmetatable({}, NO_READING_METATABLE)
	class[INHERITS_MARKER] = setmetatable({}, NO_READING_METATABLE)
	class[INHERITED_MARKER] = setmetatable({}, NO_READING_METATABLE)

	function meta:__iter()
		local clone = {}
		for k, v in pairs(rawget(self, PUBLIC_MARKER)) do
			if typeof(v) == "function" then continue end
			clone[k] = v
		end
		for k, v in pairs(rawget(self, PROTECTED_MARKER)) do
			if typeof(v) == "function" then continue end
			clone[k:sub(3,3):upper()..k:sub(4)] = v
		end
		return next, clone
	end

	function meta:__index(key)
		local accessingPrivate, accessingInternal = isAccessingInternal(key), isAccessingPrivate(key)
		local canAccessPrivate, canAccessInternal = if accessingPrivate then isWithinClassScope(class, self, true) else false, if accessingInternal then isWithinClassScope(class, self, false) else false
		if accessingInternal and not canAccessInternal then
			error(string.format(READ_INTERNAL_FAILED, key), 2)
		elseif accessingPrivate and not canAccessPrivate then
			error(string.format(READ_PRIVATE_NO_ACCESS, key), 2)
		end

		local public = rawget(self, PUBLIC_MARKER)
		local protected = rawget(self, PROTECTED_MARKER)
		local result = protected[key] or public[key]
		if canAccessPrivate or canAccessInternal then
			local foundInternal = rawget(self, INTERNAL_MARKER)[key]
			if foundInternal ~= nil then return evaluateValueForOverloading(self, foundInternal) end
			local foundPrivate = rawget(self, PRIVATE_MARKER)[key]
			if foundPrivate ~= nil then return evaluateValueForOverloading(self, foundPrivate) end
		end
		return evaluateValueForOverloading(self, result)
	end

	function meta:__newindex(key, value)
		local accessingPrivate, accessingProtected, accessingLocked, accessingInternal = isAccessingPrivate(key), isAccessingProtected(key), rawget(self, LOCKED_MARKER)[key:sub(2)] ~= nil, isAccessingInternal(key)
		if accessingLocked then
			error(string.format(
				if isAConstant(key) then CANNOT_WRITE_CONSTANT else CANNOT_WRITE_LOCKED,
				key), 2)
		elseif accessingInternal and not isWithinClassScope(class, self, false) then
			error(string.format(WRITE_INTERNAL_FAILED, key), 2)
		elseif (accessingPrivate or accessingProtected) and not isWithinClassScope(class, self, true) then
			error(string.format(
				if accessingPrivate then WRITE_PRIVATE_NO_ACCESS else WRITE_PROTECTED_NO_ACCESS,
				tostring(key), tostring(value)), 2)
		else
			local internal, private, protected, public = rawget(self, INTERNAL_MARKER),
			rawget(self, PRIVATE_MARKER),
			rawget(self, PROTECTED_MARKER),
			rawget(self, PUBLIC_MARKER)
			
			local oldValue = internal[key] or private[key] or protected[key] or public[key]
			if oldValue == value then
				return
			end

			local predicate = rawget(self, STRICTIFIY_VALUE_MARKER)[key]
			if predicate ~= nil then
				local ok, err = predicate(value)
				if not ok then
					error(err or "Failed to set strict property", 2)
				end
			end

			if isAConstant(key) and not rawget(self, INTERNAL_MARKER).__canMakeConstants__ then
				error("Cannot initialize constant '" .. key .. "' after initialization", 2)
			end

			if accessingInternal then
				internal[key] = value
			elseif accessingPrivate then
				private[key] = value
			elseif accessingProtected then
				protected[key] = value
			else
				if key == PROTECTED_MARKER or key == PRIVATE_MARKER then
					error("Cannot override internal properties", 2)
				end
				public[key] = value
			end

			local foundChangedSignal = rawget(self, PROP_CHANGED_SIGNALS_MARKER)[key] :: BindableEvent | nil
			if foundChangedSignal then
				foundChangedSignal:Fire(value, oldValue)
			end
		end
	end

	function class.new<T>(...): T
		local markers, realProps = initSelf(class, defaultProps, properties)
		local self = setmetatable(markers, meta)
		self.__canMakeConstants__ = true
		self.__canStrictifyProperties__ = true
		self.__canOverloadFunctions__ = true
		
		pasteSelf(self, realProps)
		if self.__init then
			self:__init(...)
		end

		self.__canOverloadFunctions__ = false

		-- now check the constants
		for key, value in pairs(self) do
			if isAConstant(key) and type(value) ~= "function" then
				self[LOCKED_MARKER][key] = true
				if type(value) == "table" then
					table.freeze(value)
				end
			end
		end

		self.__canMakeConstants__ = false
		self.__canStrictifyProperties__ = false

		for _, key in next, AUTOLOCK_PROPERTIES do
			self:__lockProperty(key)
		end

		return self
	end

	function class.inherits(otherClass)
		assert(otherClass[INHERITED_MARKER] ~= nil, "Cannot inherit from an unrelated class or table")
		class[INHERITS_MARKER][otherClass] = true
		otherClass[INHERITED_MARKER][class] = true
	end

	function class.extend()
		local subClass = Class(defaultProps)
		for k, v in pairs(class) do
			if subClass[k] == nil then
				subClass[k] = v
			end
		end
		setmetatable(subClass, {__index = class})
		return subClass
	end

	function class:OnPropertyChanged(propName: string, handler: (...any) -> ()): RBXScriptConnection
		local signal = self[PROP_CHANGED_SIGNALS_MARKER][propName]
		if not signal then
			signal = Instance.new("BindableEvent")
			signal.Name = propName
			self[PROP_CHANGED_SIGNALS_MARKER][propName] = signal
		end
		local conn = self:__wrapSignal(signal.Event, handler)
		return conn
	end

	function class:__strictifyProperty__(propName: string, predicate: (value: any) -> boolean)
		assert(self.__canStrictifyProperties__ == true, "Cannot strictify properties after initialization")
		self[STRICTIFIY_VALUE_MARKER][propName] = predicate
	end

	-- the target function that is going to be overloaded is best to be left empty!
	function class:__overloadTargetFunction__(key: string, expects: {string | {string}}, func: (...any) -> (...any))
		assert(not IGNORE_OVERLOADS_OF[key], "Cannot overload an internal function!")
		assert(self.__canOverloadFunctions__, "Cannot overload functions after initialization!")
		local overloads = self[FUNCTION_OVERLOAD_MARKER]
		local hasOverload = overloads[key] ~= nil
		if not hasOverload then
			overloads[key] = setmetatable({}, {
				__call = function(tbl, ...)
					local args = {...}
					local mustOffset = false
					if getmetatable(args[1]) == getmetatable(self) then
						mustOffset = true
					end
					local argCount = if mustOffset then #args-1 else #args
					local sorted = {}
					for i = 1, #tbl do
						if tbl[i].argumentCount == argCount or tbl[i].isVariaDic then
							table.insert(sorted, {tbl[i], if tbl[i].isVariaDic then math.huge + (tbl[i].argumentCount - argCount) else #sorted+1})
						end
					end

					local target = nil
					if #sorted > 0 then
						table.sort(sorted, function(a, b)
							return a[2] < b[2]
						end)

						for i = 1, #sorted do
							local overloadInfo = sorted[i][1]
							local ok = true
							for j = if mustOffset then 2 else 1, #args do
								local typ = typeof(args[j])
								local expected = overloadInfo.expectsAs[if mustOffset then j - 1 else j]
								if type(expected) == "table" then
									ok = false
									for n = 1, #expected do
										if expected[n] == "any" or typ == expected[n] then
											ok = true
											break
										end
									end
								elseif type(expected) == "string" then
									if expected ~= "any" then
										if typ ~= expected then
											ok = false
										end
									end
								end
							end
							if ok or (argCount > overloadInfo.argumentCount and overloadInfo.isVariaDic) then
								target = overloadInfo.callback
								break
							end
						end
					end

					return target(unpack(args, if mustOffset then 2 else 1, #args))
				end
			})
		end

		local argCount, isVariaDic = debug.info(func, 'a')
		table.insert(overloads[key], {
			expectsAs = expects,
			argumentCount = argCount,
			isVariaDic = isVariaDic,
			callback = self:__registerSpecialHandler__(func),
		})
	end

	function class:__registerSpecialHandler__(handler)
		self[SPECIAL_HANDLER_MARKER][handler] = true
		return handler
	end

	function class:__wrapSignal(signal, handler)
		return signal:Connect(self:__registerSpecialHandler__(handler))
	end

	function class:__wrapCoroutine(coroutine, handler)
		return coroutine(self:__registerSpecialHandler__(handler))
	end

	function class:__wrapTask(task, ...)
		local args = {...}
		for i = 1, #args do
			if type(args[i]) == "function" then
				self:__registerSpecialHandler__(args[i])
				break
			end
		end
		return task(unpack(args))
	end

	function class:__lockProperty(propName: string)
		self[LOCKED_MARKER][propName] = true
	end

	function class:__unlockProperty(propName: string)
		assert(not isAConstant(propName), "Cannot unlock a constant!")
		self[LOCKED_MARKER][propName] = nil
	end

	function class:__internalDestroy__()
		for _, signal in pairs(self[PROP_CHANGED_SIGNALS_MARKER]) do
			signal:Destroy()
		end
		table.clear(self[FUNCTION_OVERLOAD_MARKER])
		table.clear(self[SPECIAL_HANDLER_MARKER])
		table.clear(self[FUNCTION_OVERLOAD_MARKER])
		table.clear(self[STRICTIFIY_VALUE_MARKER])
		setmetatable(self, nil)
		table.clear(self)
	end

	return class
end

return Class