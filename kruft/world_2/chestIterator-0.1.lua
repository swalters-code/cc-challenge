-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals textutils rednet os peripheral

-- Written for CC:Tweaked

-- For debugging:
local pretty = require("cc.pretty")

-- Pretty-print a data structure to the screen
-- luacheck: ignore pp unused
local  function pp(data)
  textutils.pagedPrint(pretty.render(pretty.pretty(data),51))
end

-- luacheck: ignore time unused
local function time(fn, ...)
  local start = os.epoch("local")
  local ret = {pcall(fn, ...)}
  local elapsed = os.epoch("local") - start
  return elapsed / 1000.0, table.unpack(ret)
end

-- Configuration

--- The type for peripheral names
---@alias peripheralName string

-- Class from the CC:Tweaked peripheral API
-- defined at https://github.com/nvim-computercraft/lua-ls-cc-tweaked

--- A wrapped peripheral that supports the Inventory API
---@alias wrappedInventoryPeripheral ccTweaked.peripheral.Inventory

---@class inventoryBank
---@field peripherals wrappedInventoryPeripheral[]
---@field names peripheralName[]
---@field index table<string, chestStackRecord[]>?

---@param peripheralNames peripheralName[]
---@return inventoryBank
local function makeInventoryBank(peripheralNames)
  ---@type inventoryBank
  local bank = {
    peripherals = {},
    names = peripheralNames,
    index = nil
  }

  for _, chestName in ipairs(bank.names) do
    table.insert(bank.peripherals, peripheral.wrap(chestName))
  end
  return bank
end

local inputBank = 
makeInventoryBank({
  "ironchest:obsidian_chest_2"
})

local storageBank =
makeInventoryBank({
  "ironchest:diamond_chest_0",
  "ironchest:diamond_chest_1",
  "ironchest:diamond_chest_2",
  "ironchest:diamond_chest_3",
  "ironchest:diamond_chest_4",
  "ironchest:diamond_chest_5",
  "ironchest:diamond_chest_6",
  "ironchest:diamond_chest_7",
  "ironchest:diamond_chest_8",
  "ironchest:diamond_chest_9",
  "ironchest:diamond_chest_10",
  "ironchest:diamond_chest_11",
  "ironchest:diamond_chest_12",
  "ironchest:diamond_chest_13",
  "ironchest:diamond_chest_14",
  "ironchest:diamond_chest_15"
})

for _, chestName in ipairs(storageBank.names) do
  -- FIXME: handle errors during wrapping.
  table.insert(storageBank.peripherals, peripheral.wrap(chestName))
end


--- iterate through all the items of the given inventory peripherals.
--- Assume that inventoryPeriphs is a sparse array.
---@param inventoryPeriphs wrappedInventoryPeripheral[] A sparse array of inventory peripherals
---@return fun(): wrappedInventoryPeripheral|nil, integer|nil, table|nil
local function inventoryListIterator(inventoryPeriphs)
  ---@type integer
  local chestIndex = 1
  ---@type number|nil
  local slotIndex = nil
  ---@type table|nil
  local slotItem = nil
  ---@type table|nil
  local chestList = nil
  return function()
    while inventoryPeriphs[chestIndex] do
      if not inventoryPeriphs[chestIndex] then
        return nil
      end

      if not chestList then
        chestList = inventoryPeriphs[chestIndex].list()
      end
      -- list method returns a sparse table, so we need to
      -- use the next function to iterate through it.
      slotIndex, slotItem = next(chestList, slotIndex)
      if slotIndex then
        -- found an item
        return inventoryPeriphs[chestIndex], slotIndex, slotItem
      else
        -- move to next chest
        chestIndex = chestIndex + 1
        chestList = inventoryPeriphs[chestIndex] and
          inventoryPeriphs[chestIndex].list() or {}
        slotIndex = nil
      end
    end
  end
end

