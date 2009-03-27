--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
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

local defaultOptions = {
	allowUndefined = true,
	null = jsonutil.null,
	undefined = jsonutil.undefined
}

default = nil -- Let the buildCapture optimization take place
strict = {
	allowUndefined = false
}

local function buildCapture(options)
	options = options and jsonutil.merge({}, defaultOptions, options) or defaultOptions
	local valueCapture = (
		booleanCapture
		+ nullCapture * lpeg.Cc(options.null)
	)
	if options.allowUndefined then
		valueCapture = valueCapture + undefinedCapture * lpeg.Cc(options.undefined)
	end
	return valueCapture
end

function load_types(options, global_options, grammar)
	local capture = buildCapture(options)
	util.append_grammar_item(grammar, "VALUE", capture)
end
