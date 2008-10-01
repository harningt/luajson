local tostring = tostring

module("json.encode.number")

function encode(number, options)
	local str = tostring(number)
	if str == "nan" then return "NaN" end
	if str == "inf" then return "Infinity" end
	if str == "-inf" then return "-Infinity" end
	return str
end
