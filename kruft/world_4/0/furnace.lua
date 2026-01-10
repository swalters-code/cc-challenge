-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg sleep peripheral
-- Written for CC:Tweaked

-- A simple furnace management script for computers.
-- TODO: Add fuel management.
-- TODO: Add "keep 1 in output slot" option. (for XP)

-- Configurable parameters
local inputChestSide = "left"
local outputChestSide = "right"
local furnaceSide = "back"

local fuelSlot = 1
local inputSlot = 2
local outputSlot = 3

local inputChest = peripheral.wrap(inputChestSide)
assert(inputChest ~= nil, "No peripheral found on " .. inputChestSide)
local outputChest = peripheral.wrap(outputChestSide)
assert(outputChest ~= nil, "No peripheral found on " .. outputChestSide)
local furnace = peripheral.wrap(furnaceSide)
assert(furnace ~= nil, "No peripheral found on " .. furnaceSide)

-- Get current item being smelted
local function getCurrentItem()
  return furnace.getItemDetail(inputSlot)
end



while true do
    -- Try to put the first available item into the
  -- furnace
  local l = inputChest.list()
  for k, _ in pairs(inputChest.list()) do
    print("Trying to insert from slot " .. k)
    local try = inputChest.pushItems(furnaceSide, k, 64, fuelSlot)
    if try > 0 then
      break
    end
  end

  if l == nil then
    print("No items to smelt. Waiting...")
    sleep(5)
  end

  furnace.pushItems(outputChestSide, outputSlot, 64)
  sleep(1)

end
