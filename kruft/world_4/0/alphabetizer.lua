-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep peripheral
-- Written for CC:Tweaked

-- A simple script to alphabetize the items

-- Peripheral names of inventories to alphabetize
local chestNames = {
  "left",
  "bottom",
}

-- Number of seconds to wait between checks
---@type integer
local idleTime = 5

invlib = require("invlib")

---An associative array of chest names to peripherals.
---@type ccTweaked.peripheral.wrappedPeripheral[]
local chestPeripherals = {}
-- Get an associated peripheral for each chest name
for _, chestName in pairs(chestNames) do
  local p = peripheral.wrap(chestName)
  assert(p ~= nil, "No peripheral found on " .. chestName)
  chestPeripherals[chestName] = p
end

local details = invlib.pDetailsList(chestPeripherals[chestNames[1]])

-- Make the sparse details table into a dense array
do
  local index = 1
  local tmpDetails = {}
  for _, item in pairs(details) do
    tmpDetails[index] = item
    index = index + 1
  end
  details = tmpDetails
end

table.sort(details, function(a, b)
  return a.displayName < b.displayName
                                    end)

for slot, item in pairs(details) do
  print("Slot " .. slot .. ": " .. item.displayName)
end

local function findItemSlot(itemDetail)
  for slot, item in pairs(details) do
    -- print("Comparing " .. itemDetail.displayName ..
    --   " to " .. item.displayName)
    if itemDetail.displayName == item.displayName then
      return slot
    end
  end
end

invlib.arrangeInventory(
  chestPeripherals[chestNames[1]],
  findItemSlot
)
