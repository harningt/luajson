local json = require("json")
local lunit = require("lunit")

-- Test module for handling the simple decoding that behaves more like expected
if not module then
    _ENV = lunit.module("lunit-nothrow-decode", 'seeall')
else
    module("lunit-nothrow-decode", lunit.testcase, package.seeall)
end

function test_decode_nothrow_bad_data()
	assert_nil((json.decode('x', {nothrow = true})))
	assert_nil((json.decode('{x:x}', {nothrow = true})))
	assert_nil((json.decode('[x:x]', {nothrow = true})))
	assert_nil((json.decode('[1.fg]', {nothrow = true})))
	assert_nil((json.decode('["\\xzz"]', {nothrow = true})))
end

function test_decode_nothrow_ok_data()
	assert_not_nil((json.decode('"x"', {nothrow = true})))
	assert_not_nil((json.decode('{x:"x"}', {nothrow = true})))
	assert_not_nil((json.decode('["x"]', {nothrow = true})))
	assert_not_nil((json.decode('[1.0]', {nothrow = true})))
	assert_not_nil((json.decode('["\\u00FF"]', {nothrow = true})))
end

