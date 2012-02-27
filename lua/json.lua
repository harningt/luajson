--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local decode = require("json.decode")
local encode = require("json.encode")
local util = require("json.util")

local _G = _G

_ENV = nil

local json = {
	decode = decode,
	encode = encode,
	util = util
}

_G.json = json

return json
