-- Additional path that may be required
require("json")

require("lfs")

local success = true

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
local function RoundTripTest(parseFunc, jsonData, luaData, fullRoundTrip)
	local dataString = json.encode(luaData)
	assert(dataString, "Couldn't encode the lua data")
	local success, result = pcall(parseFunc, dataString)
	if not success then
		print("Could not parse the generated JSON of (", luaData)
		print("GENERATED: [[" .. dataString .. "]]")
		print("DATA STORED IN: ", putTempData(dataString))
		return
	end
	if fullRoundTrip then
		-- Ensure that whitespace is trimmed off ends
		dataString = dataString:match("^[%s]*(.-)[%s]*$")
		jsonData = jsonData:match("^[%s]*(.-)[%s]*$")
		if dataString ~= jsonData then
			print("Encoded values do not match")
			print("ORIGINAL: << " .. jsonData .. " >>")
			print("RE-ENCOD: << " .. dataString .. " >>")
			return
		end
	end
	return true
end

local function testFile(fileName, parseFunc, expectSuccess, fullRoundTrip)
	local data = getFileData(fileName)
	if not data then return end
	io.write(".")
	local succeed, result = pcall(parseFunc, data)
	if expectSuccess ~= succeed then
		print("Wrongly " .. (expectSuccess and "Failed" or "Succeeded") .. " on : " .. fileName .. "(" .. tostring(result) .. ")")
		success = false
	elseif succeed then
		if not RoundTripTest(parseFunc, data, result, fullRoundTrip) then
			print("FAILED TO ROUND TRIP: " .. fileName)
			success = false
		end
	end
end

local function testDirectories(parseFunc, directories, ...)
	if not directories then return end
	for _,directory in ipairs(directories) do
		if lfs.attributes(directory, 'mode') == 'directory' then
			for f in lfs.dir(directory) do
				testFile(directory .. "/" .. f, parseFunc, ...)
			end
		end
	end
	io.write("\n")
end

local function TestParser(parseFunc, successNames, failNames, roundTripNames)
	testDirectories(parseFunc, successNames, true, false)
	testDirectories(parseFunc, failNames, false, false)
	testDirectories(parseFunc, roundTripNames, true, true)
end
print("Testing lax/fast mode:")
TestParser(function(data) return json.decode(data) end, {"test/pass","test/fail_strict"}, {"test/fail_all"},{"test/roundtrip","test/roundtrip_lax"})

print("Testing (mostly) strict mode:")
local strict = json.decode.util.merge({}, json.decode.strict, {
	number = {
		nan = false,
		inf = true,
		strict = true
	}
})
TestParser(function(data) return json.decode(data, strict) end, {"test/pass"}, {"test/fail_strict","test/fail_all"}, {"test/roundtrip"})

if not success then
	os.exit(1)
end
