-- inv_to_recipe.lua
-- Utility for CC:Tweaked / Computercraft turtles/computers
-- Inspect an inventory peripheral on a given side and append a recipe
-- entry (ingredients with counts) into a recipes Lua file.
--
-- Usage:
--   inv_to_recipe.lua [side] [recipes_file] [recipe_name]
-- Examples:
--   inv_to_recipe.lua             -- uses side="left", file="recipes.lua", auto name
--   inv_to_recipe.lua right myrecipes.lua "Packed Stone"
--
-- Behavior:
-- - Reads the inventory on the specified side (peripheral.list).
-- - Sums counts by item name (detail.name).
-- - Appends a recipe entry to the recipes file. If the recipes file doesn't
--   exist it will be created with a top-level "return { ... }" table.
-- - The code attempts to safely insert the entry before the final '}' of the
--   returned table. If the file is not in the expected format, it will still
--   try to append but will warn you to inspect the file afterwards.
--
-- Notes:
-- - Recipes file format expected is a Lua chunk that returns an array/table:
--     return {
--       { name = "Example", ingredients = { ["minecraft:stone"]=64 } },
--       ...
--     }
-- - The utility is conservative but not a full Lua parser. Always back up your
--   recipes file before running this on important data.

local args = { ... }
local side = args[1] or "left"
local recipes_file = args[2] or "recipes.lua"
local recipe_name = args[3] -- optional

local function die(fmt, ...)
  local msg = string.format(fmt, ...)
  io.stderr:write("ERROR: " .. msg .. "\n")
  os.exit(1)
end

-- convenience trims
local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- peripheral check
if not peripheral then
  die("peripheral API not available in this environment")
end
if not peripheral.isPresent(side) then
  die("no peripheral attached on side '%s'", tostring(side))
end

-- list inventory
local ok, inv_or_err = pcall(peripheral.call, side, "list")
if not ok then
  die("failed to list inventory on side '%s': %s", side, tostring(inv_or_err))
end
local inv = inv_or_err or {}
-- build ingredients table { name -> count }
local ingredients = {}
for slot, detail in pairs(inv) do
  local name = detail.name or ("<unknown:" .. tostring(slot) .. ">")
  local count = tonumber(detail.count) or 0
  ingredients[name] = (ingredients[name] or 0) + count
end

-- ensure there is at least one item
local any = false
for k,v in pairs(ingredients) do any = true; break end
if not any then
  die("no items found in inventory on side '%s'", side)
end

-- build recipe table
local tname = recipe_name or string.format("From %s @ %s", side, os.date("%Y-%m-%d %H:%M:%S"))
local recipe = {
  name = tname,
  ingredients = ingredients,
}

-- serialize recipe to Lua string with indentation
local function serialize_value(v, indent)
  indent = indent or ""
  local t = type(v)
  if t == "string" then
    -- escape backslashes and double quotes
    local s = v:gsub("\\", "\\\\"):gsub('"', '\\"')
    return '"' .. s .. '"'
  elseif t == "number" or t == "boolean" then
    return tostring(v)
  elseif t == "table" then
    -- assume simple table (map or array) used for ingredients
    local parts = {}
    table.insert(parts, "{")
    local first = true
    for k2, v2 in pairs(v) do
      if not first then table.insert(parts, ",") end
      first = false
      local keyStr
      if type(k2) == "string" and k2:match("^[%a_][%w_:.%-]*$") == nil then
        -- use bracket notation if name contains characters that are not safe for identifiers
        keyStr = "[" .. serialize_value(k2) .. "]"
      elseif type(k2) == "string" then
        -- We want string keys like ["minecraft:stone"]
        keyStr = "[" .. serialize_value(k2) .. "]"
      else
        keyStr = "[" .. tostring(k2) .. "]"
      end
      table.insert(parts, "\n" .. indent .. "  " .. keyStr .. " = " .. serialize_value(v2, indent .. "  "))
    end
    table.insert(parts, "\n" .. indent .. "}")
    return table.concat(parts)
  else
    return "nil"
  end
