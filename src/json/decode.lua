--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")

local error = error

local object = require("json.decode.object")
local array = require("json.decode.array")

local util = require("json.decode.util")

local setmetatable, getmetatable = setmetatable, getmetatable
local assert = assert
local ipairs, pairs = ipairs, pairs
local string_char = string.char

local require = require
module("json.decode")

local VALUE, TABLE, ARRAY = util.VALUE, util.TABLE, util.ARRAY

local modulesToLoad = {
	"strings",
	"number",
	"calls",
	"others"
}
local loadedModules = {
}

local defaultOptions = {
	object = object.default,
	array  = array.default,
	unicodeWhitespace = true,
	initialObject = false
}

default = nil -- Let the buildCapture optimization take place

strict = {
	object = object.strict,
	array  = array.strict,
	unicodeWhitespace = true,
	initialObject = true
}

for _,name in ipairs(modulesToLoad) do
	local mod = require("json.decode." .. name)
	defaultOptions[name] = mod.default
	strict[name] = mod.strict
	loadedModules[name] = mod
end

local function buildDecoder(mode)
	mode = mode and util.merge({}, defaultOptions, mode) or defaultOptions
	local ignored = mode.unicodeWhitespace and util.unicode_ignored or util.ascii_ignored
	-- Store 'ignored' in the global options table
	mode.ignored = ignored

	local arrayCapture = array.buildCapture(mode.array, mode)
	local objectCapture = object.buildCapture(mode.object, mode)
	local valueCapture
	for name, mod in pairs(loadedModules) do
		local capture = mod.buildCapture(mode[name], mode)
		if capture then
			if valueCapture then
				valueCapture = valueCapture + capture
			else
				valueCapture = capture
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
		local ret, err = lpeg.match(grammar, data)
		assert(nil ~= ret, err or "Invalid JSON data")
		return ret
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
