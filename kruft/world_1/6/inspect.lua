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
local p = peripheral. wrap(direction)

print("Inspecting " .. pType .. " in direction: " .. direction)

-- Open file for writing
local filename = pType .. "_" .. direction .. "_info.txt"
local file = fs.open(filename, "w")

file.writeLine("=== Peripheral Information ===")
file.writeLine("Type: " .. pType)
file.writeLine("Direction: " ..  direction)
file.writeLine("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
file.writeLine("")

-- Get all methods
local methods = peripheral.getMethods(direction)
file.writeLine("=== Available Methods ===")
file.writeLine("Total methods: " .. #methods)
file. writeLine("")

for i, method in ipairs(methods) do
    file.writeLine(i ..  ". " .. method)
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
            file. writeLine("  Inventory contents:")
            for slot, item in pairs(items) do
                if type(item) == "table" then
                    file.writeLine("    Slot " .. slot .. ":")
                    file.writeLine("      Name: " .. (item.name or "unknown"))
                    file.writeLine("      Count: " .. (item.count or 0))
                    file. writeLine("      Max: " ..  (item.maxCount or item. max or "unknown"))
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
            file. writeLine("  Info:")
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
                file.writeLine("Slot " .. slot ..  ":")
                file.writeLine("  Name: " .. itemDetail.name)
                file.writeLine("  Count: " .. (itemDetail.count or 0))
                file.writeLine("  Max: " .. (itemDetail. maxCount or itemDetail.max or "unknown"))
                file.writeLine("")
            end
        end
    end
end

-- Tank/Fluid inspection
local hasTanks = false
if p.tanks then
    local success, tanks = pcall(p.tanks, p)
    if success and type(tanks) == "table" then
        hasTanks = true
        file.writeLine("=== Tank/Fluid Information ===")
        file. writeLine("Number of tanks: " .. #tanks)
        file.writeLine("")
        
        for i, tank in ipairs(tanks) do
            file.writeLine("Tank " .. i .. ":")
            if tank.name then
                file.writeLine("  Fluid: " .. tank.name)
            else
                file.writeLine("  Fluid: Empty")
            end
            file. writeLine("  Amount: " .. (tank.amount or 0) .. " mB")
            file.writeLine("  Capacity: " .. (tank.capacity or "unknown") .. " mB")
            if tank.capacity and tank.capacity > 0 then
                local percent = math.floor((tank.amount or 0) / tank.capacity * 100)
                file.writeLine("  Fill Level: " .. percent .. "%")
            end
            file. writeLine("")
        end
    end
end

-- Alternative fluid methods (for mods that use different APIs)
if not hasTanks then
    -- Try getFluid / getFluidInTank methods
    if p.getFluidInTank then
        file.writeLine("=== Tank/Fluid Information ===")
        local tankIndex = 0
        while true do
            local success, fluid = pcall(p.getFluidInTank, p, tankIndex)
            if not success or not fluid then break end
            
            file.writeLine("Tank " .. tankIndex .. ":")
            if fluid.name then
                file.writeLine("  Fluid: " .. fluid.name)
            else
                file.writeLine("  Fluid: Empty")
            end
            file.writeLine("  Amount: " .. (fluid. amount or 0) .. " mB")
            file.writeLine("  Capacity: " .. (fluid.capacity or "unknown") ..  " mB")
            if fluid.capacity and fluid.capacity > 0 then
                local percent = math.floor((fluid.amount or 0) / fluid.capacity * 100)
                file.writeLine("  Fill Level: " ..  percent .. "%")
            end
            file.writeLine("")
            
            tankIndex = tankIndex + 1
            if tankIndex > 100 then break end -- Safety limit
        end
        hasTanks = tankIndex > 0
    end
    
    -- Try getTankInfo (older API)
    if not hasTanks and p.getTankInfo then
        local success, tankInfo = pcall(p.getTankInfo, p)
        if success and type(tankInfo) == "table" then
            file. writeLine("=== Tank/Fluid Information ===")
            for i, tank in ipairs(tankInfo) do
                file.writeLine("Tank " .. i .. ":")
                if tank.contents then
                    file.writeLine("  Fluid: " .. (tank.contents.name or tank.contents.rawName or "unknown"))
                    file.writeLine("  Amount: " .. (tank.contents.amount or 0) .. " mB")
                else
                    file.writeLine("  Fluid: Empty")
                    file.writeLine("  Amount: 0 mB")
                end
                file.writeLine("  Capacity: " .. (tank. capacity or "unknown") .. " mB")
                if tank.capacity and tank.capacity > 0 then
                    local amount = tank.contents and tank.contents.amount or 0
                    local percent = math. floor(amount / tank.capacity * 100)
                    file.writeLine("  Fill Level: " .. percent .. "%")
                end
                file.writeLine("")
            end
        end
    end
end

-- Energy inspection
local hasEnergy = false
file.writeLine("=== Energy Information ===")

-- Try common energy methods (Forge Energy / Tech Reborn / Mekanism style)
local energyStored = nil
local energyCapacity = nil

-- Method 1: getEnergy / getEnergyCapacity (common in many mods)
if p.getEnergy then
    local success, energy = pcall(p.getEnergy, p)
    if success and type(energy) == "number" then
        energyStored = energy
        hasEnergy = true
    end
end

if p.getEnergyCapacity then
    local success, capacity = pcall(p.getEnergyCapacity, p)
    if success and type(capacity) == "number" then
        energyCapacity = capacity
    end
end

-- Method 2: getEnergyStored / getMaxEnergyStored (Forge Energy style)
if not hasEnergy and p.getEnergyStored then
    local success, energy = pcall(p.getEnergyStored, p)
    if success and type(energy) == "number" then
        energyStored = energy
        hasEnergy = true
    end
end

if not energyCapacity and p.getMaxEnergyStored then
    local success, capacity = pcall(p. getMaxEnergyStored, p)
    if success and type(capacity) == "number" then
        energyCapacity = capacity
    end
end

-- Method 3: Mekanism style (may use different units)
if not hasEnergy and p.getEnergyFilledPercentage then
    local success, percent = pcall(p.getEnergyFilledPercentage, p)
    if success and type(percent) == "number" then
        file.writeLine("Energy Fill Level: " .. string.format("%.2f", percent * 100) .. "%")
        hasEnergy = true
    end
end

if p.getMaxEnergy then
    local success, maxEnergy = pcall(p.getMaxEnergy, p)
    if success and type(maxEnergy) == "number" then
        energyCapacity = maxEnergy
    end
end

-- Method 4: Tech Reborn style
if not hasEnergy and p. getStoredPower then
    local success, power = pcall(p.getStoredPower, p)
    if success and type(power) == "number" then
        energyStored = power
        hasEnergy = true
    end
end

if not energyCapacity and p.getMaxPower then
    local success, maxPower = pcall(p. getMaxPower, p)
    if success and type(maxPower) == "number" then
        energyCapacity = maxPower
    end
end

-- Output energy information
if hasEnergy then
    if energyStored then
        file.writeLine("Energy Stored: " .. tostring(energyStored) .. " FE")
    end
    if energyCapacity then
        file.writeLine("Energy Capacity: " .. tostring(energyCapacity) .. " FE")
    end
    if energyStored and energyCapacity and energyCapacity > 0 then
        local percent = math.floor(energyStored / energyCapacity * 100)
        file. writeLine("Energy Fill Level: " .. percent .. "%")
    end
    
    -- Additional energy info (input/output rates)
    if p.getEnergyInput then
        local success, input = pcall(p.getEnergyInput, p)
        if success and type(input) == "number" then
            file. writeLine("Energy Input Rate: " .. tostring(input) .. " FE/t")
        end
    end
    
    if p.getEnergyOutput then
        local success, output = pcall(p.getEnergyOutput, p)
        if success and type(output) == "number" then
            file. writeLine("Energy Output Rate: " .. tostring(output) .. " FE/t")
        end
    end
    
    if p.getEnergyUsage then
        local success, usage = pcall(p.getEnergyUsage, p)
        if success and type(usage) == "number" then
            file.writeLine("Energy Usage: " .. tostring(usage) .. " FE/t")
        end
    end
    
    file.writeLine("")
else
    file.writeLine("No energy storage detected.")
    file.writeLine("")
end

file.close()

print("Inspection complete!")
print("Information saved to: " .. filename)
print("File location: /" .. filename)
