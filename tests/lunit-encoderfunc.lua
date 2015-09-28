local json = require("json")
local lunit = require("lunit")
local math = require("math")
local testutil = require("testutil")
local unpack = require("table").unpack or unpack

local setmetatable = setmetatable

if not module then
    _ENV = lunit.module("lunit-encoderfunc", 'seeall')
else
    module("lunit-encoderfunc", lunit.testcase, package.seeall)
end

local function build_call(name, parameters)
	return json.util.buildCall(name, unpack(parameters, parameters.n))
end

function test_param_counts()
	local encoder = json.encode.getEncoder()
	assert(encoder(build_call('noparam', {})))
	assert(encoder(build_call('oneparam', {1})))
	assert(encoder(build_call('multiparam', {1,2})))
end

function test_output()
	local encoder = json.encode.getEncoder()
	assert_equal('b64("hello")', encoder(build_call('b64', {'hello'})))
	assert_equal('add(1,2)', encoder(build_call('add', {1,2})))
	assert_equal('dood([b64("hello"),add(1,2)])',
		encoder(build_call('dood', { {
			build_call('b64', {'hello'}),
			build_call('add', {1,2})
		} })))
end
