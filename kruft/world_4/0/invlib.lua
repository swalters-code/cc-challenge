-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel
-- Written for CC:Tweaked

-- A library of utility functions for inventory
-- peripherals.

-- These are functionality I keep re-implementing.

local invlib = {}

-- Like the list method, but returns full item details.
-- This is a rather expensive operation, taking as
-- many ticks as there are stacks in the inventory.
-- For a Sophisticated Storage netherite chest,
-- with 268 slots, that can take up to 13.4
-- seconds.
---@param invPeriph ccTweaked.peripheral.wrappedPeripheral An inventory peripheral.
---@return ccTweaked.peripheral.item[] A table of item details, indexed by slot.
local function detailsList(invPeriph)
  assert(invPeriph.list ~= nil, "Peripheral does not support list method")

  ---@type ccTweaked.peripheral.item[]
  local details = {}

  for slot, _ in pairs(invPeriph.list()) do
    details[slot] = invPeriph.getItemDetail(slot)
  end
  return details
end

-- A parallelized version of detailsList.
-- Too many parallel calls can cause the computer
-- to hang.
---@param inv ccTweaked.peripheral.wrappedPeripheral An inventory peripheral.
local function pDetailsList(inv)
  assert(inv.list ~= nil, "Peripheral does not support list method")

  ---@type ccTweaked.peripheral.item[]
  local details = {}
  -- Functions to be called in parallel.
  local pFuncs = {}

  for slot, _ in pairs(inv.list()) do
    table.insert(pFuncs,
      function()
        details[slot] = inv.getItemDetail(slot)
      end)
  end
  -- Run all the calls in the next tick.
  parallel.waitForAll(table.unpack(pFuncs))
  return details
end

-- Find the first occurrence of an item in an
-- inventory.
---@param invPeriph ccTweaked.peripheral.wrappedPeripheral An inventory peripheral.
---@param itemName string The item name to search for.
local function findItem(invPeriph, itemName)
  assert(invPeriph.list ~= nil, "Peripheral does not support list method")

  for slot, item in pairs(invPeriph.list()) do
    if item.name == itemName then
      return slot, item
    end
  end
  return nil, nil
end

-- Find the first empty slot in an inventory.
---@param invPeriph ccTweaked.peripheral.wrappedPeripheral An inventory peripheral.
---@return integer? The first empty slot number, or nil if none found.
local function findEmptySlot(invPeriph)
  assert(invPeriph.list ~= nil, "Peripheral does not support list method")

  local list = invPeriph.list()
  for slot = 1, invPeriph.size() do
    if list[slot] == nil then
      return slot
    end
  end
  return nil
end

-- Find the last empty slot in an inventory.
local function findLastEmptySlot(invPeriph)
  assert(invPeriph.list ~= nil, "Peripheral does not support list method")

  local list = invPeriph.list()
  for slot = invPeriph.size(), 1, -1 do
    if list[slot] == nil then
      return slot
    end
  end
  return nil
end

-- Find the first unassigned index in an array.
-- Useful for when you've already cached a list
-- of items.
local function findFirstUnassignedIndex(arr)
  local index = 1
  while arr[index] ~= nil
  do
    index = index + 1
  end
  return index
end

-- Move the first available item from one to another.
-- Like pushItem, but just selects the first item.
---@param fromPeriph ccTweaked.peripheral.wrappedPeripheral The source inventory peripheral.
---@param toName string The name of the destination peripheral.
---@param toSlot number? The slot number in the destination peripheral.
---@param count number? The number of items to move.
---@return number? The number of items moved.
local function moveFirstItem(fromPeriph, toName, toSlot, count)
  assert(fromPeriph.list ~= nil, "Peripheral does not support list method")

  local list = fromPeriph.list()
  for slot = 1, fromPeriph.size() do
    if list[slot] ~= nil then
      -- Found an item.
      return fromPeriph.pushItems(toName, slot, count, toSlot)
    end
  end
  return nil
end

-- Try to move every item to the destination.
-- Use for feeding items to a machine.
-- Will stop when the destination slot, if
-- provided, is full.
---@param fromPeriph ccTweaked.peripheral.wrappedPeripheral The source inventory peripheral.
---@param toName string The name of the destination peripheral.
---@param slot number? The slot number in the destination peripheral.
---@param count number? The number of items to move.
---@return integer The total number of items moved.
local function moveAllItems(fromPeriph, toName, slot, count)
  assert(fromPeriph.list ~= nil, "Peripheral does not support list method")

  ---@type integer The total number of items moved so far.
  local movedItems = 0
  ---@type integer? The remaining space in the destination slot.
  local spaceRemaining = nil
  if slot ~= nil then
    local toPeriph = peripheral.wrap(toName)
    assert(toPeriph ~= nil,
      "No peripheral found for " .. toName)
    spaceRemaining = toPeriph.getItemLimit(slot)
  end
  local list = fromPeriph.list()
  for fromSlot = 1, fromPeriph.size() do
    if spaceRemaining ~= nil
      and spaceRemaining <= 0
    then
      break
    end
    if list[fromSlot] ~= nil then
      -- Found an item.
      local pushedCount =
        fromPeriph.pushItems(
          toName,
          fromSlot,
          count,
          slot)
      if spaceRemaining ~= nil then
        spaceRemaining = spaceRemaining - pushedCount
      end
      movedItems = movedItems + pushedCount
    end
  end
  return movedItems
