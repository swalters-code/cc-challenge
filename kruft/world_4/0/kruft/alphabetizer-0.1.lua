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

-- Return an equivalent to the list() method, but
-- include the full details of the items.
-- Uses parallel to speed up the process.
---@param pName string The name of the peripheral.
---@return ccTweaked.peripheral.item[] A table of item details, indexed by slot.
local function detailList(pName)
  local periph = chestPeripherals[pName]
  assert(periph ~= nil, "No peripheral found for " .. pName)
  ---@type ccTweaked.peripheral.item[]
  local details = {}
  -- Functions to be called in parallel.
  local pFuncs = {}
  for slot, _ in pairs(periph.list()) do
    table.insert(pFuncs,
                 function()
                   details[slot] = periph.getItemDetail(slot)
                 end
  end
  -- Run all the calls in the next tick.
  parallel.waitForAll(table.unpack(pFuncs))
  return details
end

---Compact chest by combining stacks and moving them to the front of the cherst (low slot number)
---@param pName string The name of the peripheral.
---@return boolean True if any items were moved.
local function compactChest(pName)
  local periph = chestPeripherals[pName]
  assert(periph ~= nil, "No peripheral found for " .. pName)

  -- An index of partial stacks by item name.
  local partialStacks = {}
 -- A list of empty slots.
local emptySlots = {}
  local movedAny = false

  for slot = 
end
