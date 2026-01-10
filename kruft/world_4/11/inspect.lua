-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg
-- Written for CC:Tweaked

-- Inspect a block and write the data to a file.

local fileName = "noname.txt"
local direction = arg[1] or "front"

local success, data
if direction == "down" then
  success, data = turtle.inspectDown()
elseif direction == "up" then
  success, data = turtle.inspectUp()
else
  success, data = turtle.inspect()
end

if not success then
  data = "No block detected."
end

if data.name ~= nil then
  -- replace the : with _ for file name
  fileName = "inspect_" .. string.gsub(data.name, ":", "_") .. ".txt"
end
-- Open the file in write mode
print("Writing inspection data to " .. fileName)

local file = fs.open(fileName, "w")

-- Write the inspection data to the file
if file ~= nil then
  file.write(textutils.serialize(data))
  file.close()
else
  print("Failed to open file for writing.")
end
