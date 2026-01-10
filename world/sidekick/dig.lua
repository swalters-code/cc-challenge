-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel
-- Written for CC:Tweaked

if arg[1] == "down"
then
  turtle.digDown()
elseif arg[1] == "up"
then
  turtle.digUp()
else
  turtle.dig()
end
