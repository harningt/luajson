--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")
local util = require("json.decode.util")

local tonumber = tonumber
local string = string
local string_char = string.char
local floor = math.floor
local table_concat = table.concat

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

-- according to the table at http://da.wikipedia.org/wiki/UTF-8
local function utf8DecodeUnicode(code1, code2)
	code1, code2 = tonumber(code1, 16), tonumber(code2, 16)
	if code1 == 0 and code2 < 0x80 then
		return string_char(code2)
	end
	if code1 < 0x08 then
		return string_char(
			0xC0 + code1 * 4 + floor(code2 / 64),
			0x80 + code2 % 64)
	end
	return string_char(
		0xE0 + floor(code1 / 16),
		0x80 + (code1 % 16) * 4 + floor(code2 / 64),
		0x80 + code2 % 64)
end

local doSimpleSub = lpeg.C(lpeg.S("rnfbt/\\z\"")) / knownReplacements
local doUniSub = (lpeg.P('u') * lpeg.C(util.hexpair) * lpeg.C(util.hexpair) + lpeg.P(false))
local doSub = doSimpleSub

local defaultOptions = {
	badChars = '',
	additionalEscapes = lpeg.C(1), -- any escape char not handled will be dumped as-is
	escapeCheck = false, -- no check on valid characters
	decodeUnicode = utf8DecodeUnicode,
	strict_quotes = false,
	postProcess = false  -- post-processing for strings after decoding, such as for UTF8 handling
}

default = nil -- Let the buildCapture optimization take place

strict = {
	badChars = '\r\n\f\b\t',
	additionalEscapes = false, -- no additional escapes
	escapeCheck = #lpeg.S('rnfbt/\\"\'u'), --only these chars are allowed to be escaped
	strict_quotes = true
}

local function buildCaptureString(quote, badChars, escapeMatch, postProcess)
	local captureString = lpeg.P(quote) * lpeg.Cs(((1 - lpeg.S("\\" .. badChars .. quote)) + (lpeg.P("\\") / "" * escapeMatch))^0)
	if postProcess then
		captureString = captureString / postProcess
	end
	captureString = captureString * lpeg.P(quote)
	return captureString
end

function buildMatch(options)
	options = options and util.merge({}, defaultOptions, options) or defaultOptions
	local quotes = { '"' }
	if not options.strict_quotes then
		quotes[#quotes + 1] = "'"
	end
	local badChars = options.badChars
	local escapeMatch = doSub
	escapeMatch = escapeMatch + doUniSub / options.decodeUnicode
	if options.additionalEscapes then
		escapeMatch = escapeMatch + options.additionalEscapes
	end
	if options.escapeCheck then
		escapeMatch = options.escapeCheck * escapeMatch
	end
	local captureString
	for i = 1, #quotes do
		local cap = buildCaptureString(quotes[i], badChars, escapeMatch, options.postProcess)
		if captureString == nil then
			captureString = cap
		else
			captureString = captureString + cap
		end
	end
	return captureString
end
function buildCapture(options)
	return buildMatch(options)
end
