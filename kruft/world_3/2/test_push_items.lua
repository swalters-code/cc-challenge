-- pushAllItems.lua
-- Moves everything from left chest to right chest and logs every peripheral.call

local LOG_FILE = "pushItems.log"
local LEFT_CHEST = "left"
local RIGHT_CHEST = "right"

-- Clear old log
if fs.exists(LOG_FILE) then
    fs.delete(LOG_FILE)
end

local function log(msg)
    local f = fs.open(LOG_FILE, "a")
    if f then
        f.writeLine(msg)
        f.close()
    end
    print(msg) -- also print to console
end

log("=== pushAllItems.lua started at " .. os.date("%Y-%m-%d %H:%M:%S") .. " ===")

-- Check peripherals
if not peripheral.isPresent(LEFT_CHEST) then
    log("ERROR: No peripheral on left!")
    return
end
if not peripheral.getType(LEFT_CHEST) == "minecraft:chest" and peripheral.getType(LEFT_CHEST) ~= "minecraft:shulker_box" then
    log("WARNING: Left peripheral is not a chest/shulker, but proceeding...")
end

if not peripheral.isPresent(RIGHT_CHEST) then
    log("ERROR: No peripheral on right!")
    return
end

local leftChest = peripheral.wrap(LEFT_CHEST)
local rightChest = peripheral.wrap(RIGHT_CHEST)

log("Left chest: " .. peripheral.getName(LEFT_CHEST))
log("Right chest: " .. peripheral.getName(RIGHT_CHEST))

-- Get size of left inventory
local success, size = pcall(peripheral.call, LEFT_CHEST, "size")
if not success then
    log("ERROR: Failed to call size() on left chest: " .. tostring(size))
    return
end
log("CALL: " .. LEFT_CHEST .. ':size() -> ' .. tostring(size))

for slot = 1, size do
    -- Get item detail in this slot
    local success, item = pcall(peripheral.call, LEFT_CHEST, "getItemDetail", slot)
    if success and item then
        log(string.format("Slot %d: %dx %s", slot, item.count, item.displayName or item.name))

        -- Keep pushing until slot is empty
        while true do
            local success, moved = pcall(peripheral.call, LEFT_CHEST, "pushItems", peripheral.getName(rightChest), slot, 64)
            
            local logMsg = string.format('CALL: %s:pushItems("%s", %d, 64) -> %s',
                LEFT_CHEST, peripheral.getName(rightChest), slot, tostring(moved))
            log(logMsg)

            if not success then
                log("ERROR: pushItems failed: " .. tostring(moved))
                break
            end

            if moved == 0 then
                log("Slot " .. slot .. " is now empty.")
                break
            else
                log("Moved " .. moved .. " items from slot " .. slot)
            end

            -- Small delay to avoid overwhelming the system (optional)
            os.sleep(0.05)
        end
    else
        -- Slot is empty or getItemDetail failed (normal for empty slots)
        if not success then
            -- This is expected for empty slots, suppress noisy errors
            -- log("getItemDetail failed on slot " .. slot .. " (likely empty)")
        end
    end
end

log("=== Transfer complete ===")
print("All items transferred. Log written to " .. LOG_FILE)
