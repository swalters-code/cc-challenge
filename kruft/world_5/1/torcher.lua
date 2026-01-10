-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg
-- Place torches in a grid 4 apart.
-- Written for CC:Tweaked

-- TODO: Add support for different spacing.
-- TODO: Add support for different grid shapes (rectangles).
-- TODO: Add support for refueling.
-- TODO: Add support for returning to start.
-- TODO: Add support for different torch types.

local spacing = 4
local gridSize = tonumber(arg[1]) or 4 -- On chunk
gridSize = gridSize - 1
local t = turtle
local fuelSlot = 16
-- Move above everything.
local travelUp = 3

for _ = 1, travelUp do
  t.up()
end

-- Start at (0,0), placing the torch there.
-- move forward then right in a zig-zag over the grid.
-- A distance of 4 would result in 5 torches in each direction.
-- At each position where a torch belongs, drop down and place it.

-- Every slot is a torch slot.
local torchSlot = nil
local function placeTorch()
  if torchSlot == nil
    or t.getItemCount(torchSlot) == 0 then
    -- Find a torch slot
    for slot = 1, 16 do
      t.select(slot)
      local itemDetail = t.getItemDetail()
      if itemDetail ~= nil
        and itemDetail.name == "minecraft:torch" then
        torchSlot = slot
        break
      end
    end
  end
  if torchSlot == nil then
    error("No torches found in inventory")
  end
  t.placeDown()
end

local function dropTorch()
  -- Travel all the way down to the ground.
  local distanceDropped = 0
  while not t.inspectDown() do
    t.down()
    distanceDropped = distanceDropped + 1
  end
  t.up()
  placeTorch()
  -- Travel back up.
  print(distanceDropped)
  for _ = 1, distanceDropped - 1 do
    t.up()
  end
end

-- Go spacing units forward.
local function goForwardSpacing()
  for _ = 1, spacing do
    t.forward()
  end
end

-- For each line.

local turnDirection = "right"
for x = 0, gridSize + 1 do
  -- Travel one row.
  for _ = 0, gridSize do
    dropTorch()
    goForwardSpacing()
  end
  dropTorch()
  -- Turn and go to the next row.
  if x == gridSize + 1 then
    break
  end
  if turnDirection == "right" then
    t.turnRight()
    goForwardSpacing()
    t.turnRight()
    turnDirection = "left"
  else
    t.turnLeft()
    goForwardSpacing()
    t.turnLeft()
    turnDirection = "right"
  end
end


