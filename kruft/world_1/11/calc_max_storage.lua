-- calc_max_storage.lua
-- Calculates the theoretical maximum storage capacity for system resources
-- based on the limits of slots currently holding those items.

local logFile = "max_storage.log"
local file = fs.open(logFile, "w")

-- Map Item IDs to your Display Categories
-- "Uranium" and "Uraninite" are combined as requested.
local resourceMap = {
    ["powah:uraninite"] = "Uraninite",
    ["ftbmaterials:uranium_ingot"] = "Uraninite", -- Pre-conversion source
    
    ["minecraft:coal"] = "Coal",
    ["minecraft:redstone"] = "Redstone",
    ["minecraft:snowball"] = "Snowballs", -- Solid Coolant
    ["chicken_roost:chicken_food_tier_8"] = "Chicken Food"
}

local maxCapacities = {
    ["Uraninite"] = 0,
    ["Coal"] = 0,
    ["Redstone"] = 0,
    ["Snowballs"] = 0,
    ["Chicken Food"] = 0
}

print("Calculating max storage capacities...")
file.writeLine("=== Max Storage Capacity Calculation ===")
file.writeLine("Timestamp: " .. os.epoch("utc"))
file.writeLine("")

local peripherals = peripheral.getNames()

for _, name in ipairs(peripherals) do
    local p = peripheral.wrap(name)
    
    -- Check if valid inventory
    if p.size and p.getItemLimit and p.list then
        local items = p.list()
        local inventorySize = p.size()
        
        -- We loop through every slot in the inventory
        for slot = 1, inventorySize do
            local item = items[slot]
            
            if item then
                local category = resourceMap[item.name]
                
                if category then
                    -- Get the max limit for this specific slot (handles drawers vs chests)
                    local limit = p.getItemLimit(slot)
                    maxCapacities[category] = maxCapacities[category] + limit
                    
                    -- Optional: Log details for verification
                    -- file.writeLine(string.format("Found %s in %s slot %d. Limit: %d", category, name, slot, limit))
                end
            end
        end
    end
end

file.writeLine("--- Final Totals ---")
for category, total in pairs(maxCapacities) do
    local line = string.format("%-15s : %d", category, total)
    print(line)
    file.writeLine(line)
end

file.close()
print("Results written to " .. logFile)
