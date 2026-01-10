
local length = 6
local width = 5
for i = 1, width do
    for j = 1, length do
        shell.run("log.lua")
        if j ~= 6 then
            turtle.forward()
            turtle.forward()
        end
    end
    if i ~= width then

        turtle.forward()
        if i %2 == 1 then
            turtle.turnLeft()
        else
            turtle.turnRight()
        end
        turtle.forward()
        turtle.forward()
        turtle.forward()
        if i %2 == 1 then
            turtle.turnLeft()
        else
            turtle.turnRight()
        end
    end
end

-- Get in position for planting
turtle.back()

