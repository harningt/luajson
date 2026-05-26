local json = require("json")
local lunit = require("lunit")
local testutil = require("testutil")

local pcall = pcall
local tostring = tostring
local string_find = require("string").find

if not module then
    _ENV = lunit.module("lunit-error-reporting", 'seeall')
else
    module("lunit-error-reporting", lunit.testcase, package.seeall)
end

-- Helper: assert that decoding fails and the error contains the expected substring and position
local function assert_decode_error(input, expected_substr, options, expected_line, expected_col, msg)
	local ok, err = pcall(json.decode, input, options)
	assert_false(ok, (msg or "Expected decode to fail for: ") .. input)
	assert_not_nil(err, "Expected error message for: " .. input)
	err = tostring(err)
	if expected_substr then
		assert_not_nil(
			string_find(err, expected_substr, 1, true),
			"Expected error to contain '" .. expected_substr .. "' but got: " .. err
		)
	end
	if expected_line and expected_col then
		local pos_pattern = " " .. expected_line .. ":" .. expected_col .. " "
		assert_not_nil(
			string_find(err, pos_pattern, 1, true),
			"Expected error position '" .. pos_pattern .. "' but got: " .. err
		)
	end
	return err
end

-- Test: unexpected character produces positioned error
function test_unexpected_character()
	assert_decode_error("@", "unexpected character", nil, 1, 1)
end

-- Test: trailing garbage after valid JSON
function test_trailing_garbage()
	assert_decode_error("true foo", "unexpected character", nil, 1, 6)
end

-- Test: unclosed array includes position info
function test_unclosed_array_position()
	assert_decode_error("[1, 2", "Unclosed elements", nil, 1, 5)
end

-- Test: unclosed object includes position info
function test_unclosed_object_position()
	assert_decode_error('{"a": 1', "Unclosed elements", nil, 1, 7)
end

-- Test: trailing comma in strict array gives helpful message
function test_trailing_comma_array_strict()
	local strict_no_trailing = {
		array = { trailingComma = false }
	}
	assert_decode_error("[1, ]", "Trailing comma in array not permitted", strict_no_trailing, 1, 5)
end

-- Test: trailing comma in strict object gives helpful message
function test_trailing_comma_object_strict()
	local strict_no_trailing = {
		object = { trailingComma = false }
	}
	assert_decode_error('{"a": 1, }', "Trailing comma in object not permitted", strict_no_trailing, 1, 10)
end

-- Test: denied NaN in strict mode
function test_denied_nan_strict()
	assert_decode_error("NaN", "denied", { number = { nan = false } }, 1, 1)
end

-- Test: denied octal numbers
function test_denied_octal()
	assert_decode_error("012", "Octal", nil, 1, 1)
end

-- Test: denied undefined in strict
function test_denied_undefined_strict()
	assert_decode_error("undefined", "denied", json.decode.strict, 1, 1)
end

-- Test: nothrow mode returns errors without throwing
function test_nothrow_error_reporting()
	local result, err = json.decode("[1, 2", { nothrow = true })
	assert_nil(result)
	assert_not_nil(err, "Expected error string from nothrow mode")
	err = tostring(err)
	assert_not_nil(string_find(err, "Unclosed elements", 1, true),
		"Expected 'Unclosed elements' in: " .. err)
	assert_not_nil(string_find(err, " 1:5 ", 1, true),
		"Expected position ' 1:5 ' in: " .. err)
end

-- Test: duplicate value detection includes position
function test_duplicate_value_position()
	-- "true false" has two values without comma/structure separation
	assert_decode_error("[true false]", "Unexpected value", nil, 1, 7)
end

-- Test: multiline input reports correct line number
function test_multiline_position()
	local input = '{\n  "a": 1,\n  "b": 2,\n}'
	local strict_no_trailing = {
		object = { trailingComma = false }
	}
	assert_decode_error(input, "Trailing comma", strict_no_trailing, 4, 1)
end

-- Test: missing object value after colon
function test_missing_object_value()
	assert_decode_error('{"a": }', "Expected value after ':'", nil, 1, 7)
end

-- Test: missing key before colon
function test_missing_key_before_colon()
	assert_decode_error('{: 1}', "Expected key before ':'", nil, 1, 2)
end

-- Test: missing array value (consecutive commas)
function test_missing_array_value()
	assert_decode_error('[1,, 2]', "Expected value in array", nil, 1, 4)
end

-- Test: expected utility helper with multiple arguments
function test_util_expected_helper()
	local util = require("json.decode.util")
	local pattern = util.expected("foo", "bar")
	local ok, err = pcall(function()
		pattern:match("data")
	end)
	assert_false(ok)
	assert_not_nil(string_find(tostring(err), "expected one of 'foo','bar'", 1, true))
end

-- Test: expected utility helper with single argument
function test_util_expected_single_helper()
	local util = require("json.decode.util")
	local pattern = util.expected("baz")
	local ok, err = pcall(function()
		pattern:match("data")
	end)
	assert_false(ok)
	assert_not_nil(string_find(tostring(err), "expected 'baz'", 1, true))
end
