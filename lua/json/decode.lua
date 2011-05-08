--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")

local error = error

local object = require("json.decode.object")
local array = require("json.decode.array")

local merge = require("json.util").merge
local util = require("json.decode.util")

local setmetatable, getmetatable = setmetatable, getmetatable
local assert = assert
local ipairs, pairs = ipairs, pairs
local string_char = string.char

local require = require
module("json.decode")

local modulesToLoad = {
	"array",
	"object",
	"strings",
	"number",
	"calls",
	"others"
}
local loadedModules = {
}

local defaultOptions = {
	unicodeWhitespace = true,
	initialObject = false
}

default = nil -- Let the buildCapture optimization take place

strict = {
	unicodeWhitespace = true,
	initialObject = true
}

-- Register generic value type
util.register_type("VALUE")
for _,name in ipairs(modulesToLoad) do
	local mod = require("json.decode." .. name)
	defaultOptions[name] = mod.default
	strict[name] = mod.strict
	loadedModules[name] = mod
	-- Register types
	if mod.register_types then
		mod.register_types()
	end
end

local function buildDecoder(mode)
	mode = mode and merge({}, defaultOptions, mode) or defaultOptions
	local ignored = mode.unicodeWhitespace and util.unicode_ignored or util.ascii_ignored
	-- Store 'ignored' in the global options table
	mode.ignored = ignored

	local value_id = util.types.VALUE
	local value_type = lpeg.V(value_id)
	local object_type = lpeg.V(util.types.OBJECT)
	local array_type = lpeg.V(util.types.ARRAY)
	local grammar = {
		[1] = mode.initialObject and (ignored * (object_type + array_type)) or value_type
	}
	-- Additional state storage for modules
	local state = {}
	for _, name in pairs(modulesToLoad) do
		local mod = loadedModules[name]
		mod.load_types(mode[name], mode, grammar, state)
	end
	-- HOOK VALUE TYPE WITH WHITESPACE
	grammar[value_id] = ignored * grammar[value_id] * ignored
	local compiled_grammar = lpeg.P(grammar) * ignored
	-- If match-time-capture is supported, implement Cmt workaround for deep captures
	if lpeg.Cmt then
		if mode.initialObject then
			-- Patch the grammar and recompile for VALUE usage
			grammar[1] = value_type
			state.VALUE_MATCH = lpeg.P(grammar) * ignored
		else
			state.VALUE_MATCH = compiled_grammar
		end
	end
	-- Only add terminator for final grammar since it is expected that there is extra data
	-- when using VALUE_MATCH internally
	compiled_grammar = compiled_grammar * -1
	return function(data)
		local ret, err = lpeg.match(compiled_grammar, data)
		assert(nil ~= ret, err or "Invalid JSON data")
		return ret
	end
end

local strictDecoder, defaultDecoder = buildDecoder(strict), buildDecoder(default)
--[[
Options:
	number => number decode options
	string => string decode options
	array  => array decode options
	object => object decode options
	initialObject => whether or not to require the initial object to be a table/array
	allowUndefined => whether or not to allow undefined values
]]
function getDecoder(mode)
	mode = mode == true and strict or mode or default
	if mode == strict and strictDecoder then
		return strictDecoder
	elseif mode == default and defaultDecoder then
		return defaultDecoder
	end
	return buildDecoder(mode)
end

function decode(data, mode)
	local decoder = getDecoder(mode)
	return decoder(data)
end

local mt = getmetatable(_M) or {}
mt.__call = function(self, ...)
	return decode(...)
end
setmetatable(_M, mt)
