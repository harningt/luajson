local tostring = tostring

module("json.encode.others")

-- Shortcut that works
encodeBoolean = tostring

function encodeNil(value, options)
	return 'null'
end
