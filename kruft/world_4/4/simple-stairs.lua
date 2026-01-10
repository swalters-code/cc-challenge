-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg
-- Written for CC:Tweaked

-- Simple script to dig stairs downwards, placing
-- stair blocks and torches as it goes.

-- Fuel in slot 16.
-- Stairs or torches anywhere in the inventory.

local distance = tonumber(arg[1]) or 10
local direction = "down" -- TODO: Negative distances are up.
local torchInterval = 4
local stairWidth = 5

local t = turtle

-- A set with valid stair block names.
local stairBlockNames = {
  ["minecraft:oak_stairs"] = true,
  ["minecraft:spruce_stairs"] = true,
  ["minecraft:birch_stairs"] = true,
  ["minecraft:jungle_stairs"] = true,
  ["minecraft:acacia_stairs"] = true,
  ["minecraft:dark_oak_stairs"] = true,
  ["minecraft:stone_brick_stairs"] = true,
  ["minecraft:stone_stairs"] = true,
  ["minecraft:cobblestone_stairs"] = true,
  ["minecraft:brick_stairs"] = true,
  ["minecraft:nether_brick_stairs"] = true,
  ["minecraft:sandstone_stairs"] = true,
  ["minecraft:red_sandstone_stairs"] = true,
  ["minecraft:quartz_stairs"] = true,
  ["minecraft:andesite_stairs"] = true,
  ["minecraft:diorite_stairs"] = true,
  ["minecraft:granite_stairs"] = true,
}

-- A set with valid torch names.
local torchBlockNames = {
  ["minecraft:torch"] = true,
  ["minecraft:redstone_torch"] = true,
  ["minecraft:soul_torch"] = true,
  ["minecraft:lantern"] = true,
  ["minecraft:soul_lantern"] = true,
}

local function findStairSlot()
  for slot = 1, 15 do
    t.select(slot)
    local itemDetail = t.getItemDetail()
    if itemDetail ~= nil
      and stairBlockNames[itemDetail.name]
    then
      return slot
    end
  end
  return nil
end

local function findTorchSlot()
  for slot = 1, 15 do
    t.select(slot)
    local itemDetail = t.getItemDetail()
    if itemDetail ~= nil
      and torchBlockNames[itemDetail.name]
    then
      return slot
    end
  end
  return nil
end

for depth = 1, distance do
  t.digDown()
  t.down()
  for _ = 1, stairWidth do
    t.dig()
    t.forward()
  end
  t.back()
  -- Maybe place a torch
  if (depth - 2) % torchInterval == 0 then
    local torchSlot = findTorchSlot()
    if torchSlot ~= nil then
      t.select(torchSlot)
      t.placeUp()
    else
      print("No torches found in inventory")
    end
  end
  for _ = 1, stairWidth - 2 do
    t.back()
  end
  t.turnLeft()
  t.turnLeft()
  local stairSlot = findStairSlot()
  if stairSlot ~= nil then
    t.select(stairSlot)
    t.place()
  else
    print("No stair blocks found in inventory")
  end
  t.turnLeft()
  t.turnLeft()
end
