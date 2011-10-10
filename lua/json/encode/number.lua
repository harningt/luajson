--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local tostring = tostring
local assert = assert
local util = require("json.util")
local huge = require("math").huge

local is_52 = _VERSION == "Lua 5.2"
local _G = _G

if is_52 then
	_ENV = nil
end

local defaultOptions = {
	nan = true,
	inf = true
}

local default = nil -- Let the buildCapture optimization take place
local strict = {
	nan = false,
	inf = false
}

local function encodeNumber(number, options)
	if number ~= number then
		assert(options.nan, "Invalid number: NaN not enabled")
		return "NaN"
	end
	if number == huge then
		assert(options.inf, "Invalid number: Infinity not enabled")
		return "Infinity"
	end
	if number == -huge then
		assert(options.inf, "Invalid number: Infinity not enabled")
		return "-Infinity"
	end
	return tostring(number)
end

local function getEncoder(options)
	options = options and util.merge({}, defaultOptions, options) or defaultOptions
	return {
		number = function(number, state)
			return encodeNumber(number, options)
		end
	}
end

local number = {
	default = default,
	strict = strict,
	getEncoder = getEncoder
}

if not is_52 then
	_G.json = _G.json or {}
	_G.json.encode = _G.json.encode or {}
	_G.json.encode.number = number
end

return number
