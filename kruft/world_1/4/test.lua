-- ME Bridge 0.7 - Test pushItems from backpack
-- Start fresh log

local logFile = "me_diagnostic.log"

local function log(message)
    print(message)
    local f = fs.open(logFile, "w")  -- Always start fresh
    f.writeLine(message)
    f.close()
    -- Append for subsequent writes
    local oldLog = log
    log = function(msg)
        print(msg)
        local f = fs.open(logFile, "a")
        f.writeLine(msg)
        f.close()
    end
    log(message)  -- Re-log the first message
end

log("=== Backpack pushItems Test ===")
log("Date: " .. os.date())

-- Get peripherals
local meBridge = peripheral.find("me_bridge")
local inventory = peripheral.wrap("top")

log("ME Bridge: " .. peripheral.getName(meBridge))
log("Backpack: " .. peripheral.getName(inventory))

-- Check initial state
log("\n--- Initial State ---")
local slot1 = inventory.getItemDetail(1)
if slot1 then
    log("Backpack slot 1: " .. slot1.name .. " x" .. slot1.count)
end

-- Get brick count in ME
local success, meItem = pcall(meBridge.getItem, {name = "minecraft:brick"})
if success and meItem and meItem.amount then
    log("ME system has: " .. meItem.amount .. " bricks")
else
    log("Could not get brick count from ME: " .. tostring(meItem))
    meItem = nil
end

-- Try pushing from backpack to ME Bridge directly
log("\n--- Test: pushItems to ME Bridge ---")
log("Attempting: inventory.pushItems('" .. peripheral.getName(meBridge) .. "', 1, 1)")

local beforeCount = slot1.count
local success, result = pcall(inventory.pushItems, peripheral.getName(meBridge), 1, 1)

log("Success: " .. tostring(success))
log("Returned: " .. tostring(result))

local afterSlot = inventory.getItemDetail(1)
local afterCount = afterSlot and afterSlot.count or 0
log("Backpack before: " .. beforeCount .. " | after: " .. afterCount)
log("Items moved: " .. (beforeCount - afterCount))

-- Check ME again
local success2, meItemAfter = pcall(meBridge.getItem, {name = "minecraft:brick"})
if success2 and meItemAfter and meItemAfter.amount then
    log("ME system now has: " .. meItemAfter.amount .. " bricks")
    if meItem and meItem.amount then
        log("Change in ME: " .. (meItemAfter.amount - meItem.amount))
    end
else
    log("Could not get brick count after: " .. tostring(meItemAfter))
end

log("\n=== Test Complete ===")
