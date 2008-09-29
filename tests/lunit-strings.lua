local json = require("json")
local lunit = require("lunit")
local testutil = require("testutil")

local encode = json.encode
-- DECODE NOT 'local' due to requirement for testutil to access it
decode = json.decode.getDecoder(false)

module("lunit-strings", lunit.testcase, package.seeall)

function setup()
	-- Ensure that the decoder is reset
	_G["decode"] = json.decode.getDecoder(false)
end

function test_post_process()
	local opts = json.decode.util.merge({}, json.decode.default, {
		strings = {
			postProcess = function(value)
				-- Test that value processed is after escape handling
				assert_equal("test\n", value)
				return "arg"
			end
		}
	})
	local decode = json.decode.getDecoder(opts)
	local ret = decode([["test\n"]])
	-- Test that returned values are used
	assert_equal("arg", ret)
end
