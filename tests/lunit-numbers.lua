local json = require("json")
local lunit = require("lunit")
local math = require("math")
local testutil = require("testutil")
local string = require("string")

local encode = json.encode
-- DECODE NOT 'local' due to requirement for testutil to access it
decode = json.decode.getDecoder(false)

local TEST_ENV
if not module then
    _ENV = lunit.module("lunit-numbers", 'seeall')
    TEST_ENV = _ENV
else
    module("lunit-numbers", lunit.testcase, package.seeall)
    TEST_ENV = _M
end

function setup()
	-- Ensure that the decoder is reset
	_G["decode"] = json.decode.getDecoder(false)
end

local function is_near(expect, received)
	local pctDiff
	if expect == received then
		pctDiff = 0
	else
		pctDiff = math.abs(1 - expect / received)
	end
	if pctDiff < 0.000001 then
		return true
	else
		return false, ("expected '%s' but was '%s' .. '%s'%% apart"):format(expect, received, pctDiff * 100)
	end
end
local function assert_near(expect, received)
	assert(is_near(expect, received))
end
local function test_simple(num)
	assert_near(num, decode(tostring(num)))
end
local function test_simple_w_encode(num)
	assert_near(num, decode(encode(num)))
end
local function test_scientific(num)
	assert_near(num, decode(string.format('%e', num)))
	assert_near(num, decode(string.format('%E', num)))
end
local function test_scientific_denied(num)
	local decode = json.decode.getDecoder({ number = { exp = false } })
	assert_error_match("Exponent-denied error did not match", "Exponents.*denied", function()
		decode(string.format('%e', num))
	end)
	assert_error_match("Exponent-denied error did not match", "Exponents.*denied", function()
		decode(string.format('%E', num))
	end)
end
local numbers = {
	0, 1, -1, math.pi, -math.pi
}
math.randomseed(0xDEADBEEF)
local pow = math.pow or load("return function(a, b) return a ^ b end")()
-- Add sequence of numbers at low/high end of value-set
for i = -300,300,60 do
	numbers[#numbers + 1] = math.random() * pow(10, i)
	numbers[#numbers + 1] = -math.random() * pow(10, i)
end

local function get_number_tester(f)
	return function ()
		for _, v in ipairs(numbers) do
			f(v)
		end
	end
end

local function test_fraction(num)
	assert_near(num, decode(string.format("%f", num)))
end
local function test_fraction_denied(num)
	local decode = json.decode.getDecoder({ number = { frac = false } })
	local formatted = string.format('%f', num)
	assert_error_match("Fraction-denied error did not match for " .. formatted, "Fractions.*denied", function()
		decode(formatted)
	end)
end
local function get_number_fraction_tester(f)
	return function ()
		for _, v in ipairs(numbers) do
			-- Fractional portion must be present
			local formatted = string.format("%f", v)
			-- San check that the formatted value is near the desired value
			if nil ~= formatted:find("%.") and is_near(v, tonumber(formatted)) then
				f(v)
			end
		end
	end
end

test_simple_numbers = get_number_tester(test_simple)
test_simple_numbers_w_encode = get_number_tester(test_simple_w_encode)
test_simple_numbers_scientific = get_number_tester(test_scientific)
test_simple_numbers_scientific_denied = get_number_tester(test_scientific_denied)
test_simple_numbers_fraction_only = get_number_fraction_tester(test_fraction)
test_simple_numbers_fraction_denied_only = get_number_fraction_tester(test_fraction_denied)

function test_infinite_nostrict()
	assert_equal(math.huge, decode("Infinity"))
	assert_equal(math.huge, decode("infinity"))
	assert_equal(-math.huge, decode("-Infinity"))
	assert_equal(-math.huge, decode("-infinity"))
end

function test_nan_nostrict()
	local value = decode("nan")
	assert_true(value ~= value)
	local value = decode("NaN")
	assert_true(value ~= value)
	assert_equal("NaN", encode(decode("NaN")))
end

function test_expression()
	assert_error(function()
		decode("1 + 2")
	end)
end

-- For strict tests, small concession must be made to allow non-array/objects as root
local strict = json.util.merge({}, json.decode.strict, {initialObject = false})
local strictDecoder = json.decode.getDecoder(strict)

local numberValue = {hex = true}

local hex = {number = numberValue}
local hexDecoder = json.decode.getDecoder(hex)

function test_hex()
	if decode == hexDecoder then -- MUST SKIP FAIL UNTIL BETTER METHOD SETUP
		return
	end
	assert_error(function()
		decode("0x20")
	end)
end

local hexNumbers = {
	0xDEADBEEF,
	0xCAFEBABE,
	0x00000000,
	0xFFFFFFFF,
	0xCE,
	0x01
}

function test_hex_only()
	_G["decode"] = hexDecoder
	for _, v in ipairs(hexNumbers) do
		assert_equal(v, decode(("0x%x"):format(v)))
		assert_equal(v, decode(("0X%X"):format(v)))
		assert_equal(v, decode(("0x%X"):format(v)))
		assert_equal(v, decode(("0X%x"):format(v)))
	end
end

local decimal_hexes = {
	"0x0.1",
	"0x.1",
	"0x0e+1",
	"0x0E-1"
}
function test_no_decimal_hex_only()
	for _, str in ipairs(decimal_hexes) do
		assert_error(function()
			hexDecoder(str)
		end)
	end
end

function test_nearly_scientific_hex_only()
	assert_equal(0x00E1, hexDecoder("0x00e1"))
end

local function buildStrictDecoder(f)
	return testutil.buildPatchedDecoder(f, strictDecoder)
end
local function buildFailedStrictDecoder(f)
	return testutil.buildFailedPatchedDecoder(f, strictDecoder)
end
-- SETUP CHECKS FOR SEQUENCE OF DECODERS
for k, v in pairs(TEST_ENV) do
	if k:match("^test_") and not k:match("_gen$") and not k:match("_only$") then
		if k:match("_nostrict") then
			TEST_ENV[k .. "_strict_gen"] = buildFailedStrictDecoder(v)
		else
			TEST_ENV[k .. "_strict_gen"] = buildStrictDecoder(v)
		end
		TEST_ENV[k .. "_hex_gen"] = testutil.buildPatchedDecoder(v, hexDecoder)
	end
end
