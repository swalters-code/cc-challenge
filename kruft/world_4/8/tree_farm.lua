-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg
-- Written for CC:Tweaked
-- A restartable tree farm.

-- TODO: Rename "completing" to "returning"
-- TODO: Refueling behavior.
-- TODO: Choose to produce charcoal or logs.
-- TODO: Have a boot-up message.
-- TODO: Have an informational screen.
-- TODO: Have it do inventory management during furnaced state.
-- TODO: Clear out inventory after other management done.
-- TODO: Report fuel level and usage.
-- TODO: Add code to detect what features to use. (E.g. Produce charcoal or save logs)
-- TODO: Implement a "validating" state.
-- TODO: Implement a setup process to place the
--       furnace, chest, and slab. Have it, if
--       possible, prime the furnace with
--       fuel. Otherwise complain and wait for
--       fuel.


-- If you're using oak trees, place a slab, fence
-- or glass 6 to 8 blocks above the sapling to
-- prevent large oak growth.

-- Logs in slot 1, saplings slot 2, fuel slot 16.
-- While waiting, there is a furnace below the turtle
-- and a chest behind the turtle.

-- STATE SUMMARY
--
-- STARTUP:  ORIENTING
--   orienting  - Detect what's below and route to
--                appropriate orientation state.
--   airborne   - Descend until above furnace.
--   treed      - Descend tree to reach ground.
--   furnaced   - Find chest, face away from it.
--   grounded   - Search adjacent blocks for
--                furnace

-- NORMAL OPERATION
--   idle       - Plant sapling, wait for tree.
--   upwards    - Ascend tree, clear leaves.
--   downwards  - Descend tree, harvest logs.
--   completing - Collect items, manage furnace,
--                refuel, return to idle.

local t = turtle
local idleTime = 20

-- These will probably not change, but make the
-- code clearer.
local fuelSlot = 16
local logSlot = 1
local saplingSlot = 2
local furnaceSide = "bottom"
local chestSide = "front"

-- Define some sets, many uses for these.
local saplingSet = {
  ["minecraft:oak_sapling"] = true,
  ["minecraft:spruce_sapling"] = true,
  ["minecraft:birch_sapling"] = true,
  ["minecraft:jungle_sapling"] = true,
  ["minecraft:acacia_sapling"] = true,
  ["minecraft:dark_oak_sapling"] = true
}

local logSet = {
  ["minecraft:oak_log"] = true,
  ["minecraft:spruce_log"] = true,
  ["minecraft:birch_log"] = true,
  ["minecraft:jungle_log"] = true,
  ["minecraft:acacia_log"] = true,
  ["minecraft:dark_oak_log"] = true,
  ["minecraft:stripped_oak_log"] = true,
  ["minecraft:stripped_spruce_log"] = true,
  ["minecraft:stripped_birch_log"] = true,
  ["minecraft:stripped_jungle_log"] = true,
  ["minecraft:stripped_acacia_log"] = true,
  ["minecraft:stripped_dark_oak_log"] = true,
}

local chestTypes = {
  ["minecraft:chest"] = true,
  ["minecraft:trapped_chest"] = true,
  -- Add your modded chest types here.
}

local furnaceTypes = {
  ["minecraft:furnace"] = true,
  -- Add your modded furnace types here.
}

--   State: orienting
--     Known position:  Nothing is known about where
--     the turtle is.
--
--     Objective: Determine what is below the
--     turtle and transition to the appropriate
--     sub-state.
--
--     1. Detect the block below.
--     2. If furnace, transition to "furnaced".
--     3. If nothing/air, transition to "airborne".
--     4. If log, transition to "treed".
--     5. Otherwise, transition to "searching".
local FSM = {}
FSM.state = "orienting"
FSM["orienting"] = function()
  local success, data = t.inspectDown()
  if success then
    if furnaceTypes[data.name] then
      return "furnaced"
    end
    t.select(logSlot)
    if t.compareDown() then
      return "treed"
    else
      return "searching"
    end
  end
  return "airborne"
end

--   State: airborne
--     Known position: The turtle is in the air
--     with nothing below it.
--
--     Objective:  Descend until above a furnace.
--
--     1. Move down until a furnace is detected
--        below.
--     2. Transition to "furnaced".
FSM["airborne"] = function()
  while true do
    local success, data = t.inspectDown()
    if success then
      if furnaceTypes[data.name] then
        return "furnaced"
      end
    end
    t.down()
  end
