-- Monitor Detection Script
-- Finds monitor and reports its size

-- Check all sides for a monitor
local sides = {"top", "bottom", "left", "right", "front", "back"}
local monitor = nil
local monitorSide = nil

for _, side in ipairs(sides) do
    if peripheral.isPresent(side) then
        local pType = peripheral.getType(side)
        if pType == "monitor" then
            monitor = peripheral. wrap(side)
            monitorSide = side
            print("Found monitor on: " .. side)
        end
    end
end

-- Also check for monitors connected via wired modem
local allPeripherals = peripheral.getNames()
for _, name in ipairs(allPeripherals) do
    local pType = peripheral.getType(name)
    print("Found peripheral: " .. name ..  " (" .. pType .. ")")
    if pType == "monitor" then
        monitor = peripheral.wrap(name)
        monitorSide = name
    end
end

-- Report monitor info
if monitor then
    print("")
    print("=== Monitor Info ===")
    print("Location: " .. monitorSide)
    
    local width, height = monitor.getSize()
    print("Character size: " .. width .. " x " .. height)
    
    local textScale = monitor.getTextScale()
    print("Current text scale: " .. textScale)
    
    print("")
    print("Text scale options (0.5 to 5):")
    for scale = 0.5, 2, 0.5 do
        monitor.setTextScale(scale)
        local w, h = monitor.getSize()
        print("  Scale " .. scale .. ": " ..  w .. " x " .. h ..  " chars")
    end
    
    -- Reset to scale 1
    monitor.setTextScale(1)
    
    -- Quick test display
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Monitor OK!")
else
    print("No monitor found!")
end
