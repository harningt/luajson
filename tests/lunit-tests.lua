local json = require("json")
local lunit = require("lunit")
local testutil = require("testutil")
local lpeg = require("lpeg")
-- DECODE NOT 'local' due to requirement for testutil to access it
decode = json.decode.getDecoder(false)

local TEST_ENV
if not module then
    _ENV = lunit.module("lunit-tests", 'seeall')
    TEST_ENV = _ENV
else
    module("lunit-tests", lunit.testcase, package.seeall)
    TEST_ENV = _M
end

function setup()
	_G["decode"] = json.decode.getDecoder(false)
end

function test_array_empty()
	local ret = assert_table(decode("[]"))
	assert_equal(0, #ret)
	assert_nil(next(ret))
end

function test_array_trailComma_nostrict()
	local ret = assert_table(decode("[true,]"))
	assert_equal(true, ret[1])
	assert_nil(next(ret, 1))
	assert_equal(1, #ret)
end

function test_array_innerComma()
	assert_error(function()
		decode("[true,,true]")
	end)
end

function test_preprocess()
	assert_equal('"Hello"', json.encode(1, {preProcess = function() return "Hello" end}))
	assert_equal('-1', json.encode(1, {preProcess = function(x) return -x end}))
	assert_equal('-Infinity', json.encode(1/0, {preProcess = function(x) return -x end}))
end

function test_additionalEscapes_only()
    -- Test that additionalEscapes is processed on its own - side-stepping normal processing
    assert_equal("Hello\\?", json.decode([["\S"]], { strings = { additionalEscapes = lpeg.C(lpeg.P("S")) / "Hello\\?" } }))
    -- Test that additionalEscapes overrides any builtin handling
    assert_equal("Hello\\?", json.decode([["\n"]], { strings = { additionalEscapes = lpeg.C(lpeg.P("n")) / "Hello\\?" } }))
end

local strictDecoder = json.decode.getDecoder(true)

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
	end
end
