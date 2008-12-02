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

local rawset = rawset

local DecimalLpegVersion = util.DecimalLpegVersion

module("json.decode.object")

-- BEGIN LPEG < 0.9 SUPPORT
local initObject, applyObjectKey
if DecimalLpegVersion < 0.9 then
	function initObject()
		return {}
	end
	function applyObjectKey(tab, key, val)
		tab[key] = val
		return tab
	end
end
-- END LPEG < 0.9 SUPPORT

local defaultOptions = {
	number = true,
	identifier = true,
	trailingComma = true
}

default = nil -- Let the buildCapture optimization take place

strict = {
	number = false,
	identifier = false,
	trailingComma = false,
	depthLimiter = util.buildDepthLimit(20)
}

local function buildItemSequence(objectItem, ignored)
	return (objectItem * (ignored * lpeg.P(",") * ignored * objectItem)^0) + 0
end

function buildCapture(options, global_options)
	local ignored = global_options.ignored
	options = options and util.merge({}, defaultOptions, options) or defaultOptions
	local incDepth, decDepth
	if options.depthLimiter then
		incDepth, decDepth = unpack(options.depthLimiter)
	end
	local key = strings.buildCapture(global_options.strings, global_options)
	if options.identifier then
		key = key + lpeg.C(util.identifier)
	end
	if options.number then
		key = key + number.int / tonumber
	end
	local objectItems
	local objectItem = (key * ignored * lpeg.P(":") * ignored * lpeg.V(util.VALUE))
	-- BEGIN LPEG < 0.9 SUPPORT
	if DecimalLpegVersion < 0.9 then
		objectItems = buildItemSequence(objectItem / applyObjectKey, ignored)
		objectItems = lpeg.Ca(lpeg.Cc(false) / initObject * objectItems)
	-- END LPEG < 0.9 SUPPORT
	else
		objectItems = buildItemSequence(lpeg.Cg(objectItem), ignored)
		objectItems = lpeg.Cf(lpeg.Ct(0) * objectItems, rawset)
	end


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
