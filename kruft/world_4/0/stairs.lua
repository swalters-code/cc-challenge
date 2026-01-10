-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg
-- Dig a staircase downwards or upwards. Place stair blocks as you do.
-- Written for CC:Tweaked

-- TODO: Add support for going upwards.
-- TODO: Add support for switchbacks and spirals.
-- TODO: Handle water and lava.
-- TODO: Handle gravel and sand.

local direction = arg[1] or "down"
local distance = tonumber(arg[2]) or 1
if direction ~= "down" and direction ~= "up" then
  print("Usage: stairs <up|down> <distance>")
  return
end

local t = turtle

-- Counter to track how far we've gone for torch placement.
local layersDone = 0
local stairSlot = 1
local torchSlot = 2

local function placeTorchIfNeeded()
  if layersDone % 4 == 0 then
    t.select(torchSlot)  -- Assume torches are in slot 2
    t.placeUp()
  end
end

local function placeStairs()
  -- TODO: Adjust for orientation going up or down.
  t.turnLeft()
  t.turnLeft()
  t.select(stairSlot)  
  t.placeDown()
  t.turnLeft()
  t.turnLeft()
end
-- Dig a single layer down and place stairs and a torch.
local function digLayerDown()
  t.dig()
  t.digDown()
  t.down()
  t.dig()
  t.digDown()
  t.down()
  t.dig()
  t.digDown()
  placeStairs()
  t.forward()
  t.up()
  placeTorchIfNeeded()
  layersDone = layersDone + 1
  print("Completed layer " .. layersDone .. " of " .. distance)
end


if direction == "down" then
  for i = 1, distance do
    digLayerDown()
  end
  t.down()
  t.digDown()
  t.down()
  t.digDown()
  placeStairs()
  t.up()
  t.up()
else
  print("Staircase upwards not yet implemented.")
end
