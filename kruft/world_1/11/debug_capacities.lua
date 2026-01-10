-- Diagnostic Script for Resource Capacities
-- Output is saved to "capacity_log.txt"

local filename = "capacity_log.txt"
local file = fs.open(filename, "w")

local function log(text)
    print(text)
    file.writeLine(text)
end

-- Same resource config as your main program
local RESOURCES = {
    {
        label = "Uraninite",
        drawer = "functionalstorage:ender_drawer_3",
        items = {
            ["powah:uraninite"]=true, 
            ["ftbmaterials:uranium_ingot"]=true
        }, 
    },
    {
        label = "Coal",
        drawer = "functionalstorage:ender_drawer_4",
        items = {["minecraft:coal"]=true},
    },
    {
        label = "Redstone",
        drawer = "functionalstorage:ender_drawer_1",
        items = {["minecraft:redstone"]=true},
    },
    {
        label = "Snowballs",
        drawer = "functionalstorage:ender_drawer_0",
        items = {["minecraft:snowball"]=true},
    },
    {
        label = "Seeds",
        drawer = "functionalstorage:ender_drawer_2",
        items = {["chicken_roost:chicken_food_tier_8"]=true}, 
    }
}

log("=== RESOURCE CAPACITY SCAN ===")
log("Time: " .. os.clock())

-- 1. Find Roosts/Feeders
local buffers = {}
for _, name in ipairs(peripheral.getNames()) do
    local type = peripheral.getType(name) or ""
    if string.find(type, "roost") or string.find(type, "feeder") then
        table.insert(buffers, peripheral.wrap(name))
    end
end
log("Found " .. #buffers .. " roost/feeder buffers.")

-- 2. Analyze Each Resource
for _, res in ipairs(RESOURCES) do
    log("--------------------------------------------------")
    log("ANALYZING: " .. res.label)
    
    local totalCount = 0
    local totalLimit = 0
    
    -- A. Check Primary Drawer
    if peripheral.isPresent(res.drawer) then
        local drawer = peripheral.wrap(res.drawer)
        local size = drawer.size()
        local drawerCount = 0
        local drawerLimit = 0
        
        for slot = 1, size do
            -- Get Limit for this slot
            local limit = drawer.getItemLimit(slot)
            
            -- Get Item details
            local item = drawer.getItemDetail(slot)
            
            -- Logic:
            -- If the drawer slot is empty, we assume it COULD hold the item (Drawer usually dedicated).
            -- If it has an item, we check if it matches.
            
            if item then
                if res.items[item.name] then
                    drawerCount = drawerCount + item.count
                    drawerLimit = drawerLimit + limit
                end
            else
                -- Empty slot in a dedicated drawer: assume it counts towards capacity?
                -- Functional Storage usually exposes 1 giant slot per item.
                -- We'll blindly add limit if it's a single-slot drawer or similar.
                -- Safest bet: Just add limit.
                drawerLimit = drawerLimit + limit
            end
        end
        
        log(string.format("  Drawer (%s): %d / %d", res.drawer, drawerCount, drawerLimit))
        totalCount = totalCount + drawerCount
        totalLimit = totalLimit + drawerLimit
    else
        log("  Drawer (" .. res.drawer .. "): NOT FOUND")
    end
    
    -- B. Check Roosts/Feeders
    local bufferCount = 0
    local bufferLimit = 0
    
    for _, buf in ipairs(buffers) do
        local size = buf.size()
        for slot = 1, size do
            local item = buf.getItemDetail(slot)
            
            -- For generic buffers, we ONLY count the capacity of slots that CURRENTLY hold the item.
            -- We cannot assume an empty slot is "reserved" for this specific item.
            if item and res.items[item.name] then
                bufferCount = bufferCount + item.count
                bufferLimit = bufferLimit + buf.getItemLimit(slot)
            end
        end
    end
    
    log(string.format("  Buffers (Roosts/Feeders): %d / %d", bufferCount, bufferLimit))
    totalCount = totalCount + bufferCount
    totalLimit = totalLimit + bufferLimit
    
    -- C. Result
    log(string.format("  >> TOTAL: %d / %d", totalCount, totalLimit))
    if totalLimit > 0 then
        local pct = (totalCount / totalLimit) * 100
        log(string.format("  >> PERCENT: %.2f%%", pct))
    else
        log("  >> PERCENT: 0% (No Capacity Found)")
    end
end

log("--------------------------------------------------")
log("=== SCAN COMPLETE ===")
file.close()
print("Log saved to " .. filename)
