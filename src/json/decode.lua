--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")
local jsonutil = require("json.util")

local error = error

local number = require("json.decode.number")
local strings = require("json.decode.strings")
local object = require("json.decode.object")
local array = require("json.decode.array")

local util = require("json.decode.util")

local setmetatable, getmetatable = setmetatable, getmetatable
local assert = assert
local print = print
local tonumber = tonumber
local ipairs = ipairs
local string = string
local tostring = tostring

module("json.decode")
local alpha = lpeg.R("AZ","az")

local nullValue = jsonutil.null
local undefinedValue = jsonutil.null

local identifier = util.identifier

local ignored = util.ignored

local VALUE, TABLE, ARRAY = util.VALUE, util.TABLE, util.ARRAY


local captureString = strings.buildCapture(strings.default)
local strictCaptureString = strings.buildCapture(strings.strict)

-- For null and undefined, use the util.null value to preserve null-ness
local booleanCapture =
	lpeg.P("true") * lpeg.Cc(true)
	+ lpeg.P("false") * lpeg.Cc(false)
local tableArrayCapture = lpeg.V(TABLE) + lpeg.V(ARRAY)

local nullCapture = lpeg.P("null") * lpeg.Cc(nullValue)
local undefinedCapture = lpeg.P("undefined") * lpeg.Cc(undefinedValue)

local function buildValueCapture(nullValue, undefinedValue, allowUndefined, allowNaN, strictMinusSpace, strictString)
	local ret = (
		(strictString and strictCaptureString or captureString)
		+ number.buildCapture({nan = allowNaN, inf = allowNaN, strict = strictMinusSpace})
		+ booleanCapture
		+ nullCapture
	)
	if allowUndefined then
		ret = ret + undefinedCapture
	end
	ret = ret + tableArrayCapture
	ret = ignored * ret * ignored
	return ret
end

local valueCapture = buildValueCapture(nullValue, nullValue, true, true, false, false)

-- Current deviation to permit round-tripping
--  Allow inf/nan
local strictValueCapture = buildValueCapture(nullValue, nil, false, true, true, true)

local strictLimiter = util.buildDepthLimit(20)

local tableCapture = object.buildCapture()
local strictTableCapture = object.buildCapture({
	number = false,
	identifier = false,
	trailingComma = false,
	depthLimiter = strictLimiter
})

local arrayCapture = array.buildCapture()
local strictArrayCapture = array.buildCapture({
	trailingComma = false,
	depthLimiter = strictLimiter
})

local function er(_, i) error("Invalid JSON data at: " .. tostring(i)) end

-- Deviation: allow for trailing comma, allow for "undefined" to be a value...
local grammar = lpeg.P({
	[1] = lpeg.V(VALUE),
	[VALUE] = valueCapture,
	[TABLE] = tableCapture,
	[ARRAY] = arrayCapture
}) * ignored * (-1 + lpeg.P(er))

local strictGrammar = lpeg.P({
	[1] = lpeg.V(TABLE) + lpeg.V(ARRAY), -- Initial value MUST be an object or array
	[VALUE] = strictValueCapture,
	[TABLE] = strictTableCapture,
	[ARRAY] = strictArrayCapture
}) * ignored * (-1 + lpeg.P(er))

--NOTE: Certificate was trimmed down to make it easier to read....

function decode(data, strict)
	util.doInit()
	return (assert(lpeg.match(not strict and grammar or strictGrammar, data), "Invalid JSON data"))
end

local mt = getmetatable(_M) or {}
mt.__call = function(self, ...)
	return decode(...)
end
setmetatable(_M, mt)
