local json = require("json")
local lunit = require("lunit")
local math = require("math")
local testutil = require("testutil")

local setmetatable = setmetatable

module("lunit-custom-encode", lunit.testcase, package.seeall)

function test_output()
	local encoder = json.encode.getEncoder()
	assert_equal('X', encoder(setmetatable({}, {__tojson=function() return "X" end})))
	assert_equal('"X"', encoder(setmetatable({}, {__tojson=function(value, encode, state) return encode("X") end})))
	assert_equal('[Z]', encoder({setmetatable({}, {__tojson=function(value, encode, state) return 'Z' end})}))
end
