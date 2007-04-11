local type = type
local print = print
local tostring = tostring
local pairs = pairs
module("json.util")
local function foreach(tab, func)
	for k, v in pairs(tab) do
		func(k,v)
	end
end
function printValue(tab, name)
        local parsed = {}
        local function doPrint(key, value, space)
                space = space or ''
                if type(value) == 'table' then
                        if parsed[value] then
                                print(space .. key .. '= <' .. parsed[value] .. '>')
                        else
                                parsed[value] = key
                                print(space .. key .. '= {')
                                space = space .. ' '
                                foreach(value, function(key, value) doPrint(key, value, space) end)
                        end
                else
					if type(value) == 'string' then
						value = '[[' .. tostring(value) .. ']]'
					end
                   	print(space .. key .. '=' .. tostring(value))
                end
        end
        doPrint(name, tab)
end

-- Function to insert nulls into the JSON stream
function null()
	return null
end

