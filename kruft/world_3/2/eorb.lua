-- autocrafter.lua
-- Usage:
--   autocrafter.lua [recipes_file] [input_side] [output_side]
-- Examples:
--   autocrafter.lua            -- uses recipes.lua, input=left, output=right
--   autocrafter.lua myrecipes.lua bottom top

local args = { ... }
local recipes_file = args[1] or "recipes.lua"
local inputSide = args[2] or "top"
local outputSide = args[3] or "bottom"

local function die(msg)
  io.stderr:write("ERROR: " .. tostring(msg) .. "\n")
  return os.exit(1)
end

-- try to load recipes file
local ok, recipes = pcall(dofile, recipes_file)
if not ok then
  die("Failed to load recipes file '" .. recipes_file .. "': " .. tostring(recipes))
end
if type(recipes) ~= "table" then
  die("Recipes file must return a table (array) of recipes")
end

local peripheral = peripheral

local function isPeripheralAttached(side)
  return peripheral and peripheral.isPresent(side)
end

if not isPeripheralAttached(inputSide) then
  die("No peripheral on input side '" .. inputSide .. "'")
end
if not isPeripheralAttached(outputSide) then
  die("No peripheral on output side '" .. outputSide .. "'")
end

local function inventoryList(side)
  -- returns table: slot -> {name=..., count=..., damage=..., nbt=...}
  local ok, res = pcall(peripheral.call, side, "list")
  if not ok then
    error("Failed to list inventory on side '" .. tostring(side) .. "': " .. tostring(res))
  end
  return res or {}
end

local function inventoryIsEmpty(side)
    local list = inventoryList(side)
    -- check if the list is structurally equivalent to empty
  return next(list) == nil
end

local function getCounts(side)
  local counts = {}
  local list = inventoryList(side)
  for slot, detail in pairs(list) do
    local name = detail.name or ("<unknown:" .. tostring(slot) .. ">")
    counts[name] = (counts[name] or 0) + (detail.count or 0)
  end
  return counts, list
end

local function findMatchingRecipe()
  local counts = getCounts(inputSide)
  for i, recipe in ipairs(recipes) do
    local ok = true
    if type(recipe) ~= "table" or type(recipe.ingredients) ~= "table" then
      -- skip malformed entry
      ok = false
    else
      for reqName, reqCount in pairs(recipe.ingredients) do
        if (counts[reqName] or 0) < reqCount then
          ok = false
          break
        end
      end
    end
    if ok then
      return recipe
    end
  end
  return nil
end

local function moveRecipeItems(recipe)
  -- Moves the exact required items from inputSide to outputSide using pushItems
  -- Returns true on success, false and error message on failure.
  local _, list = getCounts(inputSide)
  -- remaining counts to move by item name
  local remaining = {}
  for name, n in pairs(recipe.ingredients) do remaining[name] = n end

  -- iterate through slots to push matching items
  for slot, detail in pairs(list) do
    local name = detail.name
    local need = remaining[name]
    if need and need > 0 then
      local toMove = math.min(detail.count, need)
      local ok, err = pcall(peripheral.call, inputSide, "pushItems", outputSide, slot, toMove)
      if not ok then
        return false, "pushItems failed: " .. tostring(err)
      end
      -- peripheral.call returns number of moved items for many inventory implementations,
      -- but we assume success if no error thrown.
      remaining[name] = remaining[name] - toMove
    end
  end

  -- verify all satisfied
  for name, left in pairs(remaining) do
    if left > 0 then
      return false, "Not enough of " .. tostring(name) .. " moved; remaining " .. tostring(left)
    end
  end
  return true
end

local function recipeToString(r)
  local parts = {}
  if r.name then table.insert(parts, r.name .. "\n") end
  for n, c in pairs(r.ingredients or {}) do
    table.insert(parts, tostring(c) .. "x " .. tostring(n) .. "\n")
  end
  return table.concat(parts)
end

print("AutoCrafter starting")
print(" Recipes file: " .. recipes_file)
print(" Input side: " .. inputSide)
print(" Output side: " .. outputSide)
print(" Loaded " .. tostring(#recipes) .. " recipes")

-- main loop
while true do
  -- wait until output is empty
  if not inventoryIsEmpty(outputSide) then
    -- little sleep to avoid spinning
    os.sleep(1)
  else
    local recipe = findMatchingRecipe()
    if recipe then
      print("Found recipe: " .. recipeToString(recipe))
      local ok, err = moveRecipeItems(recipe)
      if ok then
        print("Moved recipe items to output")
      else
        print("Failed to move recipe items: " .. tostring(err))
      end
      -- small pause before next loop to let inventories update / for next checks
      os.sleep(0.5)
    else
      -- nothing to do right now
      os.sleep(1)
    end
  end
end
