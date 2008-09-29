--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
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
-- NOTE: Technically incorrect, correct one will be incorporated eventually
local function nullDecodeUnicode(code1, code2)
	code1, code2 = tonumber(code1, 16), tonumber(code2, 16)
	return string.char(code1, code2)
end

local doSimpleSub = lpeg.C(lpeg.S("rnfbt/\\z\"")) / knownReplacements
local doUniSub = (lpeg.P('u') * lpeg.C(util.hexpair) * lpeg.C(util.hexpair) + lpeg.P(false))
local doSub = doSimpleSub

defaultOptions = {
	badChars = '"',
	additionalEscapes = lpeg.C(1), -- any escape char not handled will be dumped as-is
	escapeCheck = false, -- no check on valid characters
	decodeUnicode = nullDecodeUnicode,
	postProcess = false  -- post-processing for strings after decoding, such as for UTF8 handling
}
default = {}
strict = {
	badChars = '"\r\n\f\b\t',
	additionalEscapes = false, -- no additional escapes
	escapeCheck = #lpeg.S('rnfbt/\\"u') --only these chars are allowed to be escaped
}
function buildMatch(options)
	options = options and util.merge({}, defaultOptions, options) or defaultOptions
	local badChars = options.badChars
	local escapeMatch = doSub
	escapeMatch = escapeMatch + doUniSub / options.decodeUnicode
	if options.additionalEscapes then
		escapeMatch = escapeMatch + options.additionalEscapes
	end
	if options.escapeCheck then
		escapeMatch = options.escapeCheck * escapeMatch
	end
	local captureString = lpeg.P('"') * lpeg.Cs(((1 - lpeg.S("\\" .. badChars)) + (lpeg.P("\\") / "" * escapeMatch))^0)
	if options.postProcess then
		captureString = captureString / options.postProcess
	end
	captureString = captureString * lpeg.P('"')
	return captureString
end
function buildCapture(options)
	return buildMatch(options)
end
