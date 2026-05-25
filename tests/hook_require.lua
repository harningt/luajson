local os = require("os")

local test_strict = os.getenv("TEST_STRICT")

local old_require = require
if os.getenv('LUA_OLD_INIT') then
	local loadstring = rawget(_G or {}, "loadstring") or load
	assert(loadstring(os.getenv('LUA_OLD_INIT')))()
else
	require("luarocks.require")
end
local luarocks_require = require

if test_strict and test_strict ~= "" and test_strict ~= "0" and test_strict ~= "false" then
	if test_strict == "pl.strict" then
		require("pl.strict")
		local mt = getmetatable(_G)
		if mt then
			local allowed = {
				newproxy = true,
				statsfile = true,
				reportfile = true,
				configfile = true,
				runreport = true,
				deletestats = true,
				include = true,
				exclude = true,
				reporter = true,
				tick = true,
				modules = true,
				unpack = true,
				_M = true,
				_NAME = true,
				_PACKAGE = true,
				setup = true,
				teardown = true,
				setfenv = true,
				getfenv = true,
				module = true,
			}
			mt.__declared = mt.__declared or {}
			for k, v in pairs(allowed) do
				mt.__declared[k] = v
			end
			local old_index = mt.__index
			mt.__index = function(t, n)
				if n == nil then
					return nil
				end
				return old_index(t, n)
			end
		end
	else
		local mt = getmetatable(_G)
		if not mt then
			mt = {}
			setmetatable(_G, mt)
		end
		mt.__declared = mt.__declared or {}
		for k in pairs(_G) do
			mt.__declared[k] = true
		end
		mt.__declared["_ENV"] = true

		local debug_getinfo = debug.getinfo
		local function what()
			local d = debug_getinfo(3, "S")
			return d and d.what or "C"
		end

		local old_newindex = mt.__newindex
		mt.__newindex = function(t, n, v)
			if not mt.__declared[n] then
				local w = what()
				if w ~= "main" and w ~= "C" then
					error("assign to undeclared variable '"..n.."'", 2)
				end
				mt.__declared[n] = true
			end
			if old_newindex then
				old_newindex(t, n, v)
			else
				rawset(t, n, v)
			end
		end

		local old_index = mt.__index
		mt.__index = function(t, n)
			if not mt.__declared[n] then
				local d = debug_getinfo(2, "S")
				if d and d.source and d.source:match("lua/json/") then
					error("variable '"..n.."' is not declared", 2)
				end
			end
			if old_index then
				return old_index(t, n)
			else
				return rawget(t, n)
			end
		end
	end
end

function require(module, ...)
	if module == "json" or module:match("^json%.") then
		return old_require(module, ...)
	end
	return luarocks_require(module, ...)
end
