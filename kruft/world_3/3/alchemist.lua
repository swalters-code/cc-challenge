-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals textutils rednet os peripheral fs write sleep
-- luacheck: ignore 631 (disable line_too_long)
-- Written for CC:Tweaked


-- Alchemist - A simple potion brewing assistant for ComputerCraft
-- Brews potions based on the ingredients in an attached chest.
-- Usage:
-- TODO: Write usage instructions.

---------------------------------------------------
--=== Configuration ===--
---------------------------------------------------
local inputChestName = "ironchest:iron_chest_4" -- The chest to read ingredients from
local outputChestName = "ironchest:iron_chest_4" -- The chest to write brewed potions to
local brewingStandName = "minecraft:brewing_stand_0" -- The brewing stand to use


-- Some recipes are subsets of others.  For
-- instance, a potion of swiftness can be made into
-- a potion of leaping. To avoid ambiguity, we
-- select the recipe with the most ingredients.

-- All potions are one of three types of names:
-- minecraft:potion, minecraft:splash_potion, minecraft:lingering_potion
-- The only way to tell the difference is via the display name or NBT hash.
local bottleTypes = {
  ["minecraft:potion"] = true,
  ["minecraft:splash_potion"] = true,
  ["minecraft:lingering_potion"] = true,
}

-- Slots 1-3 are for bottles
-- Slot 4 is for the reagent
-- Slot 5 is for fuel (blaze powder)

-- Recipe format:

---@class bottle
---@field name string "minecraft:potion", "minecraft:splash_potion", or "minecraft:lingering_potion"
---@field displayName string  Display name of the bottle
---@field type string Display name of the bottle
---@field nbtHash? string Optional hash of the bottle NBT data

---@class ingredients
---@field bottle bottle
---@field reagents string[]

---@class recipe
---@field name string  Display name of the output potion
---@field nbtHash? string Optional hash of the output potion NBT data
---@field ingredients ingredients  The bottle and reagents needed to brew the potion

--[[ Example recipe:
{
  name = "Display Name of Output Potion",
  nbtHash = "nbt_hash_of_output",  -- Optional
  ingredients = {
    bottle = {
      type = "minecraft:potion",
      name = "Display Name of Bottle",
      nbtHash = "nbt_hash_of_bottle"  -- Optional
    },
    -- List of reagents in the order to use them.
    reagents = { "minecraft:nether_wart",
                 "minecraft:sugar",
                 "mincraft:fermented_spider_eye",
                 "minecraft:glowstone_dust" },
    ...
  }
}
--]]

--- The master list of recipes.
---@type recipe[]
local recipes = {}


if fs.exists("recipes.lua") then
  recipes = dofile("recipes.lua")
else
  print("No recipes found")
end

-- Scan the input chest for items matching recipes.
-- Return the recipe for which all ingredients are
-- present with no leftover ingredients.
local function scanForRecipes(inputChest)
  -- Candidate recipes.
  ---@type recipe?
  local retval = nil
  -- Build and index of items in the input chest.

  ---@class itemIndexEntry
  ---@field name string
  ---@field displayName? string
  ---@field nbtHash? string

  --- A map from item name to a list of itemIndexEntry
  ---@type table<string, itemIndexEntry>
  local itemIndex = {}
  -- Build an index of the items in the input chest.
  for slot, item in pairs(inputChest.list()) do
    if bottleTypes[item.name] then
      -- This is a bottle.
      local details = inputChest.getItemDetail(slot)
      if itemIndex[details.displayName] == nil then
        -- New bottle display name.
        itemIndex[details.displayName] = {
          name = item.name,
          displayName = details.displayName,
          nbtHash = details.nbt
        }
      end
      else
        if itemIndex[item.name] == nil then
          itemIndex[item.name] = {
            name = item.name,
          }
        end
    end
  end

  -- Check each recipe against the item index.
    for _, recipe in ipairs(recipes) do
        local bottle = recipe.ingredients.bottle
        if itemIndex[bottle.displayName] ~= nil then
          -- Bottle matches.
          -- FIXME: Check NBT hash if present.
          -- Check reagents
          for _, reagentName in ipairs(recipe.ingredients.reagents) do
            if itemIndex[reagentName] == nil then
              -- Missing reagent.
              goto continue_recipe_loop
            end
          end
          
          -- All ingredients matched.
          -- If this recipe has more ingredients than the
          -- current candidate, select it.
          if retval == nil or
            #recipe.ingredients.reagents >
              #retval.ingredients.reagents then
            retval = recipe
          end
        end
        ::continue_recipe_loop::
    end
  return retval
