-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals textutils rednet os peripheral fs write sleep
-- luacheck: ignore 631 (disable line_too_long)
-- Written for CC:Tweaked


-- Sort Apotheosis gems into row (or columns) in
-- chests based on their type and quality, leaving
-- empty slots for missing tiers.


-- For debugging:
local pretty = require("cc.pretty")

-- Pretty-print a data structure to the screen
-- luacheck: ignore pp unused
local function pp(data)
  textutils.pagedPrint(pretty.render(pretty.pretty(data),51))
end


---------------------------------------------------
---- Configuration ----
---------------------------------------------------

-- The file to save/load gem type locations.
---@type string
local gemTypeFile =
  "gemTypes.lua"

-- The input chest where unsorted gems are placed.
---@type string
local inputChestName =
  "ironchest:obsidian_chest_4"

-- The storage chests where sorted gems are placed,
-- in the order they will be filled.
-- All storage chests must be of the same size.
---@type string[]
local storageChestNames = {
  "ironchest:diamond_chest_46",
  "ironchest:diamond_chest_44",
  -- "ironchest:diamond_chest_42",
  -- "ironchest:diamond_chest_40",
  -- "ironchest:diamond_chest_47",
  -- "ironchest:diamond_chest_45",
  -- "ironchest:diamond_chest_43",
  -- "ironchest:diamond_chest_41"
}

---Configure how the storage chests are filled.
---@type string
local storageChestType = "ironchest:diamondchest"

-- Sleep time between processing input chest (seconds)
---@type integer
local sleepSeconds = 15

---------------------------------------------------
---- End of configuration ----
--------------------------------------------------

local function time(fn, ...)
  local start = os.epoch("local")
  local ret = {pcall(fn, ...)}
  local elapsed = os.epoch("local") - start
  return elapsed / 1000.0, table.unpack(ret)
end

--- Max 32 bit integer (32 bit ints are used by CC:Tweaked)
---@type integer
local maxInt = 2147483647 -- Max 32 bit integer.

---@type ccTweaked.peripheral.wrappedPeripheral|nil
local inputChest = peripheral.wrap(inputChestName)
assert(inputChest, string.format(
  "Input chest '%s' not found.", inputChestName))


---A lookup table matching gem tier prefixes to their tier number.
---Skips Tier 4, which has no prefix.
---@type table<string, integer>
local tierPrefixLookup = {
  ["Cracked"] = 1,
  ["Chipped"] = 2,
  ["Flawed"] = 3,
  -- skip Tier 4, no prefix
  ["Flawless"] = 5,
  ["Perfect"] = 6
}

--- Parse a gem name into its type and tier.
---@param gemName string The full display name of the gem, e.g. "Chipped Endersurge Gem"
---@return string, integer -- typeName, tier
local function parseGemName(gemName)
  -- find the type prefix
  -- We know the separator is always a space.
  ---@type string|nil, string|nil
  local prefix, typeName = gemName:match("^(%S+) (.+)$")
  if tierPrefixLookup[prefix] == nil then
    -- Tier 4 gems have no prefix.
    return gemName, 4
  end
  ---@cast typeName string
  return typeName, tierPrefixLookup[prefix]
end

---Information about how to store gems in a particular chest type.
---@class chestTypeConfig
---@field gemsPerChest integer The number of gem types that can be stored in a single chest.
---@field startingSlots integer[] The starting slots for each gem type in the chest.
---@field getTierOffset fun(startSlot: integer, tier: integer): integer Function to compute absolute slot from starting slot and tier.

