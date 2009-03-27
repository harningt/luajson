--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")
local tonumber = tonumber
local merge = require("json.util").merge
local util = require("json.decode.util")

module("json.decode.number")

local digit  = lpeg.R("09")
local digits = digit^1

int = (lpeg.P('-') + 0) * (lpeg.R("19") * digits + digit)
local int = int

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
	inf = false
}
--[[
	Options: configuration options for number rules
		nan: match NaN
		inf: match Infinity
	   frac: match fraction portion (.0)
	    exp: match exponent portion  (e1)
	DEFAULT: nan, inf, frac, exp
]]
local function buildMatch(options)
	options = options and merge({}, defaultOptions, options) or defaultOptions
	local ret = int
	if options.frac then
		ret = ret * (frac + 0)
	end
	if options.exp then
		ret = ret * (exp + 0)
	end
	if options.hex then
		ret = hex + ret
	end
	if options.nan then
		ret = ret + nan
	end
	if options.inf then
		ret = ret + inf
	end
	return ret
end

local function buildCapture(options)
	return buildMatch(options) / tonumber
end

function register_types()
	util.register_type("INTEGER")
end

function load_types(options, global_options, grammar)
	local integer_id = util.types.INTEGER
	local capture = buildCapture(options)
	util.append_grammar_item(grammar, "VALUE", capture)
	grammar[integer_id] = int / tonumber
end