end

local inputChest = peripheral.wrap(inputChestName)
assert(inputChest ~= nil,
       "Input chest " .. inputChestName .. " not found.")
local brewingStand = peripheral.wrap(brewingStandName)
assert(brewingStand ~= nil,
       "Brewing stand " .. brewingStandName .. " not found.")
local outputChest = peripheral.wrap(outputChestName)
assert(outputChest ~= nil,
       "Output chest " .. outputChestName .. " not found.")

if arg[1] == "brew" then
  local toBrew = scanForRecipes(inputChest)

  if toBrew ~= nil then
    print("Ready to brew: " .. toBrew.name)
  else
    print("No matching recipe found.")
    return
  end

  -- load bottles

  -- We may have up to 3 bottles to load.
  local bottleCount = 0
  for slot, item in pairs(inputChest.list()) do
    if toBrew.ingredients.bottle.name == item.name then
      local details = inputChest.getItemDetail(slot)
      assert(details ~= nil,
             "Slot unexpectedly empty " .. slot)
      if details.displayName ==
      toBrew.ingredients.bottle.displayName then
        -- Bottle matches.
        bottleCount = bottleCount + 1
        inputChest.pushItems(
          brewingStandName,
          slot,
          1,
          bottleCount -- Slot in brewing stand
        )
        if bottleCount >= 3 then
          break
        end
      end
    end
    if bottleCount == 0 then
      print("No bottles found for recipe.")
      return
    end
    print("Loaded " .. bottleCount .. " bottles.")
  end

  -- Load reagents one at a time, waiting for the
  -- brewing to complete. Test completion by checking
  -- for a change in the bottle name.
  local previousBottleName = toBrew.ingredients.bottle.displayName
  for _, reagentName in ipairs(toBrew.ingredients.reagents) do
    local reagentFound = false
    -- Find and move reagent from input chest to brewing stand.
    for slot, item in pairs(inputChest.list()) do
      if reagentName == item.name then
        inputChest.pushItems(
          brewingStandName,
          slot,
          1,
          4 -- Slot in brewing stand
        )
        reagentFound = true
        break
      end
    end
    if not reagentFound then
      print("Reagent " .. reagentName .. " not found in input chest.")
      return
    end
    print("Loaded reagent: " .. reagentName)
    -- Brewing takes 20 seconds.
    sleep(20)
    -- Check for a change in the bottle name.
    while brewingStand.getItemDetail(1).displayName ==
      previousBottleName
    do
      sleep(1)
      -- TODO: Add a timeout to avoid infinite loop.
    end
    previousBottleName = brewingStand.getItemDetail(1).displayName
  end
elseif arg[1] == "learn" then
  -- Teaching recipes are lined up in the input chest.
  -- Slots 1-3: bottles (number does not matter)
  -- Slot 4-n: reagents (in order)
  -- Slot n+1: product.
  local newRecipe = {}
  local item = inputChest.getItemDetail(1)
  assert(item ~= nil,
         "No bottle found in slot 1.")
  newRecipe.bottle = {
    name = item.name,
    displayName = item.displayName,
    nbtHash = item.nbt
  }
  -- Find the first reagent.
  local list = inputChest.list()
  local index = 2
  while list[index] ~= nil and
    bottleTypes[list[index].name]
  do
    index = index + 1
  end
  newRecipe.reagents = {}
    while not bottleTypes[list[index].name]
        and list[index] ~= nil
    do
        table.insert(newRecipe.reagents
            list[index].name)
        index = index + 1
    end
  -- The next slot is the product.
  -- TODO: add the option of creating the product
  --       to get it's information.
  local productItem = inputChest.getItemDetail(index)
    assert(productItem ~= nil,
           "No product found in slot " .. index .. ".")
  -- Add to the recipes list.
  table.insert(recipes,{
    name = productItem.displayName,
    nbtHash = productItem.nbt,
    ingredients = {
      bottle = newRecipe.bottle,
      reagents = newRecipe.reagents
        }
  })
  -- Save the updated recipes list.
  local file = fs.open("recipes.lua", "w")
  file.write("return " .. textutils.serialize(recipes))
  file.close()
end
