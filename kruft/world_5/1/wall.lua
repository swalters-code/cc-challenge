if not arg[1] then
    print("Build a square wall.")
    print("Usage: wall <width> [height]")
    print("Height not yet implemented")
    -- TODO: Add wall height.
    return
end

local width = tonumber(arg[1])

local height = 1
if arg[2] ~= nil then
    height = tonumber(arg[2])
end

local slot = 1
turtle.select(slot)
turtle.up()
for h = 1, height do
    for _ = 1, 4 do
        for _ = 1, width - 1 do
            if turtle.getItemCount(slot) == 0 then
                slot = slot + 1
                if slot > 16 then
                    print("Out of blocks!")
                    return
                end
                turtle.select(slot)
            end
            turtle.placeDown()
            turtle.forward()
        end
        turtle.turnRight()
    end
   if h < height then
       turtle.up()
   end
end