---A table holding configuration data for each supported chest type.
---@type chestTypeConfig[]
local chestTypes = {
  -- Diamond chests from Iron Chests are 12x9 (108 slots)
  -- They will hold 18 gem types cleanly, 2 per row.
  ["ironchest:diamondchest"] = {
    gemsPerChest = 18,
    startingSlots = { 1,   7, 13, 19, 25,  31,
                      37, 43, 49, 55, 61,  67,
                      73, 79, 85, 91, 97, 103},
    getTierOffset = function (startSlot, tier)
      -- Each tier is stored consecutively.
      return startSlot + (tier - 1)
    end
  },

  -- A double vanilla chest is 9x6 (54 slots)
  -- They will hold 9 gem types cleanly, 1 per column.
  ["minecraft:chest"] = {
    gemsPerChest = 9,
    startingSlots = {1, 2, 3, 4, 5, 6, 7, 8, 9},
    getTierOffset = function (startSlot, tier)
      -- Each tier is stored 9 slots apart.
      return startSlot + (tier - 1) * 9
    end
  },
  -------------------------------------------
  -- Add other chest types here as needed. --
  -------------------------------------------
}
assert(chestTypes[storageChestType],
       string.format(
         "Unsupported storage chest type '%s'.\n"
           .. "Consider adding it to the chestTypes table.",
         storageChestType))

local gemsPerChest =
  chestTypes[storageChestType].gemsPerChest
local startingSlots =
  chestTypes[storageChestType].startingSlots
local getTierOffset =
  chestTypes[storageChestType].getTierOffset

-- Gem types.  Filled in as we discover them.

-- Each record holds a typename (for convenience)
-- the chest name it is stored in and starting
-- slot.

-- FIXME: Change the startSlot to be an index
--        indicating that it is the nth gem type
--        and then calculate the startSlot on
--        demand.

---A record for a discovered gem type, and where it is stored.
---@class gemTypeRecord
---@field typeName string Name of the gem type, e.g. "Endersurge Gem"
---@field chestName string  The name of the chest where this gem type is stored
---@field startSlot integer The number of the base slot in the chest for this gem type

-- The associative array mapping gem type name -> gemTypeRecord
---@type table<string, gemTypeRecord>
local gemTypes = {}

-- Check to see if "gemTypes.lua" exists, and load it if so.
if fs.exists(gemTypeFile) then
  --FIXME: Error handling for dofile failure?
  -- Likely needs a protected call.
  ---@cast gemTypes table<string, gemTypeRecord>
  gemTypes = dofile(gemTypeFile)
end

---The number of gem types already discovered.
---@type integer
local typesDiscovered = 0
-- Count how many gem types we have already discovered
for _, _ in pairs(gemTypes) do
  typesDiscovered = typesDiscovered + 1
end

-- Serialize gemTypes to a formatted string of Lua code.
---@param gemTypeTable table<string, gemTypeRecord>
local function serializeGemTypes(gemTypeTable)
  local lines = {}
  table.insert(lines, "return {")
  for typeName, record in pairs(gemTypeTable) do
    table.insert(lines, string.format(
      "  [%q] = {\n"
        .. "    typeName = %q,\n"
        .. "    chestName = %q,\n"
        .. "    startSlot = %d },",
      typeName,
    record.typeName,
    record.chestName,
    record.startSlot))
  end
  table.insert(lines, "}")
  return table.concat(lines, "\n")
end

---Loop to process each gem in input chest.
---@return nil
local function storeGems()
  -- Iterate over all items in input chest.
  for slot, gem in pairs(inputChest.list()) do
    -- Only process Apotheosis gems.
    if gem.name == "apotheosis:gem" then
      local gemDetail = inputChest.getItemDetail(slot)
      if gemDetail == nil then
        error(string.format(
          "Could not get item detail for gem in slot %d",
          slot))
      end
      ---@type string
      local displayName = gemDetail.displayName
      local typeName, tier = parseGemName(displayName)

      -- check if we have seen this type before
      if gemTypes[typeName] == nil then
        -- New gem type discovered
        typesDiscovered = typesDiscovered + 1
        local chestIdx = math.floor((typesDiscovered - 1) / gemsPerChest) + 1
        local chestName = storageChestNames[chestIdx]
        if not chestName then
          error(string.format("No storage chest for gem type '%s'", typeName))
        end
        local startSlotIdx = ((typesDiscovered - 1) % gemsPerChest) + 1
        local startSlot = startingSlots[startSlotIdx]
        gemTypes[typeName] = {
          typeName = typeName,
          chestName = chestName,
          startSlot = startSlot
        }
        -- Save gem type records to file "gemTypes.lua"
        local file, err = fs.open(gemTypeFile, "w")
        assert(file, string.format(
          "Could not open gem type file '%s' for writing.\nError: %s",
          gemTypeFile, err))

        file.write(serializeGemTypes(gemTypes))
        file.close()
      end
      local gemRecord = gemTypes[typeName]
      local destSlot = getTierOffset(gemRecord.startSlot, tier)
      -- move the gem to its destination

      local movedItems =
        inputChest.pushItems(
        gemRecord.chestName,
        slot,
        gem.count,
        destSlot)
      if movedItems < gem.count then
        write(string.format(
          "(Tier %d) '%s' full.\n chest '%s' slot %d\n",
          tier,
          typeName,
        gemRecord.chestName,
          destSlot))
      end
    end
  end
