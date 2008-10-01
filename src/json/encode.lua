--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local type = type
local assert = assert
local getmetatable, setmetatable = getmetatable, setmetatable
local util = require("json.util")
local null = util.null

local require = require

local strings = require("json.encode.strings")
local number = require("json.encode.number")
local others = require("json.encode.others")

module("json.encode")

-- Load these modules after defining that json.encode exists
--  calls, object, and array need encodeValue and isEncodable
local calls = require("json.encode.calls")
local array = require("json.encode.array")
local object = require("json.encode.object")

local function encodeFunction(val, options)
	if val ~= null and calls.isCall(val, options) then
		return calls.encode(val, options)
	end
	return 'null'
end

local alreadyEncoded -- Table set at the beginning of every
	-- encoding operation to empty to detect recursiveness
local function encodeTable(tab, options)
	assert(not alreadyEncoded[tab], "Recursive table detected")
	alreadyEncoded[tab] = true
	-- Pass off encoding to appropriate encoder
	if calls.isCall(tab, options) then
		return calls.encode(tab, options)
	elseif array.isArray(tab, options) then
		return array.encode(tab, options)
	else
		return object.encode(tab, options)
	end
end

local encodeMapping = {
	['table'  ] = encodeTable,
	['number' ] = number.encode,
	['boolean'] = others.encodeBoolean,
	['function'] = encodeFunction,
	['string' ] = strings.encode,
	['nil'] = others.encodeNil -- For the case that nils are encountered count them as nulls
}
function isEncodable(item, options)
	local isNotEncodableFunction = type(item) == 'function' and (item ~= null and not calls.isCall(item, options))
	return encodeMapping[type(item)] and not isNotEncodableFunction
end

function encodeValue(item, options)
	local itemType = type(item)
	local encoder = encodeMapping[itemType]
	assert(encoder, "Invalid item to encode: " .. itemType)
	return encoder(item, options)
end

local defaultOptions = {
	strings = {
		preProcess = false
	},
	array = {
		isArray = util.IsArray
	}
}

function encode(data, options)
	options = options or defaultOptions
	alreadyEncoded = {}
	return encodeValue(data, options)
end

local mt = getmetatable(_M) or {}
mt.__call = function(self, ...)
	return encode(...)
end
setmetatable(_M, mt)
