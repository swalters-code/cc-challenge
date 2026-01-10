

local length = tonumber(arg[1]) or 1

local function findTorch()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "minecraft:torch" then
            turtle.select(slot)
            return slot
        end
    end
    return nil
end

local function findFlooring()
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == "minecraft:polished_deepslate" then
            turtle.select(slot)
            return slot
        end
    end
    return nil
end

for i = 1, length do
    turtle.dig()
    turtle.digUp()
    if not turtle.detectDown() then
        findFlooring()
        turtle.placeDown()
    end
    if i % 4 == 0 then
        findTorch()
        turtle.back()
        turtle.placeUp()
        turtle.forward()
    end
    turtle.forward()
end

turtle.forward()

turtle.turnRight()
turtle.turnRight()
for _ = 1, length + 1 do
    turtle.forward()
end
