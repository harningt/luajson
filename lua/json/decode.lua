--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")

local error = error
local pcall = pcall

local object = require("json.decode.object")
local array = require("json.decode.array")

local merge = require("json.util").merge
local util = require("json.decode.util")

local setmetatable, getmetatable = setmetatable, getmetatable
local assert = assert
local ipairs, pairs = ipairs, pairs
local string_char = require("string").char

local require = require

local is_52 = _VERSION == "Lua 5.2"
local _G = _G

if is_52 then
	_ENV = nil
end

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

local json_decode = {}

json_decode.default = {
	unicodeWhitespace = true,
	initialObject = false,
	nothrow = false
}

local modes_defined = { "default", "strict", "simple" }

json_decode.simple = {}

json_decode.strict = {
	unicodeWhitespace = true,
	initialObject = true,
	nothrow = false
}

-- Register generic value type
util.register_type("VALUE")
for _,name in ipairs(modulesToLoad) do
	local mod = require("json.decode." .. name)
	if mod.mergeOptions then
		for _, mode in pairs(modes_defined) do
			mod.mergeOptions(json_decode[mode], mode)
		end
	end
	loadedModules[name] = mod
	-- Register types
	if mod.register_types then
		mod.register_types()
	end
end

local function buildDecoder(mode)
	mode = mode and merge({}, json_decode.default, mode) or json_decode.default
	local ignored = mode.unicodeWhitespace and util.unicode_ignored or util.ascii_ignored
	-- Store 'ignored' in the global options table
	mode.ignored = ignored

	local value_id = util.types.VALUE
	local value_type = lpeg.V(value_id)
	local object_type = lpeg.V(util.types.OBJECT)
	local array_type = lpeg.V(util.types.ARRAY)
	local grammar = {
		[1] = mode.initialObject and (ignored * (object_type + array_type + util.expected("object", "array"))) or (value_type + util.expected("value"))
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
	-- Only add terminator & pos capture for final grammar since it is expected that there is extra data
	-- when using VALUE_MATCH internally
	compiled_grammar = compiled_grammar * lpeg.Cp() * (lpeg.P(-1) + util.unexpected())
	local decoder = function(data)
		local ret, next_index = lpeg.match(compiled_grammar, data)
		assert(nil ~= next_index, "Invalid JSON data")
		return ret
	end
	if mode.nothrow then
		return function(data)
			local status, rv = pcall(decoder, data)
			if status then
				return rv
			else
				return nil, rv
			end
		end
	end
	return decoder
end

-- Since 'default' is nil, we cannot take map it
local defaultDecoder = buildDecoder(json_decode.default)
local prebuilt_decoders = {}
for _, mode in pairs(modes_defined) do
	if json_decode[mode] ~= nil then
		prebuilt_decoders[json_decode[mode]] = buildDecoder(json_decode[mode])
	end
end

--[[
Options:
	number => number decode options
	string => string decode options
	array  => array decode options
	object => object decode options
	initialObject => whether or not to require the initial object to be a table/array
	allowUndefined => whether or not to allow undefined values
]]
local function getDecoder(mode)
	mode = mode == true and json_decode.strict or mode or json_decode.default
	local decoder = mode == nil and defaultDecoder or prebuilt_decoders[mode]
	if decoder then
		return decoder
	end
	return buildDecoder(mode)
end

local function decode(data, mode)
	local decoder = getDecoder(mode)
	return decoder(data)
end

local mt = {}
mt.__call = function(self, ...)
	return decode(...)
end

json_decode.getDecoder = getDecoder
json_decode.decode = decode
setmetatable(json_decode, mt)
if not is_52 then
	_G.json= _G.json or {}
	_G.json.decode = merge(json_decode, _G.json.decode)
end

return json_decode
