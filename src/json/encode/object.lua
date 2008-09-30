local jsonencode = require("json.encode")

local pairs = pairs
local assert = assert

local type = type
local tostring = tostring

local table_concat = table.concat

local strings = require("json.encode.strings")

module("json.encode.object")

function encode(tab, options)
	local encodeValue = jsonencode.encodeValue
	local encodeString = strings.encode
	local retVal = {}
	-- Is table
	for i, v in pairs(tab) do
		local ti = type(i)
		assert(ti == 'string' or ti == 'number' or ti == 'boolean', "Invalid object index type: " .. ti)
		i = encodeString(tostring(i), options)

		retVal[#retVal + 1] = i .. ':' .. encodeValue(v, options)
	end
	return '{' .. table_concat(retVal, ',') .. '}'
end
