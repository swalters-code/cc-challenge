-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals textutils rednet os peripheral fs write sleep
-- luacheck: ignore 631 (disable line_too_long)
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

local threadcount = 0

-- Get all details for all slots in an inventory bank.  Returns a
-- table mapping peripheral names to tables mapping slot numbers to
-- item detail tables.
---@param bank inventoryBank
---@return table<string, table<integer, table>>
local function getAllDetails(bank)
    -- Use parallel to speed up the process

    -- A list of functions to parallel fetch list()
    ---@type function[]
    local listFunctions = {}
    local allLists = {}
    for i, periph in ipairs(bank.peripherals) do
        table.insert(listFunctions,
            function() allLists[i] = periph.list() end)
    end
    parallel.waitForAll(table.unpack(listFunctions))

    -- Now fetch details for each slot in parallel
    ---@type function[]
    local detailFunctions = {}

    ---@type table<string, table<integer, table>>
    local allDetails = {}

    for i, periph in ipairs(bank.peripherals) do
        local perName = bank.names[i]
        allDetails[perName] = {}
        for slot, _ in pairs(allLists[i]) do
            table.insert(detailFunctions,
                function()
                    allDetails[perName][slot] = periph.getItemDetail(slot)
                end)
            threadcount = threadcount + 1
        end
        parallel.waitForAll(table.unpack(detailFunctions))
        detailFunctions = {}
    end
    return allDetails
end

-- Query all the chests and write the result to a file.
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
  "sophisticatedbackpacks:backpack_2",
  "functionalstorage:storage_controller_0"
})

-- Time the function calls
local startTime = os.clock()
local allDetails = getAllDetails(chestBank)
local endTime = os.clock()
local elapsedTicks = (endTime - startTime) * 20
print("Fetched all details in " .. string.format("%.4f", elapsedTicks) .. " ticks.")

-- Count the number of slots processed.
local count = 0
for _, slots in pairs(allDetails) do
    for _, _ in pairs(slots) do
        count = count + 1
    end
end
print("Fetched details from " .. count .. " slots.")
print("Used " .. threadcount .. " threads.")


-- Now, do the same in a naive single-threaded way for comparison.

startTime = os.clock()
---@type table<string, table<integer, table>>
local allDetailsSingle = {}
for i, periph in ipairs(chestBank.peripherals) do
    local perName = chestBank.names[i]
    allDetailsSingle[perName] = {}
    local itemList = periph.list()
    for slot, _ in pairs(itemList) do
        allDetailsSingle[perName][slot] = periph.getItemDetail(slot)
    end
end
endTime = os.clock()
elapsedTicks = (endTime - startTime) * 20
print("Fetched all details single-threaded in " .. string.format("%.4f", elapsedTicks) .. " ticks.")
-- Count the number of slots processed.
count = 0
for _, slots in pairs(allDetailsSingle) do
    for _, _ in pairs(slots) do
        count = count + 1
    end
end
print("Fetched details from " .. count .. " slots.")
