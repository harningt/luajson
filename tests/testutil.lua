local pcall, error = pcall, error

local lunit = require("lunit")
local assert_error = lunit.assert_error

-- Allow module to alter decoder
local decoders = {}
local function pushDecoder(d)
	decoders[#decoders + 1] = decode
	decode = d
end
local function popDecoder()
	decode = decoders[#decoders]
	decoders[#decoders] = nil
end
module("testutil", package.seeall)
function buildPatchedDecoder(f, newDecoder)
	return function()
		pushDecoder(newDecoder)
		local ret, err = pcall(f)
		popDecoder()
		if not ret then
			error(err, 0)
		end
	end
end
function buildFailedPatchedDecoder(f, newDecoder)
	return function()
		pushDecoder(newDecoder)
		assert_error(f)
		popDecoder()
	end
end
