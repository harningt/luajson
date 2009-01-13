local string_char = string.char
local pairs = pairs

local util_merge = require("json.decode.util").merge
module("json.encode.strings")

local normalEncodingMap = {
	['\\'] = '\\\\',
	['"'] = '\\"',
	['\n'] = '\\n',
	['\t'] = '\\t',
	['\b'] = '\\b',
	['\v'] = '\\v',
	['\f'] = '\\f',
	['\r'] = '\\r',
	['/'] = '\\/'
}

local xEncodingMap = {}
for char, encoded in pairs(normalEncodingMap) do
	xEncodingMap[char] = encoded
end

-- Pre-encode the control characters to speed up encoding...
-- NOTE: UTF-8 may not work out right w/ JavaScript
-- JavaScript uses 2 bytes after a \u... yet UTF-8 is a
-- byte-stream encoding, not pairs of bytes (it does encode
-- some letters > 1 byte, but base case is 1)
for i = 0, 255 do
	local c = string_char(i)
	if c:match('[%c\128-\255]') and not normalEncodingMap[c] then
		normalEncodingMap[c] = ('\\u%.4X'):format(i)
		xEncodingMap[c] = ('\\x%.2X'):format(i)
	end
end

local defaultOptions = {
	preProcess = false,
	xEncode = false, -- Encode single-bytes as \xXX
	encodeSet = '\\"/%c%z',
	encodeSetAppend = nil -- Chars to append to the default set
}

default = nil
strict = nil

function getEncoder(options)
	options = options and util_merge({}, defaultOptions, options) or defaultOptions
	local stringPreprocess = options and options.preProcess
	local encodeSet = options.encodeSet
	if options.encodeSetAppend then
		encodeSet = encodeSet .. options.encodeSetAppend
	end
	local encodingMap = options.xEncode and xEncodingMap or normalEncodingMap
	local function encodeString(s, state)
		if stringPreprocess then
			s = stringPreprocess(s)
		end
		return '"' .. s:gsub('[' .. encodeSet .. ']', encodingMap) .. '"'
	end
	return {
		string = encodeString
	}
end
