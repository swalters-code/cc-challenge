-- Shuffle chest contents using the last slot as temp

local maxInt = 2147483647 -- Max 32 bit integer. 
local chest = peripheral.wrap(arg[1] or "ironchest:diamond_chest_46")
local size = chest.size()
local name = peripheral.getName(chest)

for _ = 1, arg[2] or 2 do
    for slot = 1, size - 1 do
        local targetSlot = math.random(size - 1)
        if slot ~= targetSlot then
            chest.pushItems(name, slot, maxInt, size)
            chest.pushItems(name, targetSlot, maxInt, slot)
            chest.pushItems(name, size, maxInt, targetSlot)
        end
    end
end
