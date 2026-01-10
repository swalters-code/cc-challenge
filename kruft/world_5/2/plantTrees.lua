local width = 5
local length = 6

local function row()
    for i = 1, length do
        turtle.place()
        if i ~= 6 then
            turtle.back()
            turtle.back()
            turtle.back()
        end
    end
end

for i = 1, width do
    print("Planting row " .. i)
    row()
    if i ~= width then
        if i % 2 == 0 then
            turtle.turnLeft()
        else
            turtle.turnRight()
        end
        turtle.forward()
        turtle.forward()
        turtle.forward()
        if i % 2 == 0 then
            turtle.turnLeft()
        else
            turtle.turnRight()
        end
        turtle.back()
        turtle.back()
    end
end

