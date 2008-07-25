--
--------------------------------------------------------------------------------
--         FILE:  dataTest.lua
--        USAGE:  ./dataTest.lua
package.path = package.path .. ';?/init.lua;../src/?.lua;../src/?/init.lua'

require("json")
local f = io.open("data.txt")
local data = f:read('*a')
f:close()
local opt = (...)
local strict = opt and opt:match('--strict')
local decode = json.decode.decode
for i = 1,1000 do
	decode(data, strict)
end
