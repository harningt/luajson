--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local decode = require("json.decode")
local encode = require("json.encode")
local util = require("json.util")

module("json")
_VERSION = "1.1.2"
_DESCRIPTION = "LuaJSON : customizable JSON decoder/encoder"
_COPYRIGHT = "Copyright (c) 2007-2012 Thomas Harning Jr. <harningt@gmail.com>"
_M.decode = decode
_M.encode = encode
_M.util = util
