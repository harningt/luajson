--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local type = type
local assert, error = assert, error
local table_concat = require("table").concat
local loadstring = loadstring or load

local io = require("io")

local setmetatable = setmetatable

local output_utility = require("json.encode.output_utility")

local is_52 = _VERSION == "Lua 5.2"
local _G = _G

if is_52 then
	_ENV = nil
end

local tableCompositeCache = setmetatable({}, {__mode = 'v'})

local TABLE_VALUE_WRITER = [[
	ret[#ret + 1] = %VALUE%
]]

local TABLE_INNER_WRITER = ""

--[[
	nextValues can output a max of two values to throw into the data stream
	expected to be called until nil is first return value
	value separator should either be attached to v1 or in innerValue
]]
local function defaultTableCompositeWriter(nextValues, beginValue, closeValue, innerValue, composite, encode, state)
	if type(nextValues) == 'string' then
		local fun = output_utility.prepareEncoder(defaultTableCompositeWriter, nextValues, innerValue, TABLE_VALUE_WRITER, TABLE_INNER_WRITER)
		local ret = {}
		fun(composite, ret, encode, state)
		return beginValue .. table_concat(ret, innerValue) .. closeValue
	end
end

-- no 'simple' as default action is just to return the value
local function getDefault()
	return { composite = defaultTableCompositeWriter }
end

-- BEGIN IO-WRITER OUTPUT
local IO_INNER_WRITER = [[
	if %WRITE_INNER% then
		state.__outputFile:write(%INNER_VALUE%)
	end
]]
local IO_VALUE_WRITER = [[
	state.__outputFile:write(%VALUE%)
]]

local function buildIoWriter(output)
	if not output then -- Default to stdout
		output = io.output()
	end
	local function ioWriter(nextValues, beginValue, closeValue, innerValue, composite, encode, state)
		-- HOOK OUTPUT STATE
		state.__outputFile = output
		if type(nextValues) == 'string' then
			local fun = output_utility.prepareEncoder(ioWriter, nextValues, innerValue, IO_VALUE_WRITER, IO_INNER_WRITER)
			local ret = {}
			output:write(beginValue)
			fun(composite, ret, encode, state)
			output:write(closeValue)
			return nil
		end
	end

	local function ioSimpleWriter(encoded)
		if encoded then
			output:write(encoded)
		end
		return nil
	end
	return { composite = ioWriter, simple = ioSimpleWriter }
end
local function getIoWriter(output)
	return function()
		return buildIoWriter(output)
	end
end

local output = {
	getDefault = getDefault,
	getIoWriter = getIoWriter
}

if not is_52 then
	_G.json = _G.json or {}
	_G.json.encode = _G.json.encode or {}
	_G.json.encode.output = output
end

return output
