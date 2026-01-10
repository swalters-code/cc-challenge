-- This file contains notes on how to use chests and item details in ComputerCraft / CC:Tweaked.

-- each item in inputChest.list() is like:
{ count = 1,
  name = "minecraft:stone",
  nbt = "<a long hash>" -- maybe
}
        
-- inputChest.getItemDetail(slot) returns:
{ name = "minecraft:stone",
  displayName = "Stone",
  count = 64,
  maxCount = 64,
  damage = 0, (maybe)
  maxDamage = 0, (maybe)
  nbt = "<a long hash>" (maybe)
  tags = { -- (a set of tags)
      ["forge:stones"] = true,
      ["minecraft:stone"] = true,
      ... }
  enchantments = { -- mayba  a list of enchantments
      { name = "minecraft:sharpness",
        displayName = "Sharpness",
        level = 5 },
      ...}
  -- the itemGroups is deprecated.
}
