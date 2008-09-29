--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local tostring, string, type = tostring, string, type
local tonumber, math, assert = tonumber, math, assert
local table, pairs, ipairs = table, pairs, ipairs
local getmetatable, setmetatable = getmetatable, setmetatable
local select = select
local print = print
local error = error
local util = require("json.util")
local null = util.null
local externalIsArray = IsArray or util.IsArray -- Support for the special IsArray external function...

module("json.encode")

local encodingMap = {
	['\\'] = '\\\\',
	['"'] = '\\"',
	['\n'] = '\\n',
	['\t'] = '\\t',
	['\b'] = '\\b',
	['\f'] = '\\f',
	['\r'] = '\\r',
	['/'] = '\\/'
}

-- Pre-encode the control characters to speed up encoding...
-- NOTE: UTF-8 may not work out right w/ JavaScript
-- JavaScript uses 2 bytes after a \u... yet UTF-8 is a
-- byte-stream encoding, not pairs of bytes (it does encode
-- some letters > 1 byte, but base case is 1)
for i = 1, 255 do
	local c = string.char(i)
	if c:match('%c') and not encodingMap[c] then
		encodingMap[c] = string.format('\\u%.4X', i)
	end
end
local stringPreprocess = nil
local function encodeString(s)
	if stringPreprocess then
		s = stringPreprocess(s)
	end
	return '"' .. string.gsub(s, '[\\"/%c%z]', encodingMap) .. '"'
end

local function isArray(val)
	if externalIsArray then
		local ret = externalIsArray(val)
		if ret == true or ret == false then
			return ret
		end
	end
	-- Use the 'n' element if it's a number
	if type(val.n) == 'number' and math.floor(val.n) == val.n and val.n >= 1 then
		return true
	end
	local len = #val
	for k,v in pairs(val) do
		if type(k) == 'number' and select(2, math.modf(k)) == 0 and 1<=k then
			assert(isEncodable(v), "Invalid array element type:" .. type(v))
			if k > len then -- Use Lua's length as absolute determiner
				return false
			end
		else -- Not an integral key...
			return false
		end
	end

	return true
end

local function tonull(val)
	if val == null then
		return 'null'
	end
end

-- Forward reference for encodeValue function
local encodeValue
local alreadyEncoded -- Table set at the beginning of every
	-- encoding operation to empty to detect recursiveness
local function encodeTable(tab)
	if alreadyEncoded[tab] then
		error("Recursive table detected")
	end
	alreadyEncoded[tab] = true
	local retVal = {}
	-- Try for array
	if isArray(tab) then
		for i = 1,(tab.n or #tab) do
			retVal[#retVal + 1] = encodeValue(tab[i])
		end
		return '[' .. table.concat(retVal, ',') .. ']'
	else
		-- Is table
		for i, v in pairs(tab) do
			local ti = type(i)
			if ti == 'string' or ti == 'number' or ti == 'boolean' then
				i = encodeString(tostring(i))
			else
				error("Invalid object index type: " .. ti)
			end
			retVal[#retVal + 1] = i .. ':' .. encodeValue(v)
		end
		return '{' .. table.concat(retVal, ',') .. '}'
	end
end

local function encodeNumber(number)
	local str = tostring(number)
	if str == "nan" then return "NaN" end
	if str == "inf" then return "Infinity" end
	if str == "-inf" then return "-Infinity" end
	return str
end

local allowAllNumbers = true

local encodeMapping = {
	['table'  ] = encodeTable,
	['number' ] = allowAllNumbers and encodeNumber or tostring,
	['boolean'] = tostring,
	['function'] = tonull,
	['string' ] = encodeString,
	['nil'] = function() return 'null' end -- For the case that nils are encountered count them as nulls
}
function isEncodable(item)
	return encodeMapping[type(item)] and not (type(item) == 'function' and item ~= null)
end

--[[local ]] function encodeValue(item)
	local encoder = encodeMapping[type(item)]
	if not encoder then
		error("Invalid item to encode: " .. type(item))
	end
	return encoder(item)
end

local defaultOptions = {
	strings = {
		preProcess = false
	}
}

function encode(data, options)
	options = options or defaultOptions
	stringPreprocess = options and options.strings and options.strings.preProcess
	alreadyEncoded = {}
	return encodeValue(data)
end

local mt = getmetatable(_M) or {}
mt.__call = function(self, ...)
	return encode(...)
end
setmetatable(_M, mt)
