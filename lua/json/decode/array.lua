--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")

local util = require("json.decode.util")
local jsonutil = require("json.util")

local ipairs = ipairs
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
	trailingComma = true
}

default = nil -- Let the buildCapture optimization take place
strict = {
	trailingComma = false
}

local function buildCapture(options, global_options)
	local ignored = global_options.ignored
	-- arrayItem == element
	local arrayItem = lpeg.V(util.types.VALUE)
	local arrayElements = lpeg.Ct(arrayItem * (ignored * lpeg.P(',') * ignored * arrayItem)^0 + 0) / processArray

	options = options and jsonutil.merge({}, defaultOptions, options) or defaultOptions
	local capture = lpeg.P("[")
	capture = capture * ignored
		* arrayElements * ignored
	if options.trailingComma then
		capture = capture * (lpeg.P(",") + 0) * ignored
	end
	capture = capture * lpeg.P("]")
	return capture
end

function register_types()
	util.register_type("ARRAY")
end

function load_types(options, global_options, grammar)
	local capture = buildCapture(options, global_options)
	local array_id = util.types.ARRAY
	grammar[array_id] = capture
	util.append_grammar_item(grammar, "VALUE", lpeg.V(array_id))
end
