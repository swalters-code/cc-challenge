-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg
-- Written for CC:Tweaked

-- Refuel a turtle on a lake of fluid fuel.


local t = turtle
local bucketSlot = 1 -- Assume buckets are in slot 1

local length = tonumber(arg[1]) or 1
local width = tonumber(arg[2]) or 1


-- zig zag over a rectangle of given length and
-- width, calling func at each position.  The
-- turtle starts at one corner, and the rectangle
-- extends length in front of it and width to the
-- right. Work from closest to the farthest. (left
-- to right first, then front to back)
---@param length number
---@param width number
---@param func fun(l:number, w:number, dist:number) Function called at each position
local function zigzag(length, width, func)
  -- Which direction to turn at the end of a row.
  local dir = "left"
  -- The total distance travelled.
  local dist = 0

  turtle.turnRight()
  for l = 1, length do
    for w = 1, width - 1 do
      func(l, w, dist)
      t.forward()
      dist = dist + 1
    end
    if l < length then
      func(l, width, dist)
      if dir == "left" then
        t.turnLeft()
        func(l, width, dist)
        t.forward()
        t.turnLeft()
        dir = "right"
        dist = dist + 1
      else
        t.turnRight()
        func(l, width, dist)
        t.forward()
        t.turnRight()
        dir = "left"
        dist = dist + 1
      end
    end
  end
  func(length, width, dist)
  print("Zigzag complete distance: " .. dist)
end


-- Return to starting position after zigzagging.
local function zigzagReturn(length, width)
  if length % 2 == 0 then
    t.turnLeft()
  else
    t.turnRight()
  end

  for _ = 1, length - 1 do
    t.forward()
  end

  if length % 2 == 0 then
    t.turnLeft()
    t.turnLeft()
  else
    t.turnRight()
    for _ = 1, width - 1 do
      t.forward()
    end
    t.turnRight()
  end
end


local function refuelAt(l, w, dist)
  print("Refuelling at " .. l .. "," .. w .. " dist " .. dist)
  t.select(bucketSlot)
  -- Clear obstructions
  t.dig()
  if t.placeDown() then
    t.refuel(1)
    print("Fuel level: " .. t.getFuelLevel())
  else
    print("Failed to place bucket")
  end
end

print("Starting zigzag refuel over " .. length .. "x" .. width)
zigzag(length, width, refuelAt)
print("Returning to start")
zigzagReturn(length, width)
