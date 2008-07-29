--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")
local util = require("json.util")

local number = require("json.decode.number")

local setmetatable, getmetatable = setmetatable, getmetatable
local assert = assert
local print = print
local tonumber = tonumber
local ipairs = ipairs
local string = string
module("json.decode")
local alpha = lpeg.R("AZ","az")
local hex = lpeg.R("09","AF","af")
local hexpair = hex * hex

local nullValue = util.null
local undefinedValue = util.null

local identifier = lpeg.R("AZ","az","__") * lpeg.R("AZ","az", "__", "09") ^0

local space = lpeg.S(" \n\r\t\f")
local comment = (lpeg.P("//") * (1 - lpeg.P("\n"))^0 * lpeg.P("\n"))
	+ (lpeg.P("/*") * (1 - lpeg.P("*/"))^0 * lpeg.P("*/"))

local ignored = (space + comment)^0

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
local function unicodeParse(code1, code2)
	code1, code2 = tonumber(code1, 16), tonumber(code2, 16)
	return string.char(code1, code2)
end

-- Potential deviation, allow for newlines inside strings
local function buildStringCapture(stopParse, escapeMatch)
	return lpeg.P('"') * lpeg.Cs(((1 - lpeg.S(stopParse)) + (lpeg.P("\\") / "" * escapeMatch))^0) * lpeg.P('"')
end

local doSimpleSub = lpeg.C(lpeg.S("rnfbt/\\z\"")) / knownReplacements
local doUniSub = (lpeg.P('u') * lpeg.C(hexpair) * lpeg.C(hexpair) + lpeg.P(false)) / unicodeParse
local doSub = doSimpleSub + doUniSub
-- Non-strict capture just spits back input value w/o slash
local captureString = buildStringCapture('"\\', doSub + lpeg.C(1))
local strictCaptureString = buildStringCapture('"\\\r\n\f\b\t', #lpeg.S("rnfbt/\\\"u") * doSub)

local VALUE, TABLE, ARRAY = 2,3,4

-- For null and undefined, use the util.null value to preserve null-ness
local booleanCapture =
	lpeg.P("true") * lpeg.Cc(true)
	+ lpeg.P("false") * lpeg.Cc(false)
local tableArrayCapture = lpeg.V(TABLE) + lpeg.V(ARRAY)

local nullCapture = lpeg.P("null") * lpeg.Cc(nullValue)
local undefinedCapture = lpeg.P("undefined") * lpeg.Cc(undefinedValue)

local function buildValueCapture(nullValue, undefinedValue, allowUndefined, allowNaN, strictMinusSpace, strictString)
	local ret = (
		(strictString and strictCaptureString or captureString)
		+ number.buildCapture({nan = allowNaN, inf = allowNaN, struct = strictMinusSpace})
		+ booleanCapture
		+ nullCapture
	)
	if allowUndefined then
		ret = ret + undefinedCapture
	end
	ret = ret + tableArrayCapture
	ret = ignored * ret * ignored
	return ret
end

local valueCapture = buildValueCapture(nullValue, nullValue, true, true, false, false)

local strictValueCapture = buildValueCapture(nullValue, nil, false, false, true, true)

local currentDepth
local function initDepth(s, i)
	currentDepth = 0
	return i
end
local function incDepth(s, i)
	currentDepth = currentDepth + 1
	return currentDepth < 20 and i or false
end
local function decDepth(s, i)
	currentDepth = currentDepth - 1
	return i
end

local tableKey = 
	lpeg.C(identifier)
	+ captureString
	+ number.int / tonumber
local strictTableKey = captureString

local function initTable(tab)
	return {}
end

-- tableItem == pair
local function applyTableKey(tab, key, val)
	if not tab then tab = {} end -- Initialize table for this set...
	tab[key] = val
	return tab
end
local function createTableItem(keyParser)
	return (keyParser * ignored * lpeg.P(':') * ignored * lpeg.V(VALUE)) / applyTableKey
end
local tableItem = createTableItem(tableKey)
local strictTableItem = createTableItem(strictTableKey)

local tableElements = lpeg.Ca(lpeg.Cc(false) / initTable * (tableItem * (ignored * lpeg.P(',') * ignored * tableItem)^0 + 0))
local strictTableElements = lpeg.Ca(lpeg.Cc(false) / initTable * (strictTableItem * (ignored * lpeg.P(',') * ignored * strictTableItem)^0 + 0))

local tableCapture =
	lpeg.P("{") * ignored
	* tableElements * ignored
	* (lpeg.P(',') + 0) * ignored
	* lpeg.P("}")
local strictTableCapture =
	lpeg.P("{") * lpeg.P(incDepth) * ignored
	* strictTableElements * ignored
	* lpeg.P("}") * lpeg.P(decDepth)


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
local arrayItem = lpeg.V(VALUE)
local arrayElements = lpeg.Ct(arrayItem * (ignored * lpeg.P(',') * ignored * arrayItem)^0 + 0) / processArray
local strictArrayCapture = 
	lpeg.P("[") * lpeg.P(incDepth) * ignored 
	* (arrayElements) * ignored 
	* lpeg.P("]") * lpeg.P(decDepth)
local arrayCapture = 
	lpeg.P("[") * ignored 
	* (arrayElements) * ignored 
	* (lpeg.P(",") + 0) * ignored 
	* lpeg.P("]")

-- Deviation: allow for trailing comma, allow for "undefined" to be a value...
local grammar = lpeg.P({
	[1] = lpeg.V(VALUE),
	[VALUE] = valueCapture,
	[TABLE] = tableCapture,
	[ARRAY] = arrayCapture
}) * ignored * -1

local strictGrammar = lpeg.P({
	[1] = lpeg.P(initDepth) * (lpeg.V(TABLE) + lpeg.V(ARRAY)), -- Initial value MUST be an object or array
	[VALUE] = strictValueCapture,
	[TABLE] = strictTableCapture,
	[ARRAY] = strictArrayCapture
}) * ignored * -1

--NOTE: Certificate was trimmed down to make it easier to read....

function decode(data, strict)
	return (assert(lpeg.match(not strict and grammar or strictGrammar, data), "Invalid JSON data"))
end

local mt = getmetatable(_M) or {}
mt.__call = function(self, ...)
	return decode(...)
end
setmetatable(_M, mt)
