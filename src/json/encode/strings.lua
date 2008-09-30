local string_char = string.char

module("json.encode.strings")

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
	local c = string_char(i)
	if c:match('%c') and not encodingMap[c] then
		encodingMap[c] = ('\\u%.4X'):format(i)
	end
end

function encode(s, options)
	local stringPreprocess = options and options.strings and options.strings.preProcess
	if stringPreprocess then
		s = stringPreprocess(s)
	end
	return '"' .. s:gsub('[\\"/%c%z]', encodingMap) .. '"'
end
