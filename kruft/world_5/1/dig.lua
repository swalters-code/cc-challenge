-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel
-- Written for CC:Tweaked

-- Simple script to dig in a specified direction.

if arg[1] ~= nil
  and arg[1] ~= "down"
  and arg[1] ~= "up"
then
  print("Invalid argument: " .. arg[1])
  print("Usage: dig <down|up>")
  print("With no arguments, digs forward.")
  return
end

if arg[1] == "down"
then
  turtle.digDown()
elseif arg[1] == "up"
then
  turtle.digUp()
else
  turtle.dig()
end
