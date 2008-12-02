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

function test_encoder_preprocess()
	local opts = {
		strings = {
			preProcess = function(str)
				return str:gsub("world", "land")
			end
		}
	}
	assert_equal([["Hello land"]], json.encode("Hello world", opts))
end

function test_post_process()
	local opts = {
		strings = {
			postProcess = function(value)
				-- Test that value processed is after escape handling
				assert_equal("test\n", value)
				return "arg"
			end
		}
	}
	local decode = json.decode.getDecoder(opts)
	local ret = decode([["test\n"]])
	-- Test that returned values are used
	assert_equal("arg", ret)
end

local utf16_matches = {
	{ '"\\u0000"', string.char(0x00) },
	{ '"\\u007F"', string.char(0x7F) },
	{ '"\\u00A2"', string.char(0xC2, 0xA2) },
	{ '"\\u20AC"', string.char(0xE2, 0x82, 0xAC) },
	{ '"\\uFFFF"', string.char(0xEF, 0xBF, 0xBF) }
}

function test_utf16_decode()
	for _, v in ipairs(utf16_matches) do
		-- Test that the default \u decoder outputs UTF8
		assert_equal(v[2], json.decode(v[1]))
	end
end