end

--   State: treed
--   Known position: The turtle is above a log
--     (in a tree).
--
--   Objective: Descend the tree trunk to reach
--     the ground.
--
--     1. Dig forward, turn left.
--     2. Dig forward, turn left.
--     3. Dig forward, turn left.
--     4. Dig forward, turn left.
--     5. Dig down, move down.
--     6. Check if there is a log below.
--     7. If yes, repeat from step 1.
--     8. If no, transition to "searching".
FSM["treed"] = function()
  for _ = 1, 4 do
    t.dig()
    t.turnLeft()
  end
  t.digDown()
  t.down()
  local success, data = t.inspectDown()
  if success then
    t.select(logSlot)
    if t.compareDown() then
      return "treed"
    end
    return "searching"
  end
  -- How did this happen?
  error("No block found below while descending tree")
end

--   State: furnaced
--     Known position: The turtle is above a
--     furnace.
--
--     Objective:  Find the chest adjacent to the
--     furnace and face away from it.
--
--     1. Turn until a chest is detected on one
--        side.
--     2. Turn 2 times to face away from the chest.
--     3. Transition to "idle".
FSM["furnaced"] = function()
  for _ = 1, 4 do
    local success, data = t.inspect()
    if success then
      if chestTypes[data.name] then
        t.turnRight()
        t.turnRight()
        return "idle"
      end
    end
    t.turnLeft()
  end
  error("No chest found next to furnace")
end

--   State: searching
--   Known position: The turtle is
--     above a block that is not a furnace or log,
--     the furnace is adjacent to one of the blocks
--     that is below the turtle.
--
--   Objective: Look for the furnace in each of
--     the cardinal directions
FSM["searching"] = function()
  for _ = 1, 4 do
    t.forward()
    local success, data = t.inspectDown()
    if success then
      if furnaceTypes[data.name] then
        t.turnRight()
        t.turnRight()
        return "idle"
      end
    end
    t.back()
    t.turnLeft()
  end
  -- give up
  error("No furnace found adjacent")
end

-- NORMAL OPERATION

--   State: idle
--     Known position:   The turtle is above the
--     furnace, facing away from the chest.
--
--     Objective: Plant a sapling and wait for it
--     to grow into a tree.

FSM["idle"] = function()
  t.select(saplingSlot)
  t.place()
  t.select(logSlot)
  if t.compare() then
    t.digUp()
    t.up()
    return "upwards"
  end
  sleep(idleTime)
  return "idle"
end

--   State: upwards
--     Known position: The turtle is adjacent to a
--     log (tree trunk), facing the log.
--
--     Objective:   Ascend the tree while clearing
--     leaves on three sides and above.
--
--     1. Turn left, dig forward.
--     2. Turn left, dig forward.
--     3. Turn left, dig forward.
--     4. Turn left, dig up.
--     5. Check if there is a log adjacent.
--     6. If yes:
--        a. Move up.
--        b. Repeat from step 1.
--     7. If no:
--        a.  Dig forward, move forward.
--        b. Transition to "downwards".
FSM["upwards"] = function()
  for _ = 1, 3 do
    t.turnLeft()
    t.dig()
  end
  t.turnLeft()
  t.digUp()
  t.up()
  t.select(logSlot)
  if t.compare() then
    return "upwards"
  end
  t.dig()
  t.forward()
  return "downwards"
end

--   State: downwards
--     Known position: The turtle is above the tree
--     trunk.
--
--     Objective:  Descend through the tree,
--     harvesting logs and clearing leaves.
--
--     1. Check if there is a log below.
--     2. If yes:
--        a.  Dig forward, turn left.
--        b. Dig forward, turn left.
--        c. Dig forward, turn left.
--        d. Dig forward, turn left.
--        e. Dig down, move down.
--        f.  Repeat from step 1.
--     3. If no, transition to "completing".
FSM["downwards"] = function()
  t.select(logSlot)
  if t.compareDown() then
    for _ = 0, 3 do
      t.dig()
      t.turnLeft()
    end
    t.digDown()
    t.down()
    return "downwards"
  end
  return "completing"
