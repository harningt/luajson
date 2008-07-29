-- Additional path that may be required
package.path = package.path .. ';?/init.lua;../src/?.lua;../src/?/init.lua'
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

local function putTempData(data)
	local name = os.tmpname()
	local f = assert(io.open(name, 'wb'))
	f:write(data)
	f:close()
	return name
end

-- Ensure that the encoder/decoder can round-trip valid JSON
local function RoundTripTest(parseFunc, luaData)
	local dataString = json.encode(luaData)
	assert(dataString, "Couldn't encode the lua data")
	local success, result = pcall(parseFunc, dataString)
	if not success then
		print("Could not parse the generated JSON of (", luaData)
		print("GENERATED: [[" .. dataString .. "]]")
		print("DATA STORED IN: ", putTempData(dataString))
		return
	end
	local newData = json.encode(result)
	if not dataString == newData then
		print("Encoded values do not match")
		print("ORIGINAL: [[" .. dataString .. "]]")
		print("RE-ENCOD: [[" .. newData .. "]])")
	end
	return true
end
local function TestParser(parseFunc)
	for _,f in ipairs(successTests) do
		local data = getFileData(f)
		local succeed, result = pcall(parseFunc, data)
		if not succeed then print("Failed on : " .. f)
		else
			if not RoundTripTest(parseFunc, result) then
				print("FAILED TO ROUND TRIP: " .. f)
			end
		end
	end

	for _,f in ipairs(failTests) do
		local data = getFileData(f)
		local failed = not pcall(parseFunc, data)
		if not failed then print("Didn't fail on : " .. f) end
	end
end
print("Testing lax/fast mode...")
TestParser(function(data) return json.decode(data) end)

print("Testing strict mode...")
TestParser(function(data) return json.decode(data, true) end)