end

local function serialize_recipe(rec, indent)
  indent = indent or ""
  local parts = {}
  table.insert(parts, "{\n")
  if rec.name then
    table.insert(parts, indent .. "  name = " .. serialize_value(rec.name, indent .. "  ") .. ",\n")
  end
  table.insert(parts, indent .. "  ingredients = " .. serialize_value(rec.ingredients, indent .. "  ") .. ",\n")
  table.insert(parts, indent .. "},")
  return table.concat(parts)
end

local entry_str = serialize_recipe(recipe, "")

-- Read existing file (if any) and try to insert entry before final '}' of top-level return table
local file_contents
local file_handle = io.open(recipes_file, "r")
if not file_handle then
  -- create new file
  local fh, ferr = io.open(recipes_file, "w")
  if not fh then
    die("failed to create recipes file '%s': %s", recipes_file, tostring(ferr))
  end
  fh:write("return {\n")
  fh:write("  " .. entry_str .. "\n")
  fh:write("}\n")
  fh:close()
  print(string.format("Created '%s' and appended recipe '%s'", recipes_file, tname))
  os.exit(0)
else
  file_contents = file_handle:read("*a")
  file_handle:close()
end

-- Find position of last '}' in file (naive, but usually sufficient)
local last_close_pos
for i = #file_contents, 1, -1 do
  if file_contents:sub(i,i) == "}" then
    last_close_pos = i
    break
  end
end

if not last_close_pos then
  -- Can't find a closing brace; append at end but warn
  local fh, ferr = io.open(recipes_file, "a")
  if not fh then
    die("failed to open recipes file '%s' for appending: %s", recipes_file, tostring(ferr))
  end
  fh:write("\n-- Warning: original file had no closing '}', appended a new top-level entry below\n")
  fh:write("return {\n  " .. entry_str .. "\n}\n")
  fh:close()
  print(string.format("Appended new recipes block to '%s' (original file missing closing brace). Inspect the file.", recipes_file))
  os.exit(0)
end

-- find preceding non-space character before last_close_pos
local i = last_close_pos - 1
local preceding_char = nil
while i >= 1 do
  local c = file_contents:sub(i,i)
  if not c:match("%s") then
    preceding_char = c
    break
  end
  i = i - 1
end

local need_comma = true
if not preceding_char then
  need_comma = false
elseif preceding_char == "{" then
  -- empty table -> no comma needed
  need_comma = false
elseif preceding_char == "," then
  need_comma = false
else
  need_comma = true
end

-- Build new contents
local before = file_contents:sub(1, last_close_pos - 1)
local after = file_contents:sub(last_close_pos) -- includes the last '}'
local insert_piece = "\n  " .. (need_comma and "" or "") .. entry_str .. "\n"
-- If we need a comma between the previous element and this new element, ensure previous has a comma.
if need_comma then
  -- add a comma after the last non-space char if it's not already a comma
  -- find position of that char (we have i from above)
  local pos_nonspace = i
  if file_contents:sub(pos_nonspace,pos_nonspace) ~= "," then
    -- insert a comma after pos_nonspace
    before = file_contents:sub(1, pos_nonspace) .. "," .. file_contents:sub(pos_nonspace+1, last_close_pos - 1)
  else
    -- already has comma; keep as-is
    before = file_contents:sub(1, last_close_pos - 1)
  end
end

local new_contents = before .. insert_piece .. after

-- Write back
local fh, ferr = io.open(recipes_file, "w")
if not fh then
  die("failed to open recipes file '%s' for writing: %s", recipes_file, tostring(ferr))
end
fh:write(new_contents)
fh:close()

print(string.format("Appended recipe '%s' to '%s' (side '%s').", tname, recipes_file, side))
print("Recipe contents:")
for k,v in pairs(ingredients) do
  print(string.format("  %s = %d", k, v))
end
print("Please inspect the recipes file to ensure formatting is as you expect.")
