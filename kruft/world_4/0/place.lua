-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg
-- Place a block from a slot in a direction.
-- Written for CC:Tweaked

local currentSlot = turtle.getSelectedSlot()

if #arg < 1 then
  -- No arguments, place the current slot in front.
  turtle.place()
elseif arg[1] == "down" then
  if tonumber(arg[2]) ~= nil then
    turtle.select(tonumber(arg[2]))
  end
  turtle.placeDown()
  turtle.select(currentSlot)
elseif arg[1] == "up" then
    if tonumber(arg[2]) ~= nil then
        turtle.select(tonumber(arg[2]))
    end
    turtle.placeUp()
    turtle.select(currentSlot)
elseif tonumber(arg[1]) ~= nil then
    turtle.select(tonumber(arg[1]))
    turtle.place()
    turtle.select(currentSlot)
else
  -- print usage
  print("Usage: place [up|down] [slot]")
end
