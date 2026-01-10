-- Peripheral Finder and Inspector
-- Usage: peripherals [peripheral_name] [-exclude_prefix ...]

local args = { ... }

-- Parse arguments
local targetPeripheral = nil
local excludePrefixes = {}

for _, arg in ipairs(args) do
    if arg:sub(1, 1) == "-" then
        table.insert(excludePrefixes, arg:sub(2))
    else
        targetPeripheral = arg
    end
end

-- Function to check if a peripheral should be excluded
local function isExcluded(name)
    for _, prefix in ipairs(excludePrefixes) do
        if name:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

-- Function to print a table recursively with indentation
local function printTable(t, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    
    if type(t) ~= "table" then
        print(prefix .. tostring(t))
        return
    end
    
    for key, value in pairs(t) do
        if type(value) == "table" then
            print(prefix .. tostring(key) ..   ":")
            printTable(value, indent + 1)
        elseif type(value) == "function" then
            print(prefix .. tostring(key) ..  " (function)")
        else
            print(prefix .. tostring(key) ..   ": " .. tostring(value))
        end
    end
end

-- Function to get peripheral info
local function getPeripheralInfo(name)
    local pType = peripheral.getType(name)
    if not pType then
        return nil
    end
    
    local methods = peripheral.getMethods(name)
    local wrapped = peripheral.wrap(name)
    
    return {
        name = name,
        type = pType,
        methods = methods,
        wrapped = wrapped
    }
end

-- Function to list all peripherals
local function listAllPeripherals()
    local allPeripherals = peripheral.getNames()
    local peripherals = {}
    
    for _, name in ipairs(allPeripherals) do
        if not isExcluded(name) then
            table.insert(peripherals, name)
        end
    end
    
    if #peripherals == 0 then
        print("No peripherals found.")
        return
    end
    
    print("=== Attached Peripherals ===")
    print("")
    
    for _, name in ipairs(peripherals) do
        local pType = peripheral.getType(name)
        print(string.format("  [%s] %s", pType, name))
    end
    
    print("")
    print("Total: " .. #peripherals .. " peripheral(s)")
    print("")
    print("Tip: Run 'peripherals <name>' for details")
end

-- Function to show detailed info about a peripheral
local function showPeripheralDetails(name)
    if isExcluded(name) then
        print("Peripheral '" .. name ..  "' is excluded.")
        return
    end
    
    local info = getPeripheralInfo(name)
    
    if not info then
        print("Error: Peripheral '" .. name .. "' not found.")
        print("")
        print("Available peripherals:")
        local names = peripheral.getNames()
        for _, n in ipairs(names) do
            if not isExcluded(n) then
                print("  - " ..   n)
            end
        end
        return
    end
    
    print("=== Peripheral Details ===")
    print("")
    print("Name: " ..   info.name)
    print("Type: " .. info. type)
    print("")
    
    -- Show available methods
    print("Available Methods:")
    if info.methods and #info.methods > 0 then
        table.sort(info. methods)
        for _, method in ipairs(info.methods) do
            print("  - " ..  method .. "()")
        end
    else
        print("  (none)")
    end
    
    print("")
    
    -- Try to get additional info based on peripheral type
    print("Additional Info:")
    local wrapped = info. wrapped
    
    -- Check for common methods and display info
    if wrapped. getItemDetail then
        -- Inventory peripheral
        local size = wrapped.size and wrapped.size() or "unknown"
        print("  Inventory Size: " .. tostring(size))
    end
    
    if wrapped.getEnergy then
        -- Energy storage
        local energy = wrapped.getEnergy()
        local maxEnergy = wrapped.getEnergyCapacity and wrapped.getEnergyCapacity() or "unknown"
        print("  Energy: " .. tostring(energy) ..  " / " .. tostring(maxEnergy))
    end
    
    if wrapped.getFuelLevel then
        -- Turtle or similar
        local fuel = wrapped.getFuelLevel()
        local maxFuel = wrapped. getFuelLimit and wrapped.getFuelLimit() or "unknown"
        print("  Fuel: " .. tostring(fuel) ..  " / " .. tostring(maxFuel))
    end
    
    if wrapped.getLabel then
        local label = wrapped.getLabel()
        if label then
            print("  Label: " ..  label)
        end
    end
    
    if wrapped.getID then
        local id = wrapped.getID()
        print("  Computer ID: " .. tostring(id))
    end
    
    if wrapped.isOn then
        local status = wrapped.isOn() and "On" or "Off"
        print("  Status: " .. status)
    end
    
    if wrapped.getFrequency then
        -- Modem
        print("  Frequency: " ..  tostring(wrapped. getFrequency()))
    end
    
    if info. type == "monitor" then
        if wrapped.getSize then
            local w, h = wrapped.getSize()
            print("  Size: " ..  w .. "x" .. h)
        end
        if wrapped.isColor then
            print("  Color: " ..  (wrapped.isColor() and "Yes" or "No"))
        end
        if wrapped.getTextScale then
            print("  Text Scale: " ..  wrapped.getTextScale())
        end
    end
end

-- Main program
if targetPeripheral then
    showPeripheralDetails(targetPeripheral)
else
    listAllPeripherals()
end