end

--   State: completing
--     Known position: The turtle is at ground
--     level, facing away from the chest and
--     furnace (chest is 2 blocks back, furnace is
--     1 block back and down).
--
--     Objective: Collect dropped items, deposit
--     logs, manage furnace, organize inventory,
--     refuel, and return to farming position.

FSM["completing"] = function()
  for _ = 1, 3 do
    t.suck()
    t.turnLeft()
  end
  t.suck()
  t.turnRight()
  -- Facing towards the chest and furnace.
  t.forward()
  -- Above furnace, facing chest.
  t.turnLeft()
  t.suck()
  t.turnLeft()
  t.turnLeft()
  t.suck()
  t.turnLeft()
  -- Manage inventory, furnace, and fuel.

  -- Much of this code is inefficient in its
  -- blindness, relying on blind attempts to move
  -- instead of tests.
  -- TODO: Make inventory management smarter.

  -- Consolidate all the saplings in turtle inventory.
  -- Refuel on sticks and excess saplings while doing so.
  for i = 1, 16 do
    if i ~= saplingSlot then
      t.select(i)
      t.transferTo(saplingSlot)
      local itemDetail = t.getItemDetail(i)
      if itemDetail
        and (saplingSet[itemDetail.name]
          or itemDetail.name == "minecraft:stick")
      then
        t.select(i)
        t.refuel()
      end
    end
  end

  -- Deposit logs into chest
  t.select(logSlot)
  local logCount = t.getItemCount(logSlot)
  -- Only add logs in increments of 8 for efficiency.
  -- Leave at least one log for comparisons.
  t.drop(math.floor((logCount - 1) / 8) * 8)

  -- Hook up to the chest and furnace.
  -- Use a do block to limit scope of variables and
  -- ensure peripherals are released.
  do
    local chest = peripheral.wrap(chestSide)
    assert(chest, "No chest detected in front")
    local furnace = peripheral.wrap(furnaceSide)
    assert(furnace, "No furnace detected below")
    local furnaceInputSlot = 1
    local furnaceFuelSlot = 2
    local furnaceOutputSlot = 3
    -- Empty the furnace output.
    furnace.pushItems(chestSide, furnaceOutputSlot)
    for i, item in pairs(chest.list()) do
      if logSet[item.name] then
        chest.pushItems(furnaceSide, i, 64, furnaceInputSlot)
      elseif item.name == "minecraft:charcoal" then
        chest.pushItems(furnaceSide, i, 64, furnaceFuelSlot)
      end
    end
    -- Ensure that slot 1 of the chest is charcoal.
    local chestSlot1Dets = chest.getItemDetail(1)
    if chestSlot1Dets
      and chestSlot1Dets.name ~= "minecraft:charcoal"
    then
      -- move the whatever to another slot.
      for j = 2, chest.size() do
        local otherItem = chest.getItemDetail(j)
        if not otherItem then
          chest.pushItems(chestSide, 1, 64, j)
          break
        end
      end
    end
    -- Move charcoal to slot 1 of the chest.
    for k, item in pairs(chest.list()) do
      if item.name == "minecraft:charcoal" then
        chest.pushItems(chestSide, k, 64, 1)
      end
    end
    -- Pull in charcoal to fuel slot, refueling then pull in more.
    t.select(fuelSlot)
    local fuelSpace = t.getItemSpace(fuelSlot)
    if fuelSpace > 0 then
      t.suck(fuelSpace)
    end
    -- Refuel if needed.
    local fuelLevel = t.getFuelLevel()
    while fuelLevel < 320 do
      t.refuel(1)
      fuelLevel = t.getFuelLevel()
      fuelSpace = t.getItemSpace(fuelSlot)
      if fuelSpace > 0 then
        t.suck(fuelSpace)
      end
    end
  end
  print("Fuel level: " .. t.getFuelLevel())

  -- Return to farming position.
  t.turnRight()
  t.turnRight()
  return "idle"
end

local state = "orienting"

while true do
  local oldState = FSM.state
  FSM.state = FSM[FSM.state]()
  if FSM.state ~= oldState then
    print("Transition: " .. oldState .. " -> " .. FSM.state)
  end
end
