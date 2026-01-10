local times = {}

-- Test 1: Turn 100 times (same direction)
local start = os.clock()
for i = 1, 100 do
    turtle.turnLeft()
end
local elapsed1 = os.clock() - start
times[1] = elapsed1

-- Test 2: Go forward 10 times, back 10 times, repeated 10 times
start = os.clock()
for rep = 1, 10 do
    for i = 1, 10 do
        turtle.forward()
    end
    for i = 1, 10 do
        turtle.back()
    end
end
local elapsed2 = os.clock() - start
times[2] = elapsed2

-- Function to go in a square of side length s, once
local function doSquare(s)
    for _ = 1, 4 do
        for _= 1, s do
            turtle.forward()
        end
        turtle.turnRight()
    end
end

-- Test 3: Go in a 2x2 square 100 times (side length 2)
start = os.clock()
for i = 1, 100 do
    doSquare(2)
end
local elapsed3 = os.clock() - start
times[3] = elapsed3

-- Test 4: Go in a 3x3 square 100 times (side length 3)
start = os.clock()
for i = 1, 100 do
    doSquare(3)
end
local elapsed4 = os.clock() - start
times[4] = elapsed4

-- Test 5: Go in a 4x4 square 100 times (side length 4)
start = os.clock()
for i = 1, 100 do
    doSquare(4)
end
local elapsed5 = os.clock() - start
times[5] = elapsed5

-- Test 6: Go forward 10, turn left twice, repeated 10 times
start = os.clock()
for rep = 1, 10 do
    for i = 1, 10 do
        turtle.forward()
    end
    turtle.turnLeft()
    turtle.turnLeft()
end
local elapsed6 = os.clock() - start
times[6] = elapsed6

-- Summarize on screen
print("Test 1 (100 turns): " .. elapsed1 .. " seconds")
print("Test 2 (forward/back repeats): " .. elapsed2 .. " seconds")
print("Test 3 (2x2 square 100x): " .. elapsed3 .. " seconds")
print("Test 4 (3x3 square 100x): " .. elapsed4 .. " seconds")
print("Test 5 (4x4 square 100x): " .. elapsed5 .. " seconds")
print("Test 6 (forward 10, 180 turn, 10x): " .. elapsed6 .. " seconds")

-- Save to file
local file = fs.open("movement.txt", "w")
file.writeLine("Test 1 (100 turns): " .. elapsed1 .. " seconds")
file.writeLine("Test 2 (forward/back repeats): " .. elapsed2 .. " seconds")
file.writeLine("Test 3 (2x2 square 100x): " .. elapsed3 .. " seconds")
file.writeLine("Test 4 (3x3 square 100x): " .. elapsed4 .. " seconds")
file.writeLine("Test 5 (4x4 square 100x): " .. elapsed5 .. " seconds")
file.writeLine("Test 6 (forward 10, 180 turn, 10x): " .. elapsed6 .. " seconds")
file.close()
