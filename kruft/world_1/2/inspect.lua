-- Peripheral Inspector for CC:Tweaked
-- Inspects a peripheral and saves all method information to a file

local args = {...}

-- Get direction from arguments or prompt user
local direction = args[1]
if not direction then
    print("Usage: inspect <direction>")
    print("Example: inspect top")
    print("\nAvailable directions: top, bottom, left, right, front, back")
    return
end

-- Check if peripheral exists
if not peripheral.isPresent(direction) then
    print("No peripheral found in direction: " .. direction)
    return
end

-- Get peripheral type and wrap it
local pType = peripheral.getType(direction)
local p = peripheral.wrap(direction)

print("Inspecting " .. pType .. " in direction: " .. direction)

-- Open file for writing
local filename = pType .. "_" .. direction .. "_info.txt"
local file = fs.open(filename, "w")

file.writeLine("=== Peripheral Information ===")
file.writeLine("Type: " .. pType)
file.writeLine("Direction: " .. direction)
file.writeLine("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
file.writeLine("")

-- Get all methods
local methods = peripheral.getMethods(direction)
file.writeLine("=== Available Methods ===")
file.writeLine("Total methods: " .. #methods)
file.writeLine("")

for i, method in ipairs(methods) do
    file.writeLine(i .. ". " .. method)
end

file.writeLine("")
file.writeLine("=== Method Details ===")
file.writeLine("")

-- Try to get detailed information for common methods
for _, method in ipairs(methods) do
    file.writeLine("Method: " .. method)
    
    -- Check for inventory-related methods
    if method == "list" or method == "getItems" then
        local success, items = pcall(p[method], p)
        if success and type(items) == "table" then
            file.writeLine("  Inventory contents:")
            for slot, item in pairs(items) do
                if type(item) == "table" then
                    file.writeLine("    Slot " .. slot .. ":")
                    file.writeLine("      Name: " .. (item.name or "unknown"))
                    file.writeLine("      Count: " .. (item.count or 0))
                    file.writeLine("      Max: " .. (item.maxCount or item.max or "unknown"))
                end
            end
        end
    elseif method == "size" then
        local success, size = pcall(p[method], p)
        if success then
            file.writeLine("  Result: " .. tostring(size))
        end
    elseif method == "getTransferLocations" then
        local success, locations = pcall(p[method], p)
        if success and type(locations) == "table" then
            file.writeLine("  Transfer locations:")
            for _, loc in ipairs(locations) do
                file.writeLine("    - " .. tostring(loc))
            end
        end
    elseif method == "getInfo" or method == "info" then
        local success, info = pcall(p[method], p)
        if success and type(info) == "table" then
            file.writeLine("  Info:")
            for k, v in pairs(info) do
                file.writeLine("    " .. k .. ": " .. tostring(v))
            end
        end
    end
    
    file.writeLine("")
end

-- Additional slot-by-slot inspection if size() exists
if p.size then
    local success, invSize = pcall(p.size, p)
    if success and type(invSize) == "number" then
        file.writeLine("=== Detailed Slot Inspection ===")
        file.writeLine("Inventory size: " .. invSize)
        file.writeLine("")
        
        for slot = 1, invSize do
            -- Try different methods to get slot info
            local itemDetail = nil
            
            if p.getItemDetail then
                local ok, detail = pcall(p.getItemDetail, p, slot)
                if ok and detail then
                    itemDetail = detail
                end
            elseif p.getStackInSlot then
                local ok, detail = pcall(p.getStackInSlot, p, slot)
                if ok and detail then
                    itemDetail = detail
                end
            end
            
            if itemDetail and type(itemDetail) == "table" and itemDetail.name then
                file.writeLine("Slot " .. slot .. ":")
                file.writeLine("  Name: " .. itemDetail.name)
                file.writeLine("  Count: " .. (itemDetail.count or 0))
                file.writeLine("  Max: " .. (itemDetail.maxCount or itemDetail.max or "unknown"))
                file.writeLine("")
            end
        end
    end
end

file.close()

print("Inspection complete!")
print("Information saved to: " .. filename)
print("File location: /" .. filename)
