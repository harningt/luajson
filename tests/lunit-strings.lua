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

function test_strict_quotes()
	local opts = {
		strings = {
			strict_quotes = true
		}
	}
	assert_error(function()
		local decoder = json.decode.getDecoder(opts)
		decoder("'hello'")
	end)
	opts.strings.strict_quotes = false
	assert_equal("hello", json.decode.getDecoder(opts)("'hello'"))
	-- Quote test
	assert_equal("he'\"llo'", json.decode.getDecoder(opts)("'he\\'\"llo\\''"))

end

local utf16_matches = {
	-- 1-byte
	{ '"\\u0000"', string.char(0x00) },
	{ '"\\u007F"', string.char(0x7F) },
	-- 2-byte
	{ '"\\u0080"', string.char(0xC2, 0x80) },
	{ '"\\u00A2"', string.char(0xC2, 0xA2) },
	{ '"\\u07FF"', string.char(0xDF, 0xBF) },
	-- 3-byte
	{ '"\\u0800"', string.char(0xE0, 0xA0, 0x80) },
	{ '"\\u20AC"', string.char(0xE2, 0x82, 0xAC) },
	{ '"\\uFFFF"', string.char(0xEF, 0xBF, 0xBF) }
}

function test_utf16_decode()
	for i, v in ipairs(utf16_matches) do
		-- Test that the default \u decoder outputs UTF8
		local num = tostring(i) .. ' '
		assert_equal(num .. v[2], num .. json.decode(v[1]))
	end
end
