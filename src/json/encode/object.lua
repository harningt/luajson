local pairs = pairs
local assert = assert

local type = type
local tostring = tostring

local table_concat = table.concat
local util_merge = require("json.decode.util").merge

module("json.encode.object")

local defaultOptions = {
}

default = nil
strict = nil

--[[
	Encode a table as a JSON Object ( keys = strings, values = anything else )
]]
local function encodeTable(tab, options, state)
	local encode = state.encode
	local retVal = {}
	-- Is table
	for i, v in pairs(tab) do
		local ti = type(i)
		assert(ti == 'string' or ti == 'number' or ti == 'boolean', "Invalid object index type: " .. ti)
		i = encode(tostring(i), state)

		retVal[#retVal + 1] = i .. ':' .. encode(v, state)
	end
	return '{' .. table_concat(retVal, ',') .. '}'
end

function getEncoder(options)
	options = options and util_merge({}, defaultOptions, options) or defaultOptions
	return {
		table = function(tab, state)
			return encodeTable(tab, options, state)
		end
	}
end
