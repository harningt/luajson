local lpeg = require("lpeg")
local jsonutil = require("json.util")
local util = require("json.decode.util")

-- Container module for other JavaScript types (bool, null, undefined)
module("json.decode.others")

-- For null and undefined, use the util.null value to preserve null-ness
local booleanCapture =
	lpeg.P("true") * lpeg.Cc(true)
	+ lpeg.P("false") * lpeg.Cc(false)

local nullCapture = lpeg.P("null")
local undefinedCapture = lpeg.P("undefined")


default = {
	allowUndefined = true,
	null = jsonutil.null,
	undefined = jsonutil.null
}

strict = util.merge({}, default, {
	allowUndefined = false
})

function buildCapture(options)
	local valueCapture = (
		booleanCapture
		+ nullCapture * lpeg.Cc(options.null)
	)
	if options.allowUndefined then
		valueCapture = valueCapture + undefinedCapture * lpeg.Cc(options.undefined)
	end
	return valueCapture
end
