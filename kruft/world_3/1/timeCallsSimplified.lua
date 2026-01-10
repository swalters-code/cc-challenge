-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-

--[[

Demonstrate how to speed up API calls that interact
with the Minecraft world.  These calls pause
execution until the next tick.  Through the use of
the parallel API, we can batch calls together to
reduce overall wait time.

The process involves two steps:

1. Build up a list of functions that perform the
API call and add the result to a table.

2. Use parallel.waitForAll to run these functions
in parallel.

This allows multiple API calls to be executed in
the next tick.

Be cautious not to overwhelm the system with too
many processes.  I found the limit to be a hair
above 900 threads.  Past that, your ComputerCraft
computer will hang.  I suggest staying well below
that limit so that other processes on the same
computer have room to batch calls as well.

--]]


-- Takes a list of wrapped inventory peripherals
-- and their names. Returns a nested table mapping
-- peripheral names to tables that map slot numbers
-- to the results of getItemDetail for that slot.
-- e.g. allDetails["ironchest:diamond_chest_0"][1]
-- gives the item detail for slot 1 of the
-- "ironchest:diamond_chest_0" peripheral.
local function getAllDetails(peripherals, names)
  -- Parallel fetch list() for all peripherals.

  -- A list of functions that each fetch the
  -- results of list() for a peripheral.
  local listFunctions = {}
  -- Where we collect the results of the list calls.
  local allLists = {}
  for i, periph in ipairs(peripherals) do
    -- Create a function to fetch the list for this
    -- peripheral and add it to listFunctions.
    table.insert(
      listFunctions,
      -- An anonymouse function to add the results of
      -- list to allLists
      function() allLists[i] = periph.list() end
    )
  end

  -- Run all of the functions from listFunctions
  -- in parallel
  parallel.waitForAll(table.unpack(listFunctions))

  -- Next fetch details for each slot in parallel
  -- (per peripheral)

  -- Where we collect the results of getItemDetail.
  -- It is a nested table mapping peripheral names
  -- to tables mapping slot numbers to item detail
  -- tables.
  local allDetails = {}
  -- Walk through each peripheral.
  for i, periph in ipairs(peripherals) do
    local periphName = names[i]

    -- Initialize the table for this peripheral
    allDetails[periphName] = {}
    -- A list of functions that each fetch item
    -- details for one of the slot in this
    -- peripheral.
    local detailFunctions = {}
    -- Walk through each slot in this peripheral.
    for slot, _ in pairs(allLists[i]) do
      -- Create a function to fetch the item detail
      -- for this slot and add it to detailFunctions.
      table.insert(
        detailFunctions,
        function()
          -- Fetch the item details and add it to
          -- the allDetails table.
          allDetails[periphName][slot] = periph.getItemDetail(slot)
        end)
    end
    -- Run all of the detail functions in parallel
    parallel.waitForAll(table.unpack(detailFunctions))
  end
  return allDetails
end

--------------------------------------------------
--- Demonstrtation code
--------------------------------------------------

-- List of peripheral names
local peripheralNames = {
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
}

-- Wrap the peripherals
local peripherals = {}
for _, name in ipairs(peripheralNames) do
  table.insert(peripherals, peripheral.wrap(name))
end

-- Time the parallel version
local startTime = os.clock()
local allDetails = getAllDetails(peripherals, peripheralNames)
local endTime = os.clock()
local elapsedSeconds = endTime - startTime
local elapsedTicks = elapsedSeconds * 20

-- Count the number of slots processed.
local slotsCount = 0
for _, periphDetails in pairs(allDetails) do
  for _ in pairs(periphDetails) do
    slotsCount = slotsCount + 1
  end
end
print("Fetched all details (parallel) in "
  .. string.format("%.4f", elapsedSeconds)
  .. " seconds (" .. string.format("%.4f", elapsedTicks)
  .. " ticks) for " .. slotsCount .. " slots.")
print("Slots per tick: "
  .. string.format("%.4f", slotsCount / elapsedTicks))

-- For comparison, do the same with a naive
-- single-threaded approach.
allDetails = {}

startTime = os.clock()
-- Walk through each peripheral.
for i, periph in ipairs(peripherals) do
  local perName = peripheralNames[i]
  -- Initialize the table for this peripheral.
  allDetails[perName] = {}
  -- Fetch the item list for this peripheral.
  local itemList = periph.list()
  -- Walk through each slot.
  for slot, _ in pairs(itemList) do
    -- Fetch the item detail for this slot.
    allDetails[perName][slot] = periph.getItemDetail(slot)
  end
end
endTime = os.clock()
elapsedSeconds = endTime - startTime
elapsedTicks = elapsedSeconds * 20

-- Count the number of slots processed.
slotsCount = 0
for _, periphDetails in pairs(allDetails) do
  for _ in pairs(periphDetails) do
    slotsCount = slotsCount + 1
  end
end

print("Fetched all details (single-threaded) in "
  .. string.format("%.4f", elapsedSeconds)
  .. " seconds (" .. string.format("%.4f", elapsedTicks)
  .. " ticks) for " .. slotsCount .. " slots.")
print("Slots per tick: "
  .. string.format("%.4f", slotsCount / elapsedTicks))
