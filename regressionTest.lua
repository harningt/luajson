-- Additional path that may be required
package.path = package.path .. ';?/init.lua'
require("json")

require("lfs")

local successTests = {}
local failTests = {}

for f in lfs.dir("test") do
	if f:match("^fail.*\.json") then
		failTests[#failTests + 1] = "test/" .. f
	elseif f:match("^pass.*\.json") then
		successTests[#successTests + 1] = "test/" .. f
	end
end

local function getFileData(fileName)
	local f = assert(io.open(fileName, 'rb'))
	local data = f:read('*a')
	f:close()
	return data
end

local function TestParser(parseFunc)
	for _,f in ipairs(successTests) do
		local data = getFileData(f)
		local succeed = pcall(parseFunc, data)
		if not succeed then print("Failed on : " .. f) end
	end

	for _,f in ipairs(failTests) do
		local data = getFileData(f)
		local failed = not pcall(parseFunc, data)
		if not failed then print("Didn't fail on : " .. f) end
	end
end
print("Testing lax/fast mode...")
TestParser(function(data) json.decode(data) end)

print("Testing strict mode...")
TestParser(function(data) json.decode(data, true) end)
