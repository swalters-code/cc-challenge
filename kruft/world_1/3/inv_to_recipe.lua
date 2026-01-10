-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- inspect the inventory above and append a recipe based on its contents
--[[
Usage:
  inv_to_recipe [RECIPE_FILE] [SIDE] [NAME]

Description:
  Append a recipe to RECIPE_FILE (default: "recipes.lua").
  Place an inventory on SIDE (default: "top") and put the items that make up the recipe
  into that inventory, then run this script to append the recipe to the file.
  Optionally provide a NAME to give the recipe a specific name.

Examples:
  inv_to_recipe energizing_org.lua
  inv_to_recipe my_recipes.lua bottom "My Recipe"

Defaults:
  RECIPE_FILE -> recipes.lua
  SIDE        -> top
--]]

local function die(fmt, ...)
  local msg = string.format(fmt, ...)
  io.stderr:write("ERROR: " .. msg .. "\n")
  error()
end

local function exit()
  error()
end

local function isEmpty(tbl)
  return type(tbl) == "table" and next(tbl) == nil
end

local args = { ... }
if #args > 3 then
  local scriptName = fs.getName(shell.getRunningProgram())
  print("Usage:")
  print( scriptName .." [RECIPE_FILE] [SIDE] [RECIPE_NAME]\n")
  exit()
end

local recipeFile = args[1] or "recipes.lua"
local side = args[2] or "top"
local recipeName = args[3]
  or string.format("On "
  .. os.date("%Y-%m-%d %H:%M:%S"))

local inventory = peripheral.wrap(side)

if not inventory then
  print("No inventory found on side: " .. side)
  return
end

local contents = inventory.list()
if isEmpty(contents) then
  die("Inventory on side %s is empty", side)
end

-- build ingredients table
local ingredients = {}
for _, item in pairs(contents) do
  ingredients[item.name] = (ingredients[item.name] or 0) + item.count
end

local recipe = {
  name = recipeName,
  ingredients = ingredients,
}

-- Read existing recipes from file.
local existingRecipes = {}
local fileHandle, err = fs.open(recipeFile, "r")
if err and not string.find(err, "No such file") then
  die("Failed to open existing recipe file %s: %s", recipeFile, err)
end

if fileHandle then
  local fileContent, err = fileHandle.readAll()
  fileHandle.close()
  -- compile the contents of the file into a function
  -- When called, the function will return the recipes table
  local func, err = load(fileContent, "@" .. recipeFile, "t", {})

  if err then
    die("Failed to load existing recipes from %s: %s", recipeFile, err)
  end

  if not func then
    die("Failed to load existing recipes from %s", recipeFile)
  end

  local ok, result = pcall(func)
  if not ok then
    die("Error parsing %s: %s", recipeFile, result)
  end
  if not type(result) == "table" then
    die("Invalid format in %s: expected a table of recipes", recipeFile)
  end

  existingRecipes = result
end

table.insert(existingRecipes, recipe)

-- write the recipe file
fileHandle, err = fs.open(recipeFile, "w")
if err then
  die("Failed to open recipe file %s for writing: %s", recipeFile, err)
end

local function esc(s) -- escape backslashes and quotes in strings
return s:gsub("\\", "\\\\"):gsub("\"", "\\\"")
end

fileHandle.write("-- " .. recipeFile .. "\n")
fileHandle.write("return {\n")
for i, rec in ipairs(existingRecipes) do

  fileHandle.write(
    "  { name = \""
      .. esc(rec.name)
      .. "\",\n"
  )
  fileHandle.write(
    "    ingredients = {\n"
  )

  for itemName, count in pairs(rec.ingredients) do
    fileHandle.write(
      "      [\""
        .. esc(itemName)
        .. "\"] = " .. tostring(count)
    )
    if next(rec.ingredients, itemName) ~= nil then
      -- more ingredients to come
      fileHandle.write(",\n")
    else
      -- close ingredients table
      fileHandle.write("\n    }")
    end
  end

  -- close recipe table
  fileHandle.write("\n  }")
  
  if i < #existingRecipes then
    -- more recipes to come
    fileHandle.write(", \n")
  else
    -- close main table
    fileHandle.write("\n}\n")
  end
end
fileHandle.close()

print("Appended recipe '"
  .. recipeName .. "' to " .. recipeFile)
print("Ingredients:")
for itemName, count in pairs(ingredients) do
  print("  " .. itemName .. ": " .. count)
end
