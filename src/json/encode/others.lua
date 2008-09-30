local tostring = tostring

module("json.encode.others")

function encodeNumber(number, options)
	local str = tostring(number)
	if str == "nan" then return "NaN" end
	if str == "inf" then return "Infinity" end
	if str == "-inf" then return "-Infinity" end
	return str
end

-- Shortcut that works
encodeBoolean = tostring

function encodeNil(value, options)
	return 'null'
end