-- luacheck: ignore buildChestIndex unused
--- Create an index of the items in a chest,
--- mapping item names to a list of
--- {slot number, count} pairs.
---@param chest wrappedInventoryPeripheral An inventory peripheral
---@return table<string, {[1]:integer, [2]:integer}[]>
local function buildChestIndex(chest)
  ---@type table<string, {[1]:integer, [2]:integer}[]>
  local index = {}
  ---@type table<integer, table>
  local stacks = chest.list()
  -- TODO: Write more robust error handling
  if not stacks then
    return {}
  end
  for slot, item in pairs(stacks) do
    if index[item.name] == nil then
      -- first occurrence of this item
      index[item.name] = {{slot, item.count}}
    else
      table.insert(
        index[item.name],
        {slot, item.count})
    end
  end
  return index
end

---@alias chestStackRecord {[1]:integer, [2]:integer, [3]:integer}

-- luacheck: ignore indexChestsStacks unused
--- Create an index of the items in a list of chests
---@param chests wrappedInventoryPeripheral[] A list of inventory peripherals
---@return chestStackRecord[] A mapping from item names to lists of
local function indexChestsStacks(chests)
  local index = {}
  for chestIdx, chest in pairs(chests) do
    print(peripheral.getName(chest))
    local stacks = chest.list()
    if not stacks then
      return index
    end
    for slot, item in pairs(stacks) do
      if index[item.name] == nil then
        -- first occurrence of this item
        index[item.name] = {{chestIdx, slot, item.count}}
      else
        table.insert(
          index[item.name],
          {chestIdx, slot, item.count})
      end
    end
  end
  return index
end

-- Move items of a particular type to a slot in a
-- destination inventory.

-- @param srcPeriphs wrappedPeripheral[] A list of source inventory peripherals
-- @param srcStacks table A list of whose elements
--              are {inventory index, slot number, count}
-- @param destName string An inventory peripheral name
-- @param destSlot int A slot number in destPeriph
-- @return table<integer, {wrappedPeripheral, integer, integer}> a list of any items remaining after the move.
local function moveItems(srcPeriphs, srcStacks, destPeriph, destSlot)
  -- the updated srcStacks to return
  local destName = peripheral.getName(destPeriph)
  local remainingSrcStacks = {}
    for _, stackInfo in pairs(srcStacks) do
      ---@type wrappedInventoryPeripheral
      local srcPeriph = srcPeriphs[stackInfo[1]]
      ---@type integer
      local srcSlot = stackInfo[2]
      ---@type integer
      local srcCount = stackInfo[3]
      -- TODO: write a safe-push that handles errors.

      -- attempt to push items from this stack.
      local pushedCount = srcPeriph.pushItems(
        destName,
        srcSlot,
        srcCount,
        destSlot)

      local remainingCount = srcCount - pushedCount
      if remainingCount > 0 then
        table.insert(
          remainingSrcStacks,
          { srcPeriph, srcSlot, remainingCount })
      end
    end
  return remainingSrcStacks
end


----------------------------------------------------

-- luacheck: ignore testInventoryListIterator unused
local function testInventoryListIterator()
  local items = {}
  -- luacheck: ignore invPeriph slotIndex slotItem
  for invPeriph, slotIndex, slotItem in
    inventoryListIterator(storageChests) do
    if items[slotItem.name] == nil then
      items[slotItem.name] = slotItem.count
    else
      items[slotItem.name] = items[slotItem.name] + slotItem.count
    end
  end
  return items
end

local function testMoveItems()
  -- build a list of stacks of "minecraft:dirt"
  local index = indexChestsStacks({ inputChests[1] })
  local dirtStacks = index["minecraft:dirt"]
  local result = moveItems(inputChests, dirtStacks, storageChests[1], 1)

  print("Returned:")
  pp(result)
end

pp(indexChestsStacks({inputChests[1]})["minecraft:dirt"])

testMoveItems()

pp(peripheral.getName(inputChests[1]))

