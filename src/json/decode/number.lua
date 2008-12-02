--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")
local tonumber = tonumber
local util = require("json.decode.util")

module("json.decode.number")

local simple_space = lpeg.S(" \t")

local digit  = lpeg.R("09")
local digits = digit^1

-- Deviation from JSON spec: Leading zeroes, inf number negatives w/ space
int = lpeg.P('-')^0 * simple_space^0 * digits
local int = int
local strictInt = (lpeg.P('-') + 0) * (lpeg.R("19") * digits + digit)

local frac = lpeg.P('.') * digits

local exp = lpeg.S("Ee") * (lpeg.S("-+") + 0) * digits

local nan = lpeg.S("Nn") * lpeg.S("Aa") * lpeg.S("Nn")
local inf = (lpeg.P('-') + 0) * lpeg.S("Ii") * lpeg.P("nfinity")
local hex = (lpeg.P("0x") + lpeg.P("0X")) * lpeg.R("09","AF","af")^1

local defaultOptions = {
	nan = true,
	inf = true,
	frac = true,
	exp = true,
	hex = false
}

default = nil -- Let the buildCapture optimization take place
strict = {
	nan = false,
	inf = false,
	strict = true
}
--[[
	Options: configuration options for number rules
		nan: match NaN
		inf: match Infinity
	 strict: for integer portion, only match [-]([0-9]|[1-9][0-9]*)
	   frac: match fraction portion (.0)
	    exp: match exponent portion  (e1)
	DEFAULT: nan, inf, frac, exp
		Must be set to false
]]
function buildMatch(options)
	options = options and util.merge({}, defaultOptions, options) or defaultOptions
	local ret
	if options.hex then
		ret = hex + (options.strict and strictInt or int)
	else
		ret = options.strict and strictInt or int
	end
	if options.frac then
		ret = ret * (frac + 0)
	end
	if options.exp then
		ret = ret * (exp + 0)
	end
	if options.nan then
		ret = ret + nan
	end
	if options.inf then
		ret = ret + inf
	end
	return ret
end

function buildCapture(options)
	return buildMatch(options) / tonumber
end
