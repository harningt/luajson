local jsonencode = require("json.encode")

local type = type
local pairs = pairs
local assert = assert

local table_concat = table.concat
local math_floor, math_modf = math.floor, math.modf

module("json.encode.array")

function isArray(val, options)
	local externalIsArray = options and options.array and options.array.isArray
	local isEncodable = jsonencode.isEncodable

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
		assert(isEncodable(v, options), "Invalid array element type:" .. type(v))
		if k > len then -- Use Lua's length as absolute determiner
			return false
		end
	end

	return true
end

function encode(tab, options)
	local encodeValue = jsonencode.encodeValue
	local retVal = {}
	for i = 1,(tab.n or #tab) do
		retVal[#retVal + 1] = encodeValue(tab[i], options)
	end
	return '[' .. table_concat(retVal, ',') .. ']'
end
