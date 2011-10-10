--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")

local util = require("json.decode.util")
local jsonutil = require("json.util")

local table_maxn = require("table").maxn

local is_52 = _VERSION == "Lua 5.2"
local unpack = unpack or require("table").unpack

local _G = _G

if is_52 then
	local pairs, type = pairs, type
	-- Replacement for maxn since it is removed
	table_maxn = function(t)
		local max = 0
		for k in pairs(t) do
			if type(k) == 'number' and k > max then
				max = k
			end
		end
		return max
	end
	_ENV = nil
end

-- Utility function to help manage slighly sparse arrays
local function processArray(array)
	local max_n = table_maxn(array)
	-- Only populate 'n' if it is necessary
	if #array ~= max_n then
		array.n = max_n
	end
	if jsonutil.InitArray then
		array = jsonutil.InitArray(array) or array
	end
	return array
end

local defaultOptions = {
	trailingComma = true
}

local modeOptions = {}

modeOptions.strict = {
	trailingComma = false
}

local function mergeOptions(options, mode)
	jsonutil.doOptionMerge(options, false, 'array', defaultOptions, mode and modeOptions[mode])
end

local function buildCapture(options, global_options, state)
	local ignored = global_options.ignored
	-- arrayItem == element
	local arrayItem = lpeg.V(util.types.VALUE)
	-- If match-time capture supported, use it to remove stack limit for JSON
	if lpeg.Cmt then
		arrayItem = lpeg.Cmt(lpeg.Cp(), function(str, i)
			-- Decode one value then return
			local END_MARKER = {}
			local pattern =
				-- Found empty segment
				#lpeg.P(']' * lpeg.Cc(END_MARKER) * lpeg.Cp())
				-- Found a value + captured, check for required , or ] + capture next pos
				+ state.VALUE_MATCH * #(lpeg.P(',') + lpeg.P(']')) * lpeg.Cp()
			local capture, i = pattern:match(str, i)
			if END_MARKER == capture then
				return i
			elseif (i == nil and capture == nil) then
				return false
			else
				return i, capture
			end
		end)
	end
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

local function register_types()
	util.register_type("ARRAY")
end

local function load_types(options, global_options, grammar, state)
	local capture = buildCapture(options, global_options, state)
	local array_id = util.types.ARRAY
	grammar[array_id] = capture
	util.append_grammar_item(grammar, "VALUE", lpeg.V(array_id))
end

local array = {
	mergeOptions = mergeOptions,
	register_types = register_types,
	load_types = load_types
}

if not is_52 then
	_G.json = _G.json or {}
	_G.json.decode = _G.json.decode or {}
	_G.json.decode.array = array
end

return array
