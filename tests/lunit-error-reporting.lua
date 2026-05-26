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

-- Helper: assert that decoding fails and the error contains the expected substring
local function assert_decode_error(input, expected_substr, options, msg)
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
	return err
end

-- Helper: assert error contains position info pattern (line:col)
local function assert_has_position(err)
	assert_not_nil(
		string_find(err, "%d+:%d+"),
		"Expected error to contain position info (line:col) but got: " .. err
	)
end

-- Test: unexpected character produces positioned error
function test_unexpected_character()
	local err = assert_decode_error("@", "unexpected character")
	assert_has_position(err)
end

-- Test: trailing garbage after valid JSON
function test_trailing_garbage()
	local err = assert_decode_error("true foo", "unexpected character")
	assert_has_position(err)
end

-- Test: unclosed array includes position info
function test_unclosed_array_position()
	local err = assert_decode_error("[1, 2", "Unclosed elements")
	assert_has_position(err)
end

-- Test: unclosed object includes position info
function test_unclosed_object_position()
	local err = assert_decode_error('{"a": 1', "Unclosed elements")
	assert_has_position(err)
end

-- Test: trailing comma in strict array gives helpful message
function test_trailing_comma_array_strict()
	local strict_no_trailing = {
		array = { trailingComma = false }
	}
	local err = assert_decode_error("[1, ]", "Trailing comma in array not permitted", strict_no_trailing)
	assert_has_position(err)
end

-- Test: trailing comma in strict object gives helpful message
function test_trailing_comma_object_strict()
	local strict_no_trailing = {
		object = { trailingComma = false }
	}
	local err = assert_decode_error('{"a": 1, }', "Trailing comma in object not permitted", strict_no_trailing)
	assert_has_position(err)
end

-- Test: denied NaN in strict mode
function test_denied_nan_strict()
	local err = assert_decode_error("NaN", "denied", { number = { nan = false } })
	assert_has_position(err)
end

-- Test: denied octal numbers
function test_denied_octal()
	local err = assert_decode_error("012", "Octal")
	assert_has_position(err)
end

-- Test: denied undefined in strict
function test_denied_undefined_strict()
	local err = assert_decode_error("undefined", "denied", json.decode.strict)
	assert_has_position(err)
end

-- Test: nothrow mode returns errors without throwing
function test_nothrow_error_reporting()
	local result, err = json.decode("[1, 2", { nothrow = true })
	assert_nil(result)
	assert_not_nil(err, "Expected error string from nothrow mode")
	err = tostring(err)
	assert_not_nil(string_find(err, "Unclosed elements", 1, true),
		"Expected 'Unclosed elements' in: " .. err)
end

-- Test: duplicate value detection includes position
function test_duplicate_value_position()
	-- "true false" has two values without comma/structure separation
	local err = assert_decode_error("[true false]", "Unexpected value")
	assert_has_position(err)
end

-- Test: multiline input reports correct line number
function test_multiline_position()
	local input = '{\n  "a": 1,\n  "b": 2,\n}'
	local strict_no_trailing = {
		object = { trailingComma = false }
	}
	local err = assert_decode_error(input, "Trailing comma", strict_no_trailing)
	-- Error should reference line 3 or 4 (where the trailing comma's effect is felt)
	assert_has_position(err)
end

-- Test: missing object value after colon
function test_missing_object_value()
	local err = assert_decode_error('{"a": }', "Expected value after ':'")
	assert_has_position(err)
end

-- Test: missing key before colon
function test_missing_key_before_colon()
	local err = assert_decode_error('{: 1}', "Expected key before ':'")
	assert_has_position(err)
end

-- Test: missing array value (consecutive commas)
function test_missing_array_value()
	local err = assert_decode_error('[1,, 2]', "Expected value in array")
	assert_has_position(err)
end
