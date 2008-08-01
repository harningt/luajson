-- Additional path that may be required
package.path = package.path .. ';?/init.lua;../src/?.lua;../src/?/init.lua'
require("json")

require("lfs")

local successTests = {}
local failTests = {}
local failStrictTests = {}

for f in lfs.dir("test") do
	if f:match("^fail.*\.json") then
		failTests[#failTests + 1] = "test/" .. f
	elseif f:match("^pass.*\.json") then
		successTests[#successTests + 1] = "test/" .. f
	end
end

local function getFileData(fileName)
	local f = io.open(fileName, 'rb')
	if not f then return end
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

local function testFile(fileName, parseFunc, expectSuccess)
	local data = getFileData(fileName)
	if not data then return end
	print("TESTING: ", fileName, "for", expectSuccess and "success" or "fail")
	local succeed, result = pcall(parseFunc, data)
	if expectSuccess ~= succeed then
		print("Wrongly " .. (expectSuccess and "Failed" or "Succeeded") .. " on : " .. fileName .. "(" .. tostring(result) .. ")")
	elseif succeed then
		if not RoundTripTest(parseFunc, result) then
			print("FAILED TO ROUND TRIP: " .. fileName)
		end
	end
end

local function TestParser(parseFunc, successNames, failNames)
	for _,successes in ipairs(successNames) do
		for f in lfs.dir(successes) do
			testFile(successes .. "/" .. f, parseFunc, true)
		end
	end
	for _, failures in ipairs(failNames) do
		for f in lfs.dir(failures) do
			testFile(failures .. "/" .. f, parseFunc, false)
		end
	end
end
print("Testing lax/fast mode...")
TestParser(function(data) return json.decode(data) end, {"test/pass","test/fail_strict"}, {"test/fail_all"})

print("Testing strict mode...")
TestParser(function(data) return json.decode(data, true) end, {"test/pass"}, {"test/fail_strict","test/fail_all"})
