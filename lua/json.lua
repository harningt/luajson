--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local decode = require("json.decode")
local encode = require("json.encode")
local util = require("json.util")

local is_52 = _VERSION == "Lua 5.2"

local _G = _G

if is_52 then
	_ENV = nil
end

local json = {
	decode = decode,
	encode = encode,
	util = util
}

if not is_52 then
	_G.json = json
end
return json
