-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg
-- Kinda like excavate, but only goes to a certain depth.
-- Written for CC:Tweaked

-- USAGE: nexcavate <diameter> <depth>
-- Excavate a quarry of given diameter and depth.
-- If depth is negative, drill upwards. (unimplemented)
-- If depth is "bedrock" or omitted, drill until bedrock is reached. (unimplemented)

-- TODO: Keep a log of the inspect data for each block dug.
-- TODO: Add a function that is called at each block.
-- TODO: Add a function that is called before moving to the next block. (let's you choose to dig or not)
-- TODO: add upward drilling
-- TODO: add returning to chest
-- TODO: add refueling from inventory
-- TODO: add refueling from chest
-- TODO: add tossing garbage blocks.

local t = turtle

-- Eventually track position and direction for returning to drop off point.
local state = {
  direction = 0, -- clockwise
  -- 0 = forward
  -- 1 = right
  -- 2 = back
  -- 3 = left
  x = 0, -- Postitive along direction 0 (forward)
  y = 0, -- Postiive up and down.
  z = 0, -- Postive along direction 1 (right)
}

-- Simulate integer division (dividend // divisor)
---@param dividend integer
---@param divisor integer
---@return integer
local function intDiv(dividend, divisor)
  return math.floor(dividend / divisor)
end



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
  -- Whenever func is called, we are assured to be
  -- facing toward the next position.

  -- Sanity check the arguments.
  assert(length > 0, "Length must be positive")
  assert(width > 0, "Width must be positive")
  assert(func ~= nil, "Function must be provided")
  assert(type(func) == "function", "func must be a function")

  -- Two degenerate cases are most easily handled
  -- separately.

  -- length == 1, width == 1.
  if length == 1 and width == 1 then
    func(1, 1, 1)
    return
  end

  -- length > 1, width == 1.
  if width == 1 then
    for l = 1, length do
      func(l, 1, l)
      if l < length then
        t.dig()
        t.forward()
      end
    end
    return
  end

  -- length == 1, width > 1 is handled correctly
  -- below.

  -- simplify the way the math looks.
  local doubleWidth = width * 2

  for d = 1, length * width do
    if d % doubleWidth == 0
      or d % doubleWidth == 1 then
      t.turnRight()
    elseif d % doubleWidth == width
      or d % doubleWidth == width + 1 then
      t.turnLeft()
    end
    -- (l, w) is the position relative to the start. (0,1)
    local l = intDiv(d - 1, width) + 1
    local w = ((d - 1) % width) + 1
    if l % 2 == 0 then
      w = width - w + 1
    end
    func(l, w, d)
    -- Skip the last step.
    if d < length * width then
      t.dig()
      t.forward()
    end
  end
end



-- Return to starting position after zigzagging.
local function zigzagReturn(length, width)
  -- Again, two degenerate cases.
  if length == 1 and width == 1 then
    -- No movement needed.
    return
  end

  if width == 1 then
    -- Just back up the length.
    for _ = 1, length - 1 do
      t.back()
    end
    return
  end
  
  if length % 2 == 0 then
    -- if the length is even, we end up facing forward,
    -- directly in front of the starting position.
    for _ = 1, length - 1 do
      t.back()
    end
  else
    -- If the length is odd, we end up face forward
    -- in the opposite corner.
    t.turnLeft()
    for _ = 1, width - 1 do
      t.forward()
    end
    t.turnRight()
    for _ = 1, length - 1 do
      t.back()
    end
  end
end

local function digDown(depth)
  if depth == "bedrock" then
    -- Distance moved
    local d = 0
    while t.digDown() do
      d = d + 1
      t.down()
    end
    for _ = 1, d do
      t.up()
    end
  else
    for _ = 1, depth do
      t.digDown()
      t.down()
    end
    for _ = 1, depth do
      t.up()
    end
  end
end

local length = tonumber(arg[1])
local width = tonumber(arg[2])
local depth = tonumber(arg[3]) or "bedrock"

print("Excavating " .. length .. "x" .. width)

if length == nil or width == nil then
  print("Test: nexcavate <length> <width>")
  return
end

local function drill(length, width, dist)
  digDown(depth)
end

-- Move into the starting position.
t.dig()
t.forward()

zigzag(length, width, drill)
zigzagReturn(length, width)

-- Move back from the starting position.
t.back()
