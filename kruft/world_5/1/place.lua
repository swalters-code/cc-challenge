-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel
-- Written for CC:Tweaked

-- TODO: Add slot selection to command line

if arg[1] == "down"
then
  turtle.placeDown()
elseif arg[1] == "up"
then
  turtle.placeUp()
else
  turtle.place()
end
