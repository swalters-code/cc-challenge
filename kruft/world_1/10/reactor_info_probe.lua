-- Reactor Method Probe Script v3
-- Outputs to file for easy reading

local reactor = peripheral.wrap("top")
local outputFile = "reactor_info_probe.out"

if not reactor then
    print("No reactor found on top!")
    return
end

-- Open file for writing
local file = fs.open(outputFile, "w")

local function output(text)
    text = text or ""
    file.writeLine(text)
    print(text)  -- Also show on screen
end

output("=== Reactor Method Probe v3 ===")
output("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
output("")

-- Helper function to format return values
local function formatValue(value, indent)
    indent = indent or 0
    local prefix = string.rep("    ", indent)
    
    if type(value) == "table" then
        local result = "{\n"
        for k, v in pairs(value) do
            if type(v) == "table" then
                result = result .. prefix .. "    [" .. tostring(k) .. "] = " .. formatValue(v, indent + 1)
            else
                result = result .. prefix .. "    " .. tostring(k) .. " = " .. tostring(v) .. "\n"
            end
        end
        result = result .. prefix ..  "}\n"
        return result
    else
        return tostring(value)
    end
end

-- Simple methods (no arguments)
output("=== Simple Methods ===")
output("")

local simpleMethods = {
    "getEnergy",
    "getStoredEnergy",
    "getMaxEnergy",
    "getEnergyCapacity",
    "isRunning",
    "getTemperature",
    "getFuel",
    "getCarbon",
    "getRedstone",
    "getUraniniteSlot",
    "getCarbonSlot",
    "getRedstoneSlot",
    "size",
    "list",
    "tanks",
}

for _, methodName in ipairs(simpleMethods) do
    output("--- " .. methodName ..  "() ---")
    local success, result = pcall(function()
        return peripheral.call("top", methodName)
    end)
    if success then
        output(formatValue(result))
    else
        output("ERROR: " ..  tostring(result))
    end
    output("")
end

-- Test getItemDetail for each slot
output("=== getItemDetail (per slot) ===")
output("")
for slot = 1, 5 do
    output("Slot " .. slot .. ":")
    local success, result = pcall(function()
        return peripheral.call("top", "getItemDetail", slot)
    end)
    if success then
        if result then
            output(formatValue(result))
        else
            output("    (empty)")
        end
    else
        output("    ERROR: " .. tostring(result))
    end
end
output("")

-- Test getItemLimit for each slot
output("=== getItemLimit (per slot) ===")
output("")
for slot = 1, 5 do
    local success, result = pcall(function()
        return peripheral.call("top", "getItemLimit", slot)
    end)
    if success then
        output("Slot " .. slot .. ": " .. tostring(result))
    else
        output("Slot " .. slot .. ": ERROR - " .. tostring(result))
    end
end

-- Close the file
file.close()

print("")
print("Output written to: " .. outputFile)
print("Use 'edit " .. outputFile .. "' to view")
