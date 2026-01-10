-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg
-- Dig a 1x3 spiral in towards the center.

-- Start just outside the spiral. The spiral will
-- be built forward and to the right of the turtle.

-- Written for CC:Tweaked

if #arg < 1 then
  print("Usage: dig_spiral <length>")
  print("Digs a 1x3 spiral of given length.")
  print("The turtle starts just outside the spiral,")
  print("facing forward along the spiral path.")
  print("The spiral will be dug forward and to the right of the turtle.")
  return
end

local length = tonumber(arg[1]) or 1
local t = turtle

local function digSegment(length)
  for _ = 1, length do
    t.dig()
    t.forward()
    t.digUp()
    t.digDown()
  end
  t.turnRight()
end

digSegment(length)
digSegment(length - 1)

length = length - 2

while length > 0 do
  digSegment(length)
  digSegment(length)
  length = length - 1
end
