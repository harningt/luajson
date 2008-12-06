local type = type
local pairs = pairs
local assert = assert

local table_concat = table.concat
local math_floor, math_modf = math.floor, math.modf

local util_merge = require("json.decode.util").merge
local util_IsArray = require("json.util").IsArray

module("json.encode.array")

local defaultOptions = {
	isArray = util_IsArray
}

default = nil
strict = nil

--[[
	Utility function to determine whether a table is an array or not.
	Criteria for it being an array:
		* ExternalIsArray returns true (or false directly reports not-array)
		* If the table has an 'n' value that is an integer >= 1 then it
		  is an array... may result in false positives (should check some values
		  before it)
		* It is a contiguous list of values with zero string-based keys
]]
function isArray(val, options)
	local externalIsArray = options and options.isArray

	if externalIsArray then
		local ret = externalIsArray(val)
		if ret == true or ret == false then
			return ret
		end
	end
	-- Use the 'n' element if it's a number
	if type(val.n) == 'number' and math_floor(val.n) == val.n and val.n >= 1 then
		return true
	end
	local len = #val
	for k,v in pairs(val) do
		if type(k) ~= 'number' then
			return false
		end
		local _, decim = math_modf(k)
		if not (decim == 0 and 1<=k) then
			return false
		end
		if k > len then -- Use Lua's length as absolute determiner
			return false
		end
	end

	return true
end

function getEncoder(options)
	options = options and util_merge({}, defaultOptions, options) or defaultOptions
	local function encodeArray(tab,  state)
		if not isArray(tab, options) then
			return false
		end
		-- Make sure this value hasn't been encoded yet
		state.check_unique(tab)
		local encode = state.encode
		local retVal = {}
		-- Encode the output from 1 to 'n' or length, mapped in JS to 0 to length - 1
		for i = 1, (tab.n or #tab) do
			retVal[#retVal + 1] = encode(tab[i], state)
		end
		return '[' .. table_concat(retVal, ',') .. ']'
	end
	return { table = encodeArray }
end
