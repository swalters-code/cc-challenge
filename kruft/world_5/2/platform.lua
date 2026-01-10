local length = arg[1] and tonumber(arg[1]) or 6
local width = arg[2] and tonumber(arg[2]) or 5

-- Zigzag and place down a platform.

local function findBlock()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "minecraft:dirt" then
            turtle.select(slot)
            return slot
        end
    end
    return nil
end

turtle.forward()

for d = 1, length * width do
    if d % width == 0 then
        local row = math.floor((d - 1) / width) + 1
        if row % 2 == 1 then
            turtle.turnLeft()
        else
            turtle.turnRight()
        end
    end
    if d % width == 1 then
        local row = math.floor((d - 1) / width) + 1
        if row % 2 == 1 then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
    end
    -- Place block down
    if not turtle.detectDown() then
        findBlock()
        turtle.placeDown()
    end
    turtle.forward()

end
