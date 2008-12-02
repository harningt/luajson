--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")
local select = select
local pairs, ipairs = pairs, ipairs
local tonumber = tonumber
local string_char = string.char
module("json.decode.util")

-- 09, 0A, 0B, 0C, 0D, 20
ascii_space = lpeg.S("\t\n\v\f\r ")
do
	local chr = string_char
	local u_space = ascii_space
	-- \u0085 \u00A0
	u_space = u_space + lpeg.P(chr(0xC2)) * lpeg.S(chr(0x85) .. chr(0xA0))
	-- \u1680 \u180E
	u_space = u_space + lpeg.P(chr(0xE1)) * (lpeg.P(chr(0x9A, 0x80)) + chr(0xA0, 0x8E))
	-- \u2000 - \u200A, also 200B
	local spacing_end = ""
	for i = 0x80,0x8b do
		spacing_end = spacing_end .. chr(i)
	end
	-- \u2028 \u2029 \u202F
	spacing_end = spacing_end .. chr(0xA8) .. chr(0xA9) .. chr(0xAF)
	u_space = u_space + lpeg.P(chr(0xE2, 0x80)) * lpeg.S(spacing_end)
	-- \u205F
	u_space = u_space + lpeg.P(chr(0xE2, 0x81, 0x9F))
	-- \u3000
	u_space = u_space + lpeg.P(chr(0xE3, 0x80, 0x80))
	-- BOM \uFEFF
	u_space = u_space + lpeg.P(chr(0xEF, 0xBB, 0xBF))
	_M.unicode_space = u_space
end

identifier = lpeg.R("AZ","az","__") * lpeg.R("AZ","az", "__", "09") ^0

hex = lpeg.R("09","AF","af")
hexpair = hex * hex

comments = {
	cpp = lpeg.P("//") * (1 - lpeg.P("\n"))^0 * lpeg.P("\n"),
	c = lpeg.P("/*") * (1 - lpeg.P("*/"))^0 * lpeg.P("*/")
}

comment = comments.cpp + comments.c

ascii_ignored = (ascii_space + comment)^0

unicode_ignored = (unicode_space + comment)^0

VALUE, TABLE, ARRAY = 2, 3, 4
function clone(t)
	local ret = {}
	for k,v in pairs(t) do
		ret[k] = v
	end
	return ret
end

function merge(t, ...)
	for i = 1,select('#', ...) do
		local currentTable = select(i, ...)
		if currentTable then
			for k,v in pairs(currentTable) do
				t[k] = v
			end
		end
	end
	return t
end

inits = {}

function doInit()
	for _, v in ipairs(inits) do
		v()
	end
end

-- Current depth is persistent
-- If more complex depth management needed, a new system would need to be setup
local currentDepth = 0

function buildDepthLimit(limit)
	local function init()
		currentDepth = 0
	end
	inits[#inits + 1] = init

	local function incDepth(s, i)
		currentDepth = currentDepth + 1
		return currentDepth < limit and i or false
	end
	local function decDepth(s, i)
		currentDepth = currentDepth - 1
		return i
	end
	return {incDepth, decDepth}
end


-- Parse the lpeg version skipping patch-values
-- LPEG <= 0.7 have no version value... so 0.7 is value
DecimalLpegVersion = lpeg.version and tonumber(lpeg.version():match("^(%d+%.%d+)")) or 0.7
