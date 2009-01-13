--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local type = type
local assert, error = assert, error
local table_concat = table.concat
local loadstring = loadstring

local setmetatable = setmetatable

local output_utility = require("json.encode.output_utility")

module("json.encode.output")

local tableCompositeCache = setmetatable({}, {__mode = 'v'})

local VALUE_WRITER = [[
	ret[#ret + 1] = %VALUE%
]]

local INNER_WRITER = ""

--[[
	nextValues can output a max of two values to throw into the data stream
	expected to be called until nil is first return value
	value separator should either be attached to v1 or in innerValue
]]
local function defaultTableCompositeWriter(nextValues, beginValue, closeValue, innerValue, composite, encode, state)
	if type(nextValues) == 'string' then
		local fun = output_utility.prepareEncoder(defaultTableCompositeWriter, nextValues, innerValue, VALUE_WRITER, INNER_WRITER)
		local ret = {}
		fun(composite, ret, encode, state)
		return beginValue .. table_concat(ret, innerValue) .. closeValue
	end
end

-- no 'simple' as default action is just to return the value
function getDefault()
	return { composite = defaultTableCompositeWriter }
end
