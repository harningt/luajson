--[[
  Some Time Trails for the JSON4Lua package
]]--

package.path = package.path .. ';?/init.lua'
require('json')
require('os')
require('table')

local t1 = os.clock()
local jstr
local v
for i=1,500 do
  local t = {}
  for j=1,500 do
    t[#t + 1] = j
  end
  for j=1,500 do
    t[#t + 1] = "VALUE"
  end
  jstr = json.encode(t)
  v = json.decode(jstr)
  --print(json.encode(t))
end

for i = 1,500 do
  local t = {}
  for j=1,500 do
    local m= math.mod(j,3)
    if (m==0) then
      t['a'..j] = true
    elseif m==1 then 
      t['a'..j] = json.util.null
    else
      t['a'..j] = j
    end
  end
  jstr = json.encode(t)
  v = json.decode(jstr)
end

print (jstr)
--print(type(t1))
local t2 = os.clock()

print ("Elapsed time=" .. os.difftime(t2,t1) .. "s")
