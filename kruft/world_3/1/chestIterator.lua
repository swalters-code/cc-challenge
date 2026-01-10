-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals textutils rednet os peripheral
-- Written for CC:Tweaked


--- The type for peripheral names
---@alias peripheralName string

-- Class from the CC:Tweaked peripheral API
-- defined at https://github.com/nvim-computercraft/lua-ls-cc-tweaked

--- A wrapped peripheral that supports the Inventory API
---@alias wrappedInventoryPeripheral ccTweaked.peripheral.Inventory

---@class indexRecord
---@field perName peripheralName
---@field slot integer
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

-- Concatenate two inventory banks into a new one.
---@param bankA inventoryBank
---@param bankB inventoryBank
---@return inventoryBank
local function joinInventoryBanks(bankA, bankB)
  ---@type inventoryBank
  local bank = {
    peripherals = {},
    names = {},
  }

  for _, chestName in ipairs(bankA.names) do
    table.insert(bank.names, chestName)
    table.insert(bank.peripherals, peripheral.wrap(chestName))
  end

  for _, chestName in ipairs(bankB.names) do
    table.insert(bank.names, chestName)
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
            {
              slot = slot,
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

---@param sourceBank inventoryBank
---@param storageBank inventoryBank
local function storeItems(sourceBank, storageBank)

  local inputIndex = buildBankIndex(sourceBank)

  -- Track storage inventories that contain each item.
  -- maps itemName -> a set of peripherNames
  -- indicating that this inventory contains at
  -- least one of the item.

  ---@type table<string, table<peripheralName, boolean>>
  local storageInventoriesByItem = {}

  -- Track the names of items from inputBank that
  -- have been encountered in storageBank and which
  -- have items to move.

  for dstPerName, dstSlotNum, dstItem, _ in
    inventoryBankIterator(storageBank) do
        local dstItemName = dstItem.name
        if inputIndex[dstItemName] ~= nil then
            -- This storage inventory contains an item to store.

            -- If we have not yet recorded this inventory
            -- for this item,then add it.
            if storageInventoriesByItem[dstItemName] == nil then
                storageInventoriesByItem[dstItemName] = {}
            end

            storageInventoriesByItem[dstItemName][dstPerName] = true

            local dstSlotFull = false
            -- Try to move items from inputBank into this slot.
            for _, srcRecord in ipairs(inputIndex[dstItemName]) do
                if dstSlotFull then
                    -- This slot is full, move on to the next storage slot.
                    break
                end
                local srcPer = srcRecord.perObj
                local srcSlotNum = srcRecord.slot
                local srcCount = srcRecord.count
                if srcCount > 0 then
                    local movedCount = srcPer.pushItems(
                        dstPerName,
                        srcSlotNum,
                        srcCount,
                        dstSlotNum)

                    if movedCount < srcCount then
                        -- the destination is full, move on to the next storage slot.
                        dstSlotFull = true
                    end
                    -- All items moved, remove this record
                    -- table.remove(inputIndex[dstItemName], k)
                    srcRecord.count = srcCount - movedCount
                end
                -- continue on to the next source slot
            end
            -- There may be more available space in
            -- dstSlotNum, so try the next source slot.
        end
  end

  -- Now, try to move items into other slots

  for _ , srcSlotNum, srcItem, srcPerObj in
    inventoryBankIterator(sourceBank) do
    local srcItemName = srcItem.name
    local dstInventories =
      storageInventoriesByItem[srcItemName]
    if dstInventories ~= nil then
      -- There are storage inventories that contain this item.
      for dstPerName, _ in pairs(dstInventories) do
        local movedCount =
              srcPerObj.pushItems(
                dstPerName,
                srcSlotNum)
        if movedCount == srcItem.count then
          -- All items moved, break out.
          break
        else
          -- Update the remaining count in inputIndex
          srcItem.count = srcItem.count - movedCount
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
  "ironchest:obsidian_chest_3"
})

local chestBank =
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
  "ironchest:diamond_chest_15",
  "ironchest:diamond_chest_16",
  "ironchest:diamond_chest_17",
  "ironchest:diamond_chest_18",
  "ironchest:diamond_chest_19",
  "ironchest:diamond_chest_20",
  "ironchest:diamond_chest_21",
  "ironchest:diamond_chest_22",
  "ironchest:diamond_chest_23",
  "ironchest:diamond_chest_24",
  "ironchest:diamond_chest_25",
  "ironchest:diamond_chest_26",
  "ironchest:diamond_chest_27",
  "ironchest:diamond_chest_28",
  "ironchest:diamond_chest_29",
  "ironchest:diamond_chest_30",
  "ironchest:diamond_chest_31",
  "ironchest:diamond_chest_32",
  "ironchest:diamond_chest_33",
  "ironchest:diamond_chest_34",
  "ironchest:diamond_chest_35",
  "ironchest:diamond_chest_36",
  "ironchest:diamond_chest_37",
  "ironchest:diamond_chest_38",
  "ironchest:diamond_chest_39",
  "sophisticatedbackpacks:backpack_1",
  "sophisticatedbackpacks:backpack_2"
})

local drawerBank =
makeInventoryBank(
  { "functionalstorage:storage_controller_0" }
  )

-- Try the drawers first.
local storageBank =
  joinInventoryBanks(drawerBank, chestBank)

-- luacheck: ignore time unused
local function time(fn, ...)
  local start = os.epoch("local")
  local ret = {pcall(fn, ...)}
  local elapsed = os.epoch("local") - start
  return elapsed / 1000.0, table.unpack(ret)
end


print(time(storeItems, inputBank, storageBank))
print(time(storeItems, chestBank, drawerBank))

