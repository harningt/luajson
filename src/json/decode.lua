--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")
local jsonutil = require("json.util")

local error = error

local number = require("json.decode.number")
local strings = require("json.decode.strings")
local object = require("json.decode.object")
local array = require("json.decode.array")

local util = require("json.decode.util")

local setmetatable, getmetatable = setmetatable, getmetatable
local assert = assert
local print = print
local tonumber = tonumber
local ipairs, pairs = ipairs, pairs
local string = string
local tostring = tostring
local type = type

module("json.decode")

local nullValue = jsonutil.null
local undefinedValue = jsonutil.null

local ignored = util.ignored

local VALUE, TABLE, ARRAY = util.VALUE, util.TABLE, util.ARRAY

-- For null and undefined, use the util.null value to preserve null-ness
local booleanCapture =
	lpeg.P("true") * lpeg.Cc(true)
	+ lpeg.P("false") * lpeg.Cc(false)

local nullCapture = lpeg.P("null") * lpeg.Cc(nullValue)
local undefinedCapture = lpeg.P("undefined") * lpeg.Cc(undefinedValue)

default = {
	object = object.default,
	array  = array.default,
	number = number.default,
	string = strings.default,
	allowUndefined = true
}
strict = {
	object = object.strict,
	array  = array.strict,
	number = number.strict,
	string = strings.strict,
	initialObject = true
}

local function buildDecoder(mode)
	local arrayCapture = array.buildCapture(mode.array)
	local objectCapture = object.buildCapture(mode.object)
	local numberCapture = number.buildCapture(mode.number)
	local stringCapture = strings.buildCapture(mode.string)
	local valueCapture = (
		stringCapture
		+ numberCapture
		+ booleanCapture
		+ nullCapture
	)
	if mode.allowUndefined then
		valueCapture = valueCapture + undefinedCapture
	end
	if mode.functionCalls then
		for name, func in pairs(mode.functionCalls) do
			-- TODO: Potentially permit patterns for 'name' and potentially pass the name of the function called to the function itself
			if type(name) ~= 'string' and not lpeg.type(name) == 'pattern'then
				error("Invalid functionCalls name: " .. tostring(name) .. " not a string or LPEG pattern")
			end
			if type(func) ~= 'function' then
				error("Invalid functionCalls item: " .. name .. " not a function")
			end
			if type(name) == 'string' then
				valueCapture = valueCapture + lpeg.P((name .. "(") * lpeg.V(VALUE) / func * ")")
			else
				valueCapture = valueCapture + (name * "(" * lpeg.V(VALUE) / func * ")")
			end
		end
	end
	valueCapture = valueCapture + lpeg.V(TABLE) + lpeg.V(ARRAY)
	valueCapture = ignored * valueCapture * ignored
	local grammar = lpeg.P({
		[1] = mode.initialObject and (lpeg.V(TABLE) + lpeg.V(ARRAY)) or lpeg.V(VALUE),
		[VALUE] = valueCapture,
		[TABLE] = objectCapture,
		[ARRAY] = arrayCapture
	}) * ignored * -1
	return function(data)
		util.doInit()
		return assert(lpeg.match(grammar, data), "Invalid JSON data")
	end
end

local strictDecoder, defaultDecoder = buildDecoder(strict), buildDecoder(default)
--[[
Options:
	number => number decode options
	string => string decode options
	array  => array decode options
	object => object decode options
	initialObject => whether or not to require the initial object to be a table/array
	allowUndefined => whether or not to allow undefined values
]]
function getDecoder(mode)
	mode = mode == true and strict or mode or default
	if mode == strict and strictDecoder then
		return strictDecoder
	elseif mode == default and defaultDecoder then
		return defaultDecoder
	end
	return buildDecoder(mode)
end

function decode(data, mode)
	local decoder = getDecoder(mode)
	return decoder(data)
end

local mt = getmetatable(_M) or {}
mt.__call = function(self, ...)
	return decode(...)
end
setmetatable(_M, mt)
