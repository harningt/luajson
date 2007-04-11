local decode = require("json.decode")
local encode = require("json.encode")
local util = require("json.util")
module("json")
_M.decode = decode
_M.encode = encode
_M.util = util
