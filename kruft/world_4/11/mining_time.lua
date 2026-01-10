-- Mining Timer and Logger Script
-- Times mining in a straight line and logs blocks mined

-- Get the distance from command line argument
local args = {...}
local distance = tonumber(args[1])

if not distance or distance < 1 then
    print("Usage: miner <distance>")
    print("Example: miner 10")
    return
end

-- Initialize variables
local blockLog = {}
local startTime = os.epoch("utc")
local totalBlocks = 0

-- Function to inspect and log a block
local function inspectAndLog(inspectFunc, direction)
    local success, data = inspectFunc()
    if success and data and data.name then
        totalBlocks = totalBlocks + 1
        if blockLog[data.name] then
            blockLog[data.name] = blockLog[data.name] + 1
        else
            blockLog[data.name] = 1
        end
        return data.name
    end
    return nil
end

-- Function to mine forward
local function mineForward()
    if turtle.detect() then
        inspectAndLog(turtle.inspect, "forward")
        turtle.dig()
    end
    turtle.forward()
end

-- Function to ensure fuel
if turtle.getFuelLevel() < distance * 2 + 2 then
    print("Warning: Low fuel! Current: " .. turtle.getFuelLevel())
    print("Press any key to continue or Ctrl+T to abort...")
    os.pullEvent("key")
end

print("Starting mining run: " .. distance .. " blocks")
print("================================")

-- Mine forward in a straight line
print("Mining forward...")
for i = 1, distance do
    mineForward()
    print("Progress: " .. i .. "/" .. distance)
end

-- Turn right, mine, move forward, turn right again
print("Turning right...")
turtle.turnRight()

if turtle.detect() then
    print("Mining block to the side...")
    inspectAndLog(turtle.inspect, "forward")
    turtle.dig()
end

turtle.forward()
print("Turning right again...")
turtle.turnRight()

-- Mine back
print("Mining back...")
for i = 1, distance do
    mineForward()
    print("Progress: " .. i .. "/" .. distance)
end

-- Calculate elapsed time
local endTime = os.epoch("utc")
local elapsedMs = endTime - startTime
local elapsedSec = elapsedMs / 1000

-- Display results
print("\n================================")
print("Mining Complete!")
print("================================")
print("Distance: " .. distance .. " blocks")
print("Time elapsed: " .. string.format("%.2f", elapsedSec) .. " seconds")
print("Total blocks mined: " .. totalBlocks)
print("\nBlocks mined:")
print("--------------------------------")

-- Sort and display block log
local sortedBlocks = {}
for name, count in pairs(blockLog) do
    table.insert(sortedBlocks, {name = name, count = count})
end

table.sort(sortedBlocks, function(a, b) return a.count > b.count end)

for _, block in ipairs(sortedBlocks) do
    print(block.count .. "x " .. block.name)
end

-- Create /tmp directory if it doesn't exist
if not fs.exists("/tmp") then
    fs.makeDir("/tmp")
end

-- Save log to file
local logFile = fs.open("/tmp/blocks.txt", "a")
logFile.writeLine("\n=== Mining Run: " .. os.date("%Y-%m-%d %H:%M:%S") .. " ===")
logFile.writeLine("Distance: " .. distance .. " blocks")
logFile.writeLine("Time: " .. string.format("%.2f", elapsedSec) .. " seconds")
logFile.writeLine("Total blocks: " .. totalBlocks)
logFile.writeLine("Blocks mined:")
for _, block in ipairs(sortedBlocks) do
    logFile.writeLine("  " .. block.count .. "x " .. block.name)
end
logFile.close()

print("\nLog saved to: /tmp/blocks.txt")
