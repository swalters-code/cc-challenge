-- scan_inventories.lua
-- Scans all attached peripherals, identifies inventories, and logs contents to a file.

local logFile = "inventory_scan.log"
local file = fs.open(logFile, "w")

if not file then
    error("Could not open log file for writing.")
end

print("Scanning peripherals...")
file.writeLine("=== Peripheral Inventory Scan ===")
file.writeLine("Timestamp: " .. os.epoch("utc"))
file.writeLine("")

local peripherals = peripheral.getNames()
local inventoryCount = 0

for _, name in ipairs(peripherals) do
    local p = peripheral.wrap(name)
    
    -- Check if the peripheral is an inventory by looking for standard item storage methods
    if p.size and p.list then
        inventoryCount = inventoryCount + 1
        print("Found inventory: " .. name)
        
        file.writeLine("--------------------------------------------------")
        file.writeLine("Peripheral: " .. name)
        file.writeLine("Type: " .. peripheral.getType(name))
        file.writeLine("Size: " .. p.size() .. " slots")
        file.writeLine("Contents:")
        
        local items = p.list()
        local isEmpty = true
        
        for slot, item in pairs(items) do
            isEmpty = false
            -- item contains .name, .count, and sometimes .nbt
            file.writeLine(string.format("  Slot %d: %dx %s", slot, item.count, item.name))
        end
        
        if isEmpty then
            file.writeLine("  (Empty)")
        end
        file.writeLine("")
    end
end

file.writeLine("==================================================")
file.writeLine("Scan complete. Found " .. inventoryCount .. " inventories.")
file.close()

print("Scan complete.")
print("Log written to /" .. logFile)
