-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg sleep peripheral
-- Written for CC:Tweaked

-- A simple furnace management script for computers.
-- TODO: Add fuel management.
-- TODO: Add "keep 1 in output slot" option. (for XP)

-- Configurable parameters
local inputChestSide = "left"
local outputChestSide = "right"
local furnaceSide = "top"
local fuelSide = "back"


local fuelSlot = 2
local inputSlot = 1
local outputSlot = 3

local inputChest = peripheral.wrap(inputChestSide)
assert(inputChest ~= nil, "No peripheral found on " .. inputChestSide)
local outputChest = peripheral.wrap(outputChestSide)
assert(outputChest ~= nil, "No peripheral found on " .. outputChestSide)
local furnace = peripheral.wrap(furnaceSide)
assert(furnace ~= nil, "No peripheral found on " .. furnaceSide)
local fuelInventory = peripheral.wrap(fuelSide)
assert(fuelInventory ~= nil, "No peripheral found on " .. fuelSide)

-- Get current item being smelted
local function getCurrentItem()
  return furnace.getItemDetail(inputSlot)
end



while true do
  -- Try to put the first available item into the
  -- furnace
  local l = inputChest.list()
  for k, _ in pairs(inputChest.list()) do
    local try = inputChest.pushItems(furnaceSide, k, 64, inputSlot)
    if try > 0 then
      break
    end
  end

  -- Load fuel.
  local fuel = furnace.getItemDetail(fuelSlot)
  if fuel == nil or fuel.count < 64 then
    local fuelName = furnace.getItemDetail(fuelSlot)
    if fuelName ~= nil then
      fuelName = fuelName.name
    end
    local fuelSourceSlot = nil
    local fuelItems = fuelInventory.list()
    for k, v in pairs(fuelItems) do
      if fuelName == nil or fuelName == v.name then
        fuelSourceSlot = k
        break
      end
    end
    if fuelSourceSlot ~= nil then
      fuelInventory.pushItems(furnaceSide, fuelSourceSlot, 64, fuelSlot)
    else
      print("No fuel available!")
    end
  end
  
  if l == nil then
    print("No items to smelt. Waiting...")
    sleep(5)
  end

  furnace.pushItems(outputChestSide, outputSlot, 64)
  sleep(1)

end
