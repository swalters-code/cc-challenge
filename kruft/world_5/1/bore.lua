-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel shell
-- Written for CC:Tweaked

-- Mine a 1x2 tunnel of a specified length.
-- Place torches every so often and place flooring
-- blocks to that the tunnel is walkable.


-- Interval for placing torches.
local torchInterval = 4

local torchTypes = {
  ["minecraft:torch"] = true,
  ["minecraft:soul_torch"] = true,
}

local floorBlockTypes = {
  ["minecraft:polished_deepslate"] = true,
  --    ["minecraft:stone"] = true,
  --    ["minecraft:cobblestone"] = true,
}

if #arg < 1 then
  print("Usage: bore <length>")
  return
end

-- Length of the tunnel to mine.
---@type integer
local length = tonumber(arg[1])

-- Find and select a slot containing torches.
---@return integer? slot The slot number with a torch, or nil if not found.
local function findTorch()
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name == "minecraft:torch" then
      turtle.select(slot)
      return slot
    end
  end
  return nil
end

-- Find and select a slot with a block for flooring.
local function findFlooring()
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name and
      floorBlockTypes[item.name] then
      turtle.select(slot)
      return slot
    end
  end
  return nil
end

for i = 1, length do
  -- Don't dig past the end of the tunnel.
  if i ~= length then
    turtle.dig()
  end
  turtle.digUp()
  if not turtle.detectDown() then
    findFlooring()
    turtle.placeDown()
  end
  if i % torchInterval == 0 then
    findTorch()
    turtle.back()
    turtle.placeUp()
    turtle.forward()
  end
  if i ~= length then
    turtle.forward()
  end
end

turtle.turnRight()
turtle.turnRight()
for _ = 1, length do
  turtle.forward()
end
