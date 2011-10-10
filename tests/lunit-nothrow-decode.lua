local json = require("json")
local lunit = require("lunit")

-- Test module for handling the simple decoding that behaves more like expected
module("lunit-nothrow-decode", lunit.testcase, package.seeall)

function test_decode_nothrow_bad_data()
	assert_nil((json.decode('x', {nothrow = true})))
	assert_nil((json.decode('{x:x}', {nothrow = true})))
	assert_nil((json.decode('[x:x]', {nothrow = true})))
	assert_nil((json.decode('[1.fg]', {nothrow = true})))
	assert_nil((json.decode('["\\xzz"]', {nothrow = true})))
end

