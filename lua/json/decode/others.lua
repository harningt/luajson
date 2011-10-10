--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")
local jsonutil = require("json.util")
local util = require("json.decode.util")

local rawset = rawset

-- Container module for other JavaScript types (bool, null, undefined)
local is_52 = _VERSION == "Lua 5.2"
local _G = _G

if is_52 then
	_ENV = nil
end

-- For null and undefined, use the util.null value to preserve null-ness
local booleanCapture =
	lpeg.P("true") * lpeg.Cc(true)
	+ lpeg.P("false") * lpeg.Cc(false)

local nullCapture = lpeg.P("null")
local undefinedCapture = lpeg.P("undefined")

local defaultOptions = {
	allowUndefined = true,
	null = jsonutil.null,
	undefined = jsonutil.undefined,
	setObjectKey = rawset
}

local default = nil -- Let the buildCapture optimization take place
local simple = {
	null = false,     -- Mapped to nil
	undefined = false -- Mapped to nil
}
local strict = {
	allowUndefined = false
}

local function buildCapture(options)
	-- The 'or nil' clause allows false to map to a nil value since 'nil' cannot be merged
	options = options and jsonutil.merge({}, defaultOptions, options) or defaultOptions
	local valueCapture = (
		booleanCapture
		+ nullCapture * lpeg.Cc(options.null or nil)
	)
	if options.allowUndefined then
		valueCapture = valueCapture + undefinedCapture * lpeg.Cc(options.undefined or nil)
	end
	return valueCapture
end

local function load_types(options, global_options, grammar)
	local capture = buildCapture(options)
	util.append_grammar_item(grammar, "VALUE", capture)
end

local others = {
	default = default,
	simple = simple,
	strict = strict,
	load_types = load_types
}

if not is_52 then
	_G.json = _G.json or{}
	_G.json.decode = _G.json.decode or {}
	_G.json.decode.others = others
end

return others
