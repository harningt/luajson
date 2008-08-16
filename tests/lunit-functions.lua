package.path = package.path .. ';?/init.lua;../src/?.lua;../src/?/init.lua'

local json = require("json")
local lunit = require("lunit")
local math = math
local testutil = require("testutil")

local encode = json.encode
-- DECODE NOT 'local' due to requirement for testutil to access it
decode = json.decode.getDecoder(false)

module("lunit-functions", lunit.testcase, package.seeall)

function setup()
	-- Ensure that the decoder is reset
	_G["decode"] = json.decode.getDecoder(false)
end

local values = {
	0,
	1,
	0.2,
	"Hello",
	true,
	{hi=true},
	{1,2}
}

function test_identity()
	local function testFunction(...)
		return (...)
	end
	local strict = json.decode.util.merge({}, json.decode.default, {
		functionCalls = {
			call = testFunction
		}
	})
	local decode = json.decode.getDecoder(strict)
	for i, v in ipairs(values) do
		local str = "call(" .. encode(v) .. ")"
		local decoded = decode(str)
		if type(decoded) == 'table' then
			for k2, v2 in pairs(v) do
				assert_equal(v2, decoded[k2])
				decoded[k2] = nil
			end
			assert_nil(next(decoded))
		else
			assert_equal(v, decoded)
		end
	end
end