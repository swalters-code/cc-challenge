-- Script to test single-threaded vs. parallel inventory operations
-- Assumes a peripheral (e.g., chest) is attached to the "back" side.
-- Run this on a computer next to an inventory peripheral.

local peripheral_side = "functionalstorage:storage_controller_0"
local inv = peripheral.wrap(peripheral_side)
if not inv then
    error("No peripheral found on side '" .. peripheral_side .. "'")
end

-- Function to perform single-threaded operations
local function singleThreadedTest()
    local start = os.clock()
    local items = inv.list()  -- Get list of items
    local details = {}
    for slot, _ in pairs(items) do
        details[slot] = inv.getItemDetail(slot)  -- Get details for each slot
    end
    local end_time = os.clock()
    return (end_time - start) * 20, details
end

-- Function to perform parallel operations
local function parallelTest()
    local start = os.clock()
    local items = inv.list()  -- Get list of items
    local details_parallel = {}
    
    -- Create a list of functions, one per slot
    local functions = {}
    for slot, _ in pairs(items) do
        table.insert(functions, function()
            details_parallel[slot] = inv.getItemDetail(slot)
        end)
    end
    
    -- Run all functions in parallel
    parallel.waitForAll(table.unpack(functions))
    
    local end_time = os.clock()
    return (end_time - start) * 20, details_parallel
end

-- Run tests
print("Testing single-threaded approach...")
local single_time, single_details = singleThreadedTest()
print("Single-threaded time: " .. string.format("%.4f", single_time) .. " ticks")
print("Number of slots processed: " .. #single_details)

print("\nTesting parallel approach...")
local parallel_time, parallel_details = parallelTest()
print("Parallel time: " .. string.format("%.4f", parallel_time) .. " ticks")
print("Number of slots processed: " .. #parallel_details)

-- Compare results
print("\nComparison:")
if single_time > parallel_time then
    print("Parallel was faster by " .. string.format("%.4f", single_time - parallel_time) .. " ticks")
elseif parallel_time > single_time then
    print("Single-threaded was faster by " .. string.format("%.4f", parallel_time - single_time) .. " ticks")
else
    print("Times were equal")
end

-- Verify results are the same (basic check)
local match = true
for slot, detail in pairs(single_details) do
    if parallel_details[slot] == nil or parallel_details[slot].name ~= detail.name then
        match = false
        break
    end
end
print("Results match: " .. tostring(match))

