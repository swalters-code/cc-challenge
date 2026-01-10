-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils
-- Written for CC:Tweaked

-- Dig straight down, mining on all four sides,
-- until you hit bedrock or run out of fuel, or inventory is full.

-- Usage: neo_drill.lua [depth]

-- Inspect each of the blocks before mining and add
-- them to a list.  Save the list each time a block
-- is added. List is a lua table serialized to a file.

-- TODO: Add refueling support.

local t = turtle
turtle = nil -- prevent accidental use of global turtle

local depth = tonumber(arg[1]) or math.huge

local saveDir = "/data"
local inspectedBlocksFile = saveDir .. "/inspected_blocks.lua"

local function loadList()
  -- Create the directory, if neccessary.
  if not fs.exists(saveDir) then
    fs.makeDir(saveDir)
  end
  local exists = fs.exists(inspectedBlocksFile)
  if not exists then
    return {}
  end
  local list = dofile(inspectedBlocksFile)
  -- TODO: error checking on the loaded file
  return list
end

local function saveList(list)
  if not fs.exists(saveDir) then
    fs.makeDir(saveDir)
  end
  local file = fs.open(inspectedBlocksFile, "w")
  -- TODO: error checking on file operations
  if not file then
    error("Could not open file for writing: " .. inspectedBlocksFile)
  end
  file.write("return " .. textutils.serialize(list))
  file.close()
end

local seenBlocks = loadList()

local function inspectAndMine()
  for _ = 1, 4 do
    local success, data = t.inspect()
    if success then
      local id = data.name
      if not seenBlocks[id] then
        seenBlocks[id] = data
        saveList(seenBlocks)
      end
      t.dig()
      t.turnRight()
    end
  end
  local success, data = t.inspectDown()
  if success then
    local id = data.name
    if id and not seenBlocks[id] then
      seenBlocks[id] = data
      saveList(seenBlocks)
    end
    t.digDown()
  end
end

local d = 0
while d <= depth do
  inspectAndMine()
  local success, data = t.inspectDown()
  if success and data.name == "minecraft:bedrock" then
    print("Hit bedrock at depth " .. d .. ", returning.")
    break
  end
  -- Make sure we have more than enough fuel to return.
  if t.getFuelLevel() < d * 2 then
    print("Insufficient fuel to continue at depth " .. d .. ", returning.")
    break
  end
  -- Return if inventory is full.
  local inventoryFull = false
  for slot = 1, 15 do
    t.select(slot)
    if t.getItemCount(slot) == 0 then
      break
    end
    if slot == 15 then
      print("Inventory full at depth " .. d .. ", returning.")
      inventoryFull = true
    end
  end
  t.select(1)
  if inventoryFull then
    break
  end
  if d < depth and not t.down() then
    print("Could not move down at depth " .. d .. ", returning.")
    break
  end
  d = d + 1
end

-- Begin moving back up

for _ = 1, d do
  t.up()
end