end

-- Sort gems already in storage chests.
local function repairSortedChests()
  -- Calls to list, getItemDetail, and pushItems
  -- are expensive. Each takes about 1 tick. That
  -- adds up for large banks of storage.  Much of
  -- this code is devoted to minimizing calls to
  -- these functions.

  -- Function declarations.

  -- luacheck: ignore unused fromChestName fromChestPeripheral fromSlot seenSlots

  -- Recursively move gems out of the way to sort them.
  -- seenSlots is used to detect cycles.
  ---@type fun(fromChestName: string, fromChestPeripheral: ccTweaked.peripheral.wrappedPeripheral, fromSlot: integer, seenSlots: markTable): integer
  ---@param fromChestName string
  ---@param fromChestPeripheral ccTweaked.peripheral.wrappedPeripheral
  ---@param fromSlot integer
  ---@param seenSlots markTable
  ---@return integer number of items moved
  local function fixSlot(fromChestName, fromChestPeripheral, fromSlot, seenSlots)
    -- stub function for forward declaration
    return 0
  end

  -- Cache various information about storage chests.

  ---@class storageChestCache
  ---@field idx integer
  ---@field name string
  ---@field peri ccTweaked.peripheral.wrappedPeripheral
  ---@field size integer
  ---@field list table<integer, ccTweaked.peripheral.item>

  --- A table matching storage chest names to their cache record.
  ---@type table<string, storageChestCache>
  local storageChests = {}
  -- Set up storage chest cache
  for idx, chestName in pairs(storageChestNames) do
    local chestPeripheral = peripheral.wrap(chestName)
    assert(chestPeripheral, string.format(
      "Storage chest '%s' not found.", chestName))
    storageChests[chestName] = {
      idx = idx,
      name = chestName,
      peri = chestPeripheral,
      size = chestPeripheral.size(),
      list = chestPeripheral.list()
    }
  end

  --- A table matching storage chest names to their cache record.
  ---@type storageChestCache[]
  local storageChestsIdx = {}
  for idx , name in pairs(storageChestNames) do
    storageChestsIdx[idx] = storageChests[name]
  end

  -- Move an item to the input chest
  ---@param fromChestPeripheral ccTweaked.peripheral.wrappedPeripheral
  ---@param slot integer
  ---@return integer Number of items moved.
  local function moveToInputChest(fromChestPeripheral, slot)
    --FIXME: Check for errors.
    local movedItems = fromChestPeripheral.pushItems(
      inputChestName,
      slot)
    return movedItems
  end

  -- When a the location we need to move a gem is
  -- blocked by a different kind of gem, we move it
  -- out of the way. We do this by moving the
  -- blocking gem where it belongs, recursing as
  -- necessary. However, if we encounter a cycle,
  -- we need somewhere to move it. We use the last
  -- provably empty slot for this purpose. If no
  -- slot is available, we move it to the input
  -- chest and make the user deal with it
  -- themselves.

  ---@class stashSlot
  ---@field chestName string? The name of the chest where the stash slot is located.
  ---@field slotNum integer? The slot number of the stash slot.
  ---@field used boolean? Whether the stash slot holds a stashed gem.
  ---@field keep boolean? Whether to keep the stash slot after use.

  ---@type stashSlot
  local stash = {
    chestName = nil,
    slotNum = nil,
    used = false,
    keep = false
  }

  --- Move an item into the stash slot.
  --- If no free slot is available, kick it to the
  --- input chest to be handled by the user, but
  --- don't mark the stash as used.
  ---@param chestPeripheral ccTweaked.peripheral.wrappedPeripheral
  ---@param slot integer
  local function stashItem(chestPeripheral, slot)
    -- First try the last-moved gem's original location.
    --FIXME: Factor out the stash slot handling.
    if stash.chestName == nil then
      -- The stash slot has not been set yet.
      -- Check the storage chests for an empty slot.
      -- Work last to first, since later slots and
      -- chests are more likely to be empty.
      for chestIdx = #storageChestNames, 1, -1 do
        for s = storageChestsIdx[chestIdx].size, 1, -1 do
          -- Since the stash has not yet been set,
          -- we can safely assume that this is the
          -- first iteraton and can trust the
          -- cached list to determine emptiness.

          local list = storageChestsIdx[chestIdx].list
          if list[s] == nil then
            stash.chestName = storageChestsIdx[chestIdx].name
            stash.slotNum = s
            goto foundEmptySlot -- is this still considered harmful?
          end
        end
      end
      -- No empty slot found in storage chests.
      -- Move the gem to the input chest and never look back at it.
      -- (Don't set stashedGem true, since we won't be retrieving it.)
      local movedItems = moveToInputChest(chestPeripheral, slot)
      return movedItems
    end
    ::foundEmptySlot::
    -- Move the gem and mark the stash as being used.
    local movedItems = chestPeripheral.pushItems(
    stash.chestName,
    slot,
    maxInt,
    stash.slotNum)
    stash.used = true
    return movedItems
  end

  --- If necessary, call fixSlot on the stash slot and then update the stash to point to the appropriate empty slot.
  ---@param destChestName string
  ---@param destSlot integer
  ---@return nil
  local function updateStash(destChestName, destSlot)
    if stash.used then
      -- Put the stashed gem where it belongs.
      local fromChestPeripheral = storageChests[stash.chestName].peri

      fromChestPeripheral.pushItems(
        destChestName,
      stash.slotNum,
        maxInt,
        destSlot)
      -- Keep the stash slot where it is since we just vacated it.
    else
      if not stash.keep then
        -- Update the stash to the just-vacated slot.
        stash.chestName = destChestName
        stash.slotNum = destSlot
      end
    end
    stash.used = false
    stash.keep = false
  end



  -- Mark slots that have already been visited.
  -- Used to save calls to expensive API functions.
  -- We do not need to visit these again as they
  -- are guarunteed to already be where they
  -- belong.  The outer table is keyed by chest
  -- name. Its values are a set of slot numbers (a
  -- table whose key is a slot and value is either
  -- true or nil, depending on whether it has been
  -- visited.).
  ---@type table<string, table<integer, boolean>>
  local visitedSlots = {}

  ---A set that tracks marked slots.
  ---mt\[chestName\]\[slot\] = true if marked, nil otherwise.
  ---@alias markTable table<string, table<integer, boolean>>

  -- Mark a slot in a table of marks.
  -- Used to mark visited slots and detect cycles.
  ---@param markTable markTable
  ---@param chestName string
  ---@param slot integer
  ---@return nil
  local function markSlot(markTable, chestName, slot)
    if markTable[chestName] == nil then
      markTable[chestName] = {}
    end
    markTable[chestName][slot] = true
  end

  -- Test if a slot has been marked.
  ---@param markTable markTable
  ---@param chestName string
  ---@param slot integer
  ---@return boolean
  local function isMarked(markTable, chestName, slot)
    if markTable[chestName] == nil then
      return false
    end
    return markTable[chestName][slot] == true
  end

  fixSlot = function (fromChestName, fromChestPeripheral, fromSlot, seenSlots)
    local fromItem = fromChestPeripheral.getItemDetail(fromSlot)
    if fromItem == nil then
      -- No item in this slot.
      return 0
    end
    if fromItem.name ~= "apotheosis:gem" then
      -- Not a gem, move to input chest.
      return moveToInputChest(fromChestPeripheral, fromSlot)
    end

    -- Parse the gem name.
    local displayName = fromItem.displayName
    local typeName, tier = parseGemName(displayName)
    local gemRecord = gemTypes[typeName]
    if gemRecord == nil then
      -- Unknown gem type, kick it back to input chest.
      return moveToInputChest(fromChestPeripheral, fromSlot)
    end
    local destChestName = gemRecord.chestName
    local destSlot = getTierOffset(gemRecord.startSlot, tier)

    -- If the gem is already where it belongs,
    -- don't move it and flag to keep the old stash
    -- slot.
    if fromChestName == destChestName
      and fromSlot == destSlot
    then
      stash.keep = true
      return fromItem.count
    end

    markSlot(seenSlots, fromChestName, fromSlot)
    -- Check for cycles.
    if isMarked(seenSlots, destChestName, destSlot) then
      -- Cycle detected.
      -- Move the current gem into the stash.
      -- NOTE: It is important to move this
      --       particular gem because it belongs in
      --       the slot given as the argument to
      --       the top-level call. We will later
      --       use that fact to move the stashed
      --       gem to that slot.
      return stashItem(fromChestPeripheral, fromSlot)
    end

    -- Try to move the current gem.
    local movedItems = fromChestPeripheral.pushItems(
      destChestName,
      fromSlot,
      maxInt,
      destSlot)

    if movedItems < fromItem.count then
      -- Destination slot not empty.
      -- Recursively move the blocking gem.
      local destChestPeripheral = storageChests[destChestName].peri
      local blockedMovedItems =
        fixSlot(destChestName, destChestPeripheral, destSlot, seenSlots)
      if blockedMovedItems > 0 then
        -- Try again to move the original gem.
        local finalMovedItems = fromChestPeripheral.pushItems(
          destChestName,
          fromSlot,
          maxInt,
          destSlot)
        if finalMovedItems + movedItems < fromItem.count
        then
          -- Still could not move all items.
          -- Dump the remainder into the input chest.
          return moveToInputChest(fromChestPeripheral, fromSlot)
        end
        -- Successfully moved all items.
      end
    end
    markSlot(visitedSlots, destChestName, destSlot)
    return fromItem.count
  end



  ------- main repair loop ----
  for chestIdx = 1, #storageChestNames do
    local fromChestName = storageChestNames[chestIdx]
    local fromChestPeripheral = storageChests[fromChestName].peri
    for fromSlot, _ in pairs(storageChests[fromChestName].list) do
      if not isMarked(visitedSlots,
                      fromChestName,
                      fromSlot) then
        fixSlot(fromChestName,
                fromChestPeripheral,
                fromSlot, {})
        -- Update the stash
        updateStash(fromChestName,
                    fromSlot)
      end
    end
  end
end

if arg[1] == "repair" then
  local elapsed, ok, err = time(repairSortedChests)
  if not ok then
    error(err)
  end
  print(string.format(
    "Repair sorted chests completed in %.3f seconds.",
    elapsed))
  return
end

if arg[1] == "loop" then
  sleepSeconds = tonumber(arg[2]) or sleepSeconds
  while true do
    local elapsed, ok, err = time(storeGems)
    if not ok then
      error(err)
    end
    print(string.format(
      "Sorting pass completed in %.3f seconds.",
      elapsed))
    sleep(sleepSeconds)
  end
end

-- Single pass mode
local elapsed, ok, err = time(storeGems)
if not ok then
  error(err)
end
print(string.format(
  "Sorting pass completed in %.3f seconds.",
  elapsed))
