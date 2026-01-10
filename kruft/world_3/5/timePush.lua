local chest1Name = "ironchest:diamond_chest_46"
local chest1 = peripheral.wrap(chest1Name)
local chest2Name = "ironchest:obsidian_chest_4"
local chest2 = peripheral.wrap(chest2Name)

sleep(5)

-- Function to time a block of code
local function timeFunc(func)
    local start = os.clock()
    func()
    return os.clock() - start
end

local size = chest1.size()
assert(size >= chest2.size(),
    "chest1 must be at least as large as chest2 for this test")

-- Parallel version: Move 6 stacks from chest1 to chest2, then back
local parallelTime = timeFunc(function()
    local pushFunctions = {}
    for i = 1, size do
        table.insert(pushFunctions,
            function() chest1.pushItems(chest2Name, i) end)
    end
    parallel.waitForAll(table.unpack(pushFunctions))

    local pushBackFunctions = {}
    for i = 1, size do
        table.insert(pushBackFunctions,
            function() chest2.pushItems(chest1Name, i) end)
    end
    parallel.waitForAll(table.unpack(pushBackFunctions))
end)

parallelTime = math.floor(parallelTime * 20 + .5) -- convert to ticks, round up.

-- Sequential version: Same process, one by one
local sequentialTime = timeFunc(function()
    for i = 1, size do chest1.pushItems(chest2Name, i) end
    for i = 1, size do chest2.pushItems(chest1Name, i) end
end)

sequentialTime = math.floor(sequentialTime * 20 + .5) -- convert to ticks, round up.

print("Parallel time: " .. parallelTime .. " ticks")
print("Sequential time: " .. sequentialTime .. " ticks")
print("Parallel is " .. (sequentialTime / parallelTime) .. "x faster")
