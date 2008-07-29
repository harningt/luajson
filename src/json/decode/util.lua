local lpeg = require("lpeg")
local select = select
local pairs = pairs
module("json.decode.util")

space = lpeg.S(" \n\r\t\f")

comments = {
	cpp = lpeg.P("//") * (1 - lpeg.P("\n"))^0 * lpeg.P("\n"),
	c = lpeg.P("/*") * (1 - lpeg.P("*/"))^0 * lpeg.P("*/")
}

comment = comments.cpp + comments.c

ignored = (space + comment)^0

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
