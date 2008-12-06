local json = require("json")
local lunit = require("lunit")
local math = math
local testutil = require("testutil")

local setmetatable = setmetatable

module("lunit-encoderfunc", lunit.testcase, package.seeall)

local function build_call(name, parameters)
	return setmetatable({}, {
		callData = {
			name = name,
			parameters = parameters
		}
	})
end

function test_param_counts()
	local encoder = json.encode.getEncoder({
		calls = {
			multiArgument = false
		}
	})
	assert_error(function()
		assert(encoder(build_call('noparam', {})))
	end)
	assert_error(function()
		assert(encoder(build_call('multiparam', {1,2})))
	end)
	local encoder = json.encode.getEncoder({
		calls = {
			multiArgument = true
		}
	})
	assert(encoder(build_call('noparam', {})))
	assert(encoder(build_call('multiparam', {1,2})))
end

function test_output()
	local encoder = json.encode.getEncoder({
		calls = {
			multiArgument = true
		}
	})
	assert_equal('b64("hello")', encoder(build_call('b64', {'hello'})))
	assert_equal('add(1,2)', encoder(build_call('add', {1,2})))
	assert_equal('dood([b64("hello"),add(1,2)])',
		encoder(build_call('dood', { {
			build_call('b64', {'hello'}),
			build_call('add', {1,2})
		} })))
end
