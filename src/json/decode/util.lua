--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")
local select = select
local pairs, ipairs = pairs, ipairs
module("json.decode.util")

space = lpeg.S(" \n\r\t\f")

identifier = lpeg.R("AZ","az","__") * lpeg.R("AZ","az", "__", "09") ^0

hex = lpeg.R("09","AF","af")
hexpair = hex * hex 

comments = {
	cpp = lpeg.P("//") * (1 - lpeg.P("\n"))^0 * lpeg.P("\n"),
	c = lpeg.P("/*") * (1 - lpeg.P("*/"))^0 * lpeg.P("*/")
}

comment = comments.cpp + comments.c

ignored = (space + comment)^0

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
		for k,v in pairs(select(i, ...)) do
			t[k] = v
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

function buildDepthLimit(limit)
	local currentDepth = 0
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

