local jsonutil = require("json.util")

local table_concat = table.concat

local select = select
local getmetatable, setmetatable = getmetatable, setmetatable
local assert = assert

local util_merge = require("json.decode.util").merge
module("json.encode.calls")


local defaultOptions = {
	defs = nil,
	multiArgument = false
}

-- No real default-option handling needed...
default = nil
strict = nil

function buildCall(name, ...)
	return setmetatable({}, {
		callData = {
			name = name,
			parameters = {n = select('#', ...), ...}
		}
	})
end
function isCall(value, options)
	local mt = getmetatable(value)
	return mt and mt.callData
end
local function decodeCall(value)
	local mt = getmetatable(value)
	if not mt and mt.callData then
		return
	end
	return mt.callData.name, mt.callData.parameters
end
--[[
	Encode 'value' as a function call
	Must have parameters in the 'callData' field of the metatable
		name == name of the function call
		parameters == array of parameters to encode
]]
function encode(value, options)
	options = options and util_merge({}, defaultOptions, options) or defaultOptions
	local name, params = decodeCall(value)
	local paramLen = params.n or #params
	if not options.multiArgument then
		assert(paramLen == 1, "Invalid input: encoder configured to support single-parameter calls")
	end
	for i = 1, paramLen do
		local val = params[i]
		if val == nil then
			val = jsonutil.null
		end
		params[i] = jsonencode.encode(val, options)
	end
	return name .. '(' .. table_concat(params, ',') .. ')'
end
