local tostring = tostring

local assert = assert
local jsonutil = require("json.util")
local util_merge = require("json.decode.util").merge

module("json.encode.others")

-- Shortcut that works
encodeBoolean = tostring

local defaultOptions = {
	allowUndefined = true,
	null = jsonutil.null,
	undefined = jsonutil.null
}

default = nil -- Let the buildCapture optimization take place
strict = {
	allowUndefined = false
}

function encodeNil(value, options)
	options = options and util_merge({}, defaultOptions, options) or defaultOptions
	return 'null'
end

function encodeUndefined(value, options)
	options = options and util_merge({}, defaultOptions, options) or defaultOptions
	assert(options.allowUndefined, "Invalid value: Unsupported 'Undefines' parameter")
	return 'undefined'
end
