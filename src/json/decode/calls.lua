local lpeg = require("lpeg")
local tostring = tostring
local pairs, ipairs = pairs, ipairs
local next, type = next, type
local error = error

local util = require("json.decode.util")
local VALUE = util.VALUE

local getmetatable = getmetatable

module("json.decode.calls")

local defaultOptions = {
	defs = nil,
	multiArgument = false
}

-- No real default-option handling needed...
default = nil
strict = nil

local isPattern
if lpeg.type then
	function isPattern(value)
		return lpeg.type(value) == 'pattern'
	end
else
	local metaAdd = getmetatable(lpeg.P("")).__add
	function isPattern(value)
		return getmetatable(value).__add == metaAdd
	end
end

function buildCapture(options)
	if not options or not options.defs or (nil == next(options.defs)) then -- No calls, don't bother to parse
		return nil
	end
	local callCapture
	for name, func in pairs(options.defs) do
		if type(name) ~= 'string' and not isPattern(name) then
			error("Invalid functionCalls name: " .. tostring(name) .. " not a string or LPEG pattern")
		end
		if type(func) ~= 'function' then
			error("Invalid functionCalls item: " .. name .. " not a function")
		end
		local nameCallCapture
		if type(name) == 'string' then
			nameCallCapture = lpeg.P(name .. "(") * lpeg.Cc(name)
		else
			-- Name matcher expected to produce a capture
			nameCallCapture = name * "("
		end
		-- Call func over nameCallCapture and value to permit function receiving name
		local argumentCapture
		if not options.multiArgument then
			argumentCapture = lpeg.V(VALUE)
		else -- Allow zero or more arguments separated by commas
			argumentCapture = (lpeg.V(VALUE) * (lpeg.P(",") *  lpeg.V(VALUE))^0) + 0
		end
		local newCapture = (nameCallCapture * argumentCapture) / func * ")"
		if not callCapture then
			callCapture = newCapture
		else
			callCapture = callCapture + newCapture
		end
	end
	return callCapture
end
