-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals textutils rednet os peripheral fs write sleep
-- luacheck: ignore 631 (disable line_too_long)
-- Written for CC:Tweaked

-- Remover - A simple item removal assistant for ComputerCraft

-- Usage:
-- remover [sleepInterval]
-- remover learn

---------------------------------------------------
--=== Configuration ===--
---------------------------------------------------
local inputChestName = "top"
local outputChestName = "back"
local itemsToRemoveFile = "items_to_remove.txt"
local sleepInterval = 0.01  -- seconds between removal attempts

---------------------------------------------------

local inputChest = peripheral.wrap(inputChestName)
assert(inputChest, "Input chest not found: " .. inputChestName)
local outputChest = peripheral.wrap(outputChestName)
assert(outputChest, "Output chest not found: " .. outputChestName)

-- A set of the names of items to remove.
--@type table<string, boolean>
local itemsToRemove = {}


-- Load items to remove from file
if fs.exists(itemsToRemoveFile) then
  itemsToRemove = dofile(itemsToRemoveFile)
else
  print("No items to remove file found. Starting with an empty list.")
end

local function removeItems()
  -- FIXME: Make this configurable
  -- Only slot 1 is output on energizing orb
  local item = inputChest.getItemDetail(1)
  if not item then return end
  if itemsToRemove[item.name] then
    print("Removing item: " .. item.name)
    local success, err = inputChest.pushItems(outputChestName, 1)
    if not success then
      print("Error removing item: " .. err)
    end
  end
end

if arg[1] ~= "learn" then
  while true do
    removeItems()
    sleep(sleepInterval)
  end
else
    print("Learning mode: Please place items to remove in the input chest.")
    print("Press any key to finish learning mode.")
    while true do
        for _, item in pairs(inputChest.list()) do
            if not itemsToRemove[item.name] then
                print("Learning to remove item: " .. item.name)
                itemsToRemove[item.name] = true
                -- Save current list
                local file = fs.open(itemsToRemoveFile, "w")
                file.write("return " .. textutils.serialize(itemsToRemove))
                file.close()
                print("Items to remove saved to " .. itemsToRemoveFile)
            end
        end
        removeItems()
        if os.pullEvent("key") then
            break
        end
        sleep(1)
    end
end
