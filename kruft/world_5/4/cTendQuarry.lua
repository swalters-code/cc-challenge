-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel shell
-- Written for CC:Tweaked

-- Pipe bulk items from a quarry dump chest.

local dumpChestName = "sophisticatedstorage:chest_3"
local idleTime = 30

local dumpChest = peripheral.wrap(dumpChestName)
assert(dumpChest,
  "Could not find dump chest: " .. dumpChestName)
local outputInventories = {}

-- Discover connected inventories and the item they hold.
-- Inventories connected directly to a side are invalid.
local sides = {
  ["top"] = true,
  ["bottom"] = true,
  ["front"] = true,
  ["back"] = true,
  ["left"] = true,
  ["right"] = true,
}

-- List all peripherals on the network.
local pNames = peripheral.getNames()
for _, pName in pairs(pNames) do
  if not sides[pName]
    and pName ~= dumpChestName
  then
    local w = peripheral.wrap(pName)
    if w then
      local l = w.list()
      if l then
        for _, item in pairs(l) do
          local key = item.name

          -- Assume that every item type goes to a
          -- unique inventory.
          if not outputInventories[key] then
            outputInventories[key] = pName
          end
        end
      end
    end
  end
end

for k, v in pairs(outputInventories) do
  print("Routing " .. k .. " to " .. v)
end

-- Main loop

-- Handle mismatched stack sizes.
local movedItems = false
while true do
  local items = dumpChest.list()
  movedItems = false
  if items ~= nil then
    for slot, item in pairs(items) do
      local destination = outputInventories[item.name]
      if destination then
        dumpChest.pushItems(
          destination,
          slot)
        movedItems = true
      end
    end
  end
  if not movedItems then
    sleep(idleTime)
  end
end
