--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")

local util = require("json.decode.util")
local strings = require("json.decode.strings")
local number = require("json.decode.number")

local jsonutil = require("json.util")

local ipairs = ipairs
local tonumber = tonumber
local unpack = unpack

module("json.decode.array")

-- Utility function to help manage slighly sparse arrays
local function processArray(array)
	array.n = #array
	for i,v in ipairs(array) do
		if v == jsonutil.null then
			array[i] = nil
		end
	end
	if #array == array.n then
		array.n = nil
	end
	if jsonutil.InitArray then
		array = jsonutil.InitArray(array) or array
	end
	return array
end

local defaultOptions = {
	trailingComma = true,
	depthLimiter = nil
}

default = nil -- Let the buildCapture optimization take place
strict = {
	trailingComma = false,
	depthLimiter = util.buildDepthLimit(20)
}

function buildCapture(options, global_options)
	local ignored = global_options.ignored
	-- arrayItem == element
	local arrayItem = lpeg.V(util.VALUE)
	local arrayElements = lpeg.Ct(arrayItem * (ignored * lpeg.P(',') * ignored * arrayItem)^0 + 0) / processArray

	options = options and util.merge({}, defaultOptions, options) or defaultOptions
	local incDepth, decDepth
	if options.depthLimiter then
		incDepth, decDepth = unpack(options.depthLimiter)
	end
	local capture = lpeg.P("[")
	if incDepth then
		capture = capture * lpeg.P(incDepth)
	end
	capture = capture * ignored
		* arrayElements * ignored
	if options.trailingComma then
		capture = capture * (lpeg.P(",") + 0) * ignored
	end
	capture = capture * lpeg.P("]")
	if decDepth then
		capture = capture * lpeg.P(decDepth)
	end
	return capture
end
