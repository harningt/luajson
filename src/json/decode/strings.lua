local lpeg = require("lpeg")
local util = require("json.decode.util")

local tonumber = tonumber
local string = string

module("json.decode.strings")
local knownReplacements = {
	n = "\n",
	r = "\r",
	f = "\f",
	t = "\t",
	b = "\b",
	z = "\z",
	['\\'] = "\\",
	['/'] = "/",
	['"'] = '"'
}
local function unicodeParse(code1, code2)
	code1, code2 = tonumber(code1, 16), tonumber(code2, 16)
	return string.char(code1, code2)
end

local doSimpleSub = lpeg.C(lpeg.S("rnfbt/\\z\"")) / knownReplacements
local doUniSub = (lpeg.P('u') * lpeg.C(util.hexpair) * lpeg.C(util.hexpair) + lpeg.P(false)) / unicodeParse
local doSub = doSimpleSub + doUniSub

defaultOptions = {
	stopParse = '"\\',
	escapeMatch = doSub + lpeg.C(1)
}
default = {}
strict = {
	stopParse = '"\\\r\n\f\b\t',
	escapeMatch = #lpeg.S('rnfbt/\\"u') * doSub
}
function buildMatch(options)
	options = options and util.merge({}, defaultOptions, options) or defaultOptions
	local stopParse = options.stopParse
	local escapeMatch = options.escapeMatch	
	return lpeg.P('"') * lpeg.Cs(((1 - lpeg.S(stopParse)) + (lpeg.P("\\") / "" * escapeMatch))^0) * lpeg.P('"')
end
function buildCapture(options)
	return buildMatch(options)
end
