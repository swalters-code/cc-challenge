-- recipes.lua
-- This file should return an array (list) of recipes.
-- Each recipe is a table: { name = "friendly name", ingredients = { ["minecraft:item_name"] = count, ... } }

return {
  {
    name = "Simple Stick Pack",
    ingredients = {
      ["minecraft:planks"] = 2,  -- example: 2 planks -> something
      -- adjust to your modpack item names and counts
    }
  },
  {
    name = "Iron Bundle (example)",
    ingredients = {
      ["minecraft:iron_ingot"] = 4,
    }
  },
  {
    name = "Coal & Stone (example)",
    ingredients = {
      ["minecraft:coal"] = 2,
      ["minecraft:cobblestone"] = 8,
    }
  },
}
