local lpeg = require("lpeg")
local util = require("json.util")

local setmetatable, getmetatable = setmetatable, getmetatable
local assert = assert
local print = print
local tonumber = tonumber
local ipairs = ipairs
module("json.decode")
local digit = lpeg.R("09")
local digits = digit^1
local alpha = lpeg.R("AZ","az")
local identifier = (alpha + lpeg.P("_")) * (alpha + lpeg.P('-')^0 * digits + lpeg.P("_")) ^0

local space = lpeg.S(" \n\r\t\f")
local comment = (lpeg.P("//") * (1 - lpeg.P("\n"))^0 * lpeg.P("\n"))
	+ (lpeg.P("/*") * (1 - lpeg.P("*/"))^0 * lpeg.P("*/"))

local ignored = (space + comment)^0

-- Potential deviation, allow for newlines inside strings
local strictString = lpeg.P('"') * ((1 - lpeg.S('"\r\n\f\\')) + (lpeg.P("\\") * 1))^0 * lpeg.P('"')
local string = lpeg.P('"') * ((1 - lpeg.S('"\\')) + (lpeg.P("\\") * 1))^0 * lpeg.P('"')
-- Deviation.. permit leading zeroes, permit inf number of negatives w/ space between
local int = lpeg.P('-')^0 * space^0 * digits
local frac = lpeg.P('.') * digits
local exp = lpeg.S("Ee") * (lpeg.S("-+") + 0) * digits -- Optional +- after the E
local number = int * frac * exp + int * frac + int * exp + int

local VAL, TABLE, ARRAY = 1,2,3

local knownReplacements = {
	n = "\n",
	r = "\r",
	f = "\f",
	t = "\t",
	b = "\b",
	z = "\z",
	['\\'] = "\\",
	['/'] = "/",
	['"'] = '"'
}
local function unicodeParse(code1,code2)
	return string.char(tonumber(code1, 16),tonumber(code2,16))
end
	
local function parseString(s)
	s = s:match('^"(.*)"$') -- TODO: Optimize
	s = s:gsub('\\(.)', knownReplacements)
	s = s:gsub('\\u(..)(..)', unicodeParse)
	return s
end

-- For null and undefined, use the util.null value to preserve null-ness
local valueCapture = ignored * (
	lpeg.C(string) / parseString
	+ lpeg.C(number) / tonumber
	+ lpeg.P("true") * lpeg.Cc(true)
	+ lpeg.P("false") * lpeg.Cc(false)
	+ (lpeg.P("null") + lpeg.P("undefined")) * lpeg.Cc(util.null)
	+ lpeg.V(TABLE) 
	+ lpeg.V(ARRAY)
) * ignored

local tableKey = 
	lpeg.C(identifier) 
	+ string / parseString
	+ int / tonumber

local tableVal = lpeg.V(VAL)

-- tableItem == pair
local tableItem = tableKey * ignored * lpeg.P(':') * ignored * tableVal
tableItem = tableItem / function(tab, key, val)
	if not tab then tab = {} end -- Initialize table for this set...
	tab[key] = val
	return tab
end
local tableElements = lpeg.Ca(lpeg.Cc(false) * tableItem * (ignored * lpeg.P(',') * ignored * tableItem)^0)
local tableCapture = 
	lpeg.P("{") * ignored 
	* (tableElements + 0) * ignored 
	* (lpeg.P(',') + 0) * ignored 
	* lpeg.P("}")


-- Utility function to help manage slighly sparse arrays
local function processArray(array)
	array.n = #array
	for i,v in ipairs(array) do
		if v == util.null then
			array[i] = nil
		end
	end
	if #array == array.n then
		array.n = nil
	end
	return array
end
-- arrayItem == element
local arrayItem = lpeg.V(VAL)
local arrayElements = lpeg.Ct(arrayItem * (ignored * lpeg.P(',') * ignored * arrayItem)^0) / processArray
local arrayCapture = lpeg.P("[") * ignored * (arrayElements + 0) * ignored * (lpeg.P(",") + 0) * ignored * lpeg.P("]")

-- Deviation: allow for trailing comma, allow for "undefined" to be a value...
local grammar = lpeg.P({
	[1] = valueCapture,
	[2] = tableCapture,
	[3] = arrayCapture
}) * ignored * -1

--NOTE: Certificate was trimmed down to make it easier to read....

function decode(data)
	return (assert(lpeg.match(grammar, data), "Invalid JSON data"))
end

local mt = getmetatable(_M) or {}
mt.__call = function(self, ...)
	return decode(...)
end
setmetatable(_M, mt)
