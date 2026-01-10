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

-- Utility functions
-- TODO: Move these to a library file.

--- Check if a table is empty
---@param t table
---@return boolean
local function isEmpty(t) return next(t) == nil end

--- Check if a value is nil
---@param v any
---@return boolean
local function isNil(v)
    return v == nil
end

-- Return true if a value is mapped to any keys in a table.
---@param tbl table
---@param val any
---@return boolean
local function Contains(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

-- Configuration

--- The type for peripheral names
---@alias peripheralName string

-- Class from the CC:Tweaked peripheral API
-- defined at https://github.com/nvim-computercraft/lua-ls-cc-tweaked

--- A wrapped peripheral that supports the Inventory API
---@alias wrappedInventoryPeripheral ccTweaked.peripheral.Inventory

---@class indexRecord
---@field perName peripheralName
---@field slot integer
---@field count integer
---@field perObj wrappedInventoryPeripheral

---@alias bankIndex table<string, indexRecord[]>  -- map itemName -> list of indexRecord

---@class inventoryBank
---@field peripherals wrappedInventoryPeripheral[]
---@field names peripheralName[]


---@param peripheralNames peripheralName[]
---@return inventoryBank
local function makeInventoryBank(peripheralNames)
  ---@type inventoryBank
  local bank = {
    peripherals = {},
    names = peripheralNames,
  }

  for _, chestName in ipairs(bank.names) do
    table.insert(bank.peripherals, peripheral.wrap(chestName))
  end
  return bank
end

--- iterate through all the items of the given inventoryBank
--- This is essentially an analog of the list() method for a single chest.
---@param bank inventoryBank An inventory bank
---@return fun(): peripheralName?, integer?, table?, wrappedInventoryPeripheral?
local function inventoryBankIterator(bank)
  ---@type integer
  local invIdx = 1
  ---@type integer?
  local slotIdx = nil
  ---@type table?
  local slotItem = nil
  ---@type table<integer, table>
  local stacks = bank.peripherals[invIdx].list()

  return function()
      slotIdx, slotItem = next(stacks, slotIdx)
      while slotIdx == nil do
        -- move to the next inventory
        invIdx = invIdx + 1
            if not bank.peripherals[invIdx] then
                -- no more inventories
                return nil, nil, nil, nil
            end
        stacks = bank.peripherals[invIdx].list()
        slotIdx, slotItem = next(stacks, nil)
      end
      return bank.names[invIdx], slotIdx, slotItem, bank.peripherals[invIdx]
  end
end

local function buildBankIndex(bank)
  local index = {}
  for pName , slot, item, perObj in 
    inventoryBankIterator(bank) do
        if index[item.name] == nil then
            index[item.name] = {}
        end
        table.insert(
          index[item.name],
          { slot = slot,
            count = item.count,
            perObj = perObj,
            perName = pName })
  end
  return index
end





-- Move items from inputBank into slots of storageBank inventories that already contain the item.
--
-- For each stack in inputBank, move items only into storageBank inventories
-- that already contain at least one of that item:
-- - Fill partial stacks first (slots in those inventories that already hold the item).
-- - Then use other slots within those same inventories as needed.
-- - Do not touch inventories that contain zero of the item type.
-- - Any items remaining after all eligible slots are filled stay in inputBank and
--   are included in the returned index.

---@param inputBank inventoryBank
---@param storageBank inventoryBank
---@return bankIndex bankIndex mapping itemName -> array of indexRecord describing leftover
---                         stacks remaining in inputBank ({ perName, slot, count, perObj }).
local function storeItems(sourceBank, storageBank)

  local inputIndex = buildBankIndex(sourceBank)

  -- Track storage inventories that contain each item.
  -- maps itemName -> array of wrappedInventoryPeripheral
  ---@type table<string, wrappedInventoryPeripheral[]>
  local storageInventoriesByItem = {}

  -- Track the names of items from inputBank that
  -- have been encountered in storageBank and which
  -- l have items to move.

  for perName, slot, item, perObj in
    inventoryBankIterator(storageBank) do
    if inputIndex[item.name] ~= nil then
      -- This storage inventory contains an item to store.
      
      -- If we have not yet recorded this inventory
      -- for this item,then add it.
      if storageInventoriesByItem[item.name] == nil then
        storageInventoriesByItem[item.name] = {}
      end
      -- Check if this inventory is already recorded.
      local alreadyRecorded = false
      for _, recordedPer in
        ipairs(storageInventoriesByItem[item.name]) do
        if recordedPer == perObj then
          alreadyRecorded = true
          break
        end
      end
end
      
    end
  end
  
  
end






----------------------------------------------------
-- Casual Testing.
----------------------------------------------------
-- Will be removed later.


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

