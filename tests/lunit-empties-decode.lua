local json = require("json")
local lunit = require("lunit")

-- Test module for handling the decoding with 'empties' allowed
if not module then
    _ENV = lunit.module("lunit-empties-decode", 'seeall')
else
    module("lunit-empties-decode", lunit.testcase, package.seeall)
end

local options = {
    array = {
        allowEmptyElement = true
    },
    calls = {
        allowEmptyElement = true,
        allowUndefined = true
    },
    object = {
        allowEmptyElement = true,
    }
}
local options_notrailing = {
    array = {
        allowEmptyElement = true,
        trailingComma = false
    },
    calls = {
        allowEmptyElement = true,
        allowUndefined = true,
        trailingComma = false
    },
    object = {
        allowEmptyElement = true,
        trailingComma = false
    }
}
local options_simple_null = {
    array = {
        allowEmptyElement = true
    },
    calls = {
        allowEmptyElement = true,
        allowUndefined = true
    },
    object = {
        allowEmptyElement = true,
    },
    others = {
        null = false,
        undefined = false
    }
}

function test_decode_array_with_only_null()
    local result = assert(json.decode('[null]', options_simple_null))
    assert_nil(result[1])
    assert_equal(1, result.n)
    local result = assert(json.decode('[null]', options))
    assert_equal(json.util.null, result[1])
    assert_equal(1, #result)
end

function test_decode_array_with_empties()
    local result = assert(json.decode('[,]', options_simple_null))
    assert_nil(result[1])
    assert_equal(1, result.n)
    local result = assert(json.decode('[,]', options))
    assert_equal(json.util.undefined, result[1])
    assert_equal(1, #result)

    local result = assert(json.decode('[,]', options_notrailing))
    assert_equal(json.util.undefined, result[1])
    assert_equal(json.util.undefined, result[2])
    assert_equal(2, #result)
end

function test_decode_array_with_null()
    local result = assert(json.decode('[1, null, 3]', options_simple_null))
    assert_equal(1, result[1])
    assert_nil(result[2])
    assert_equal(3, result[3])
    assert_equal(3, result.n)
    local result = assert(json.decode('[1, null, 3]', options))
    assert_equal(1, result[1])
    assert_equal(json.util.null, result[2])
    assert_equal(3, result[3])
end
function test_decode_array_with_empty()
    local result = assert(json.decode('[1,, 3]', options_simple_null))
    assert_equal(1, result[1])
    assert_nil(result[2])
    assert_equal(3, result[3])
    assert_equal(3, result.n)
    local result = assert(json.decode('[1,, 3]', options))
    assert_equal(1, result[1])
    assert_equal(json.util.undefined, result[2])
    assert_equal(3, result[3])
end

function test_decode_small_array_with_trailing_null()
    local result = assert(json.decode('[1, null]', options_simple_null))
    assert_equal(1, result[1])
    assert_nil(result[2])
    assert_equal(2, result.n)
    local result = assert(json.decode('[1, ]', options_simple_null))
    assert_equal(1, result[1])
    assert_equal(1, #result)
    local result = assert(json.decode('[1, ]', options))
    assert_equal(1, result[1])
    assert_equal(1, #result)
    local result = assert(json.decode('[1, ]', options_notrailing))
    assert_equal(1, result[1])
    assert_equal(json.util.undefined, result[2])
    assert_equal(2, #result)
end

function test_decode_array_with_trailing_null()
    local result = assert(json.decode('[1, null, 3, null]', options_simple_null))
    assert_equal(1, result[1])
    assert_nil(result[2])
    assert_equal(3, result[3])
    assert_nil(result[4])
    assert_equal(4, result.n)
    local result = assert(json.decode('[1, null, 3, null]', options))
    assert_equal(1, result[1])
    assert_equal(json.util.null, result[2])
    assert_equal(3, result[3])
    assert_equal(json.util.null, result[4])
    assert_equal(4, #result)
    local result = assert(json.decode('[1, , 3, ]', options))
    assert_equal(1, result[1])
    assert_equal(json.util.undefined, result[2])
    assert_equal(3, result[3])
    assert_equal(3, #result)
    local result = assert(json.decode('[1, , 3, ]', options_notrailing))
    assert_equal(1, result[1])
    assert_equal(json.util.undefined, result[2])
    assert_equal(3, result[3])
    assert_equal(json.util.undefined, result[4])
    assert_equal(4, #result)
end

function test_decode_object_with_null()
    local result = assert(json.decode('{x: null}', options_simple_null))
    assert_nil(result.x)
    assert_nil(next(result))

    local result = assert(json.decode('{x: null}', options))
    assert_equal(json.util.null, result.x)

    local result = assert(json.decode('{x: }', options_simple_null))
    assert_nil(result.x)
    assert_nil(next(result))

    local result = assert(json.decode('{x: }', options))
    assert_equal(json.util.undefined, result.x)

    -- Handle the trailing comma case
    local result = assert(json.decode('{x: ,}', options_simple_null))
    assert_nil(result.x)
    assert_nil(next(result))

    local result = assert(json.decode('{x: ,}', options))
    assert_equal(json.util.undefined, result.x)

    -- NOTE: Trailing comma must be allowed explicitly in this case
    assert_error(function()
        json.decode('{x: ,}', options_notrailing)
    end)

    -- Standard setup doesn't allow empties
    assert_error(function()
        json.decode('{x: }')
    end)
end
function test_decode_bigger_object_with_null()
    local result = assert(json.decode('{y: 1, x: null}', options_simple_null))
    assert_equal(1, result.y)
    assert_nil(result.x)

    local result = assert(json.decode('{y: 1, x: null}', options))
    assert_equal(1, result.y)
    assert_equal(json.util.null, result.x)

    local result = assert(json.decode('{y: 1, x: }', options_simple_null))
    assert_equal(1, result.y)
    assert_nil(result.x)
    local result = assert(json.decode('{x: , y: 1}', options_simple_null))
    assert_equal(1, result.y)
    assert_nil(result.x)

    local result = assert(json.decode('{y: 1, x: }', options))
    assert_equal(1, result.y)
    assert_equal(json.util.undefined, result.x)

    local result = assert(json.decode('{x: , y: 1}', options))
    assert_equal(1, result.y)
    assert_equal(json.util.undefined, result.x)

    -- Handle the trailing comma case
    local result = assert(json.decode('{y: 1, x: , }', options_simple_null))
    assert_equal(1, result.y)
    assert_nil(result.x)
    local result = assert(json.decode('{x: , y: 1, }', options_simple_null))
    assert_equal(1, result.y)
    assert_nil(result.x)

    local result = assert(json.decode('{y: 1, x: ,}', options))
    assert_equal(1, result.y)
    assert_equal(json.util.undefined, result.x)

    local result = assert(json.decode('{x: , y: 1, }', options))
    assert_equal(1, result.y)
    assert_equal(json.util.undefined, result.x)

    -- NOTE: Trailing comma must be allowed explicitly in this case as there is no such thing as an "empty" key:value pair
    assert_error(function()
        json.decode('{y: 1, x: ,}', options_notrailing)
    end)
    assert_error(function()
        json.decode('{x: , y: 1, }', options_notrailing)
    end)
end

function test_decode_call_with_empties()
    local result = assert(json.decode('call(,)', options_simple_null))
    result = result.parameters
    assert_nil(result[1])
    assert_equal(1, result.n)
    local result = assert(json.decode('call(,)', options))
    result = result.parameters
    assert_equal(json.util.undefined, result[1])
    assert_equal(1, #result)

    local result = assert(json.decode('call(,)', options_notrailing))
    result = result.parameters
    assert_equal(json.util.undefined, result[1])
    assert_equal(json.util.undefined, result[2])
    assert_equal(2, #result)
end



function test_call_with_empties_and_trailing()
    local result = assert(json.decode('call(1, null, 3, null)', options_simple_null))
    result = result.parameters
    assert_equal(1, result[1])
    assert_nil(result[2])
    assert_equal(3, result[3])
    assert_nil(result[4])
    assert_equal(4, result.n)
    local result = assert(json.decode('call(1, null, 3, null)', options))
    result = result.parameters
    assert_equal(1, result[1])
    assert_equal(json.util.null, result[2])
    assert_equal(3, result[3])
    assert_equal(json.util.null, result[4])
    assert_equal(4, #result)
    local result = assert(json.decode('call(1, , 3, )', options))
    result = result.parameters
    assert_equal(1, result[1])
    assert_equal(json.util.undefined, result[2])
    assert_equal(3, result[3])
    assert_equal(3, #result)
    local result = assert(json.decode('call(1, , 3, )', options_notrailing))
    result = result.parameters
    assert_equal(1, result[1])
    assert_equal(json.util.undefined, result[2])
    assert_equal(3, result[3])
    assert_equal(json.util.undefined, result[4])
    assert_equal(4, #result)
end
