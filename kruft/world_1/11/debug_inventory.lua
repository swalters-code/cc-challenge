-- Diagnostic Script for Inventory Issues
-- Output is saved to "debug_log.txt"

local filename = "debug_log.txt"
local file = fs.open(filename, "w")

local function log(text)
    print(text)
    file.writeLine(text)
end

log("=== STARTING DIAGNOSTIC SCAN ===")
log("Time: " .. os.clock())

local periphs = peripheral.getNames()
log("Found " .. #periphs .. " total peripherals.")

for _, name in ipairs(periphs) do
    local type = peripheral.getType(name) or "unknown"
    
    -- Check for Roosts or the specific Seed Drawer
    -- We check broadly for 'roost' or 'drawer' or 'storage' to catch everything
    if string.find(type, "roost") or name == "functionalstorage:ender_drawer_2" then
        log("--------------------------------------------------")
        log("Scanning: " .. name .. " [" .. type .. "]")
        
        local p = peripheral.wrap(name)
        
        if p.list then
            local success, items = pcall(p.list)
            if success and items then
                local count = 0
                for slot, item in pairs(items) do
                    log(string.format("  Slot %s: %dx %s", slot, item.count, item.name))
                    count = count + 1
                end
                if count == 0 then
                    log("  (Inventory Empty)")
                end
            else
                log("  Error: .list() failed or returned nil.")
            end
        else
            log("  Error: Peripheral has no .list() method.")
        end
    end
end

log("--------------------------------------------------")
log("=== SCAN COMPLETE ===")
file.close()
print("Log saved to " .. filename)
