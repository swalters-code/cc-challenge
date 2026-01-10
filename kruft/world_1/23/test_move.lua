local chest, stand_name
local sides = {top=true, bottom=true, left=true, right=true, front=true, back=true}

for _, name in ipairs(peripheral.getNames()) do
    -- Ignore local sides (top, bottom, etc) to ensure we get the network names
    if not sides[name] then
        local type = peripheral.getType(name)
        if type == "minecraft:brewing_stand" then
            stand_name = name
        elseif type == "minecraft:chest" then
            chest = peripheral.wrap(name)
        end
    end
end

if not chest or not stand_name then error("Networked devices not found") end

-- Chest pulls from Stand (Slot 5 -> Chest Slot 1)
chest.pullItems(stand_name, 5, 2, 1)

-- Chest pushes to Stand (Chest Slot 1 -> Stand Slot 5)
chest.pushItems(stand_name, 1, 1, 5)
