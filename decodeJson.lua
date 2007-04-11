require("lpeg")

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

local pair = (identifier + string + int) * ignored * lpeg.P(':') * ignored * lpeg.V(1)

-- Deviation: allow for trailing comma, allow for "undefined" to be a value...
local grammar = lpeg.P({
	[1] = ignored * (string + number + lpeg.P("true") + lpeg.P("false") + lpeg.P("null") + lpeg.P("undefined") + lpeg.V(2) + lpeg.V(3)) * ignored,
	[2] = lpeg.P("{") * ignored * ((pair * (ignored * lpeg.P(',') * ignored * pair)^0) + 0) * ignored * (lpeg.P(',') + 0) * ignored * lpeg.P("}"),
	[3] = lpeg.P("[") * ignored * ((lpeg.V(1) * (ignored * lpeg.P(',') * ignored * lpeg.V(1))^0) + 0) * ignored * (lpeg.P(",") + 0) * ignored * lpeg.P("]")
}) * ignored * -1

--NOTE: Certificate was trimmed down to make it easier to read....

local testStrings = {
	[[{1:[1213.3e12, 123 , 123, "hello", [12, 2], {1:true /*test*/}]}]],
	[[{"username":"demo1","message":null,"password":""}]],
	[[{"challenge":"b64d-fnNQ6bRZ7CYiNIKwmdHoNgl9JR9MIYtzjBhpQzYXCFrgARt9mNmgUuO7FoODGr1NieT9yTeB2SLztGkvIA4NXmN9Bi27hqx1ybJIQq6S2L-AjQ3VTDClSmCsYFPOm9EMVZDZ0jhBX1fXw3o9VYj1j9KzSY5VCSAzGqYo-cBPY

.b64","cert":"b64MIIGyjCCBbKgAwIBAgIKFAC1ZgAAAAAUYzANBgkqhkiG9w0BAQUFADBZMRUwEwYKCZImiZPyLGQBGRYFbG9
tp8uQuFjWGS_KxTHXz9vkLNFjOoZY2bOwzsdEpshuYSdvX-9bRvHTQcoMNz8Q9nXG1aMl5x1nbV5byQNTCJlz4gzMJeNfeKGcipdCj7B6e_VpF-n2P-dFZizUHjxMksCVZ3nTr51x3Uw

.b64","key":"D79B30BA7954DF520B44897A6FF58919"}]],
[[{"key":"D79B30BA7954DF520B44897A6FF58919"}]],
[[{"val":undefined}]]
}
for i, v in ipairs(testStrings) do
	print("Testing: #" .. i)
	print(lpeg.match(lpeg.C(grammar), v))
end
