local chest = peripheral.find("minecraft:chest")
local stand_name
peripheral.find("minecraft:brewing_stand", function(name) stand_name = name return true end)

-- Chest pulls FROM Stand (Stand Slot 5 -> Chest Slot 1)
chest.pullItems(stand_name, 5, 1, 1)

-- Chest pushes TO Stand (Chest Slot 1 -> Stand Slot 5)
chest.pushItems(stand_name, 1, 1, 5)