end

-- Arrange an inventory based on a function.
-- Given a function that takes an item or
-- itemDetail record, arrange the inventory based
-- on the slot number returned.

-- Assumptions:
--   * No two items will be assigned to the same slot.
--   * The slotFunc will not send two items to the same slot.
--     (in reality, this will just cause duplicates
--     to be bunched up at the end of the
--     inventory)
---@param invPeriph ccTweaked.peripheral.wrappedPeripheral An inventory peripheral.
---@param slotFunc fun(item: ccTweaked.peripheral.item): integer A function that takes an item detail record and returns the desired slot number.
local function arrangeInventory(invPeriph, slotFunc)
  assert(invPeriph.list ~= nil, "Peripheral does not support list method")

  ---@type string The name of the inventory peripheral.
  local invName = peripheral.getName(invPeriph)


  -- Since we work from front to back, always
  -- moving items to their final location and track
  -- visited slots, details will never become
  -- stale.  Any out of date entries will already
  -- be in the visited set.

  ---@type ccTweaked.peripheral.item[] A table of item details, indexed by slot.
  local details = detailsList(invPeriph)
  ---@type integer The size of the inventory.
  local invSize = invPeriph.size()
  -- Find an empty slot.
  ---@type integer The first empty slot.
  local emptySlot = findFirstUnassignedIndex(details)
  if emptySlot > invSize then
    return nil, "Inventory is full, cannot arrange"
  end
  print("Using empty slot " .. emptySlot .. " for arrangement")
  ---@type boolean Flag for emptySlot usage.
  local usedEmptySlot = false

  -- A set of visited slots.
  ---@type table<number, boolean>
  local visitedSlots = {}
  -- Send each stack to where it belongs, recursively moving stacks if the target is blocked.

  -- Recursively move items to the slot they belong in.
  ---@param fromSlot integer The slot to move from.
  ---@param seenSlots table<number, boolean> A set of slots already seen in this chain.
  local function moveToSlot(fromSlot, seenSlots)
    seenSlots[fromSlot] = true
    -- print the seenSlots table
    -- print("Seen slots: ")
    -- for slot, _ in pairs(seenSlots) do
    --   io.write(slot .. " ")
    -- end
    -- io.write("\n")
    print("slotFunc says item in slot " .. fromSlot ..
      " should go to slot " ..
      slotFunc(details[fromSlot]))
    if slotFunc(details[fromSlot]) == fromSlot then
      -- Already in the right slot.
      print("Item in slot " .. fromSlot ..
        " is already in the correct slot")
      visitedSlots[fromSlot] = true
      return
    end

    local targetSlot = slotFunc(details[fromSlot])
    if details[targetSlot] == nil
    then
      print("Moving item from slot " .. fromSlot ..
        " to empty target slot " .. targetSlot)
      -- The target slot is empty, move it there.
      local moved = invPeriph.pushItems(
        invName,
        fromSlot,
        999999,
        targetSlot)
      print("Moved " .. moved .. " items from slot " ..
        fromSlot .. " to slot " .. targetSlot)
      
    end
  end
  -- TODO: walk through the slots.
  for slot = 1, invSize do
    if details[slot] ~= nil
      and not visitedSlots[slot]
    then
      moveToSlot(slot, {})
      if usedEmptySlot then
        -- Move the stack in the empty slot to where it belongs.
        local moved = invPeriph.pushItems(
          invName,
          emptySlot,
          99999,
          slot)
        print("Moved " .. moved .. 
          " items from empty slot " .. emptySlot ..
          " to slot " .. slot)
      else
        -- If the empty slot was unused, use the current slot.
        -- This keeps the empty slot marching backwards.
        print("Empty slot is now " .. slot)
        emptySlot = slot
      end
    end
  end
end

invlib.detailsList = detailsList
invlib.pDetailsList = pDetailsList
invlib.findItem = findItem
invlib.moveFirstItem = moveFirstItem
invlib.moveAllItems = moveAllItems
invlib.findEmptySlot = findEmptySlot
invlib.findLastEmptySlot = findLastEmptySlot
invlib.findFirstUnassignedIndex = findFirstUnassignedIndex
invlib.arrangeInventory = arrangeInventory

return invlib
