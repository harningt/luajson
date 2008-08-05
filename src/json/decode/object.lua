--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")

local util = require("json.decode.util")
local strings = require("json.decode.strings")
local number = require("json.decode.number")

local tonumber = tonumber
local unpack = unpack
local print = print
local tostring = tostring
module("json.decode.object")
local ignored = util.ignored

local function initObject()
	return {}
end
local function applyObjectKey(tab, key, val)
	tab[key] = val
	return tab
end
local defaultOptions = {
	number = true,
	identifier = true,
	trailingComma = true
}

default = {}

strict = {
	number = false,
	identifier = false,
	trailingComma = false,
	depthLimiter = util.buildDepthLimit(20)
}

function buildCapture(options)
	options = options and util.merge({}, defaultOptions, options) or defaultOptions
	local incDepth, decDepth
	if options.depthLimiter then
		incDepth, decDepth = unpack(options.depthLimiter)
	end
	local key = strings.buildCapture()
	if options.identifier then
		key = key + lpeg.C(util.identifier)
	end
	if options.number then
		key = key + number.int / tonumber
	end
	local objectItem = (key * ignored * lpeg.P(":") * ignored * lpeg.V(util.VALUE)) / applyObjectKey
	local objectItems = objectItem * (ignored * lpeg.P(",") * ignored * objectItem)^0
	-- Build loading mechanisms
	objectItems = lpeg.Ca(lpeg.Cc(false) / initObject * (objectItems + 0))

	local capture = lpeg.P("{") * ignored
	if incDepth then
		capture = capture * lpeg.P(incDepth)
	end
	capture = capture * objectItems * ignored
	if options.trailingComma then
		capture = capture * (lpeg.P(",") + 0) * ignored
	end
	capture = capture * lpeg.P("}")
	if decDepth then
		capture = capture * lpeg.P(decDepth)
	end
	return capture
end
