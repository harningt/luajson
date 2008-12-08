package = "luajson"
version = "scm-1"
source = {
	url = "git://github.com/harningt/luajson.git"
}
description = {
	summary = "customizable JSON decoder/encoder",
	detailed = [[
		LuaJSON is a customizable JSON decoder/encoder using
		LPEG for parsing.
	]],
	homepage = "http://github.com/harningt/luajson",
	maintainer = "Thomas Harning <harningt@gmail.com>",
	license = "MIT/X11"
}
dependencies = {
	"lua >= 5.1",
	"lunit >= 0.4",
	"lpeg >= 0.8.1"
}
build = {
	type = "module",
	modules = {
		json = "src/json.lua",
		["json.util"] = "src/json/util.lua",
		["json.encode"] = "src/json/encode.lua",
		["json.decode"] = "src/json/decode.lua",
		["json.decode.array"] = "src/json/decode/array.lua",
		["json.decode.number"] = "src/json/decode/number.lua",
		["json.decode.object"] = "src/json/decode/object.lua",
		["json.decode.string"] = "src/json/decode/strings.lua",
		["json.decode.util"] = "src/json/decode/util.lua"
	}
}
