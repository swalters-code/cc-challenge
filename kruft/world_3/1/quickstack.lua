-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals textutils rednet os peripheral

-- CC:Tweaked program to manage a bank of chests.

-- It will look at each item in an input chest and
-- move it to the appropriate chest if and only if
-- there is already one of that item in the chest.
-- This let's you manually control which chest each
-- type of item goes into by placing one of that
-- type in the intended destination by by putting
-- one of that item in the chest first.


-- For debugging:
local pretty = require("cc.pretty")

-- Pretty-print a data structure to the screen
-- luacheck: ignore pp unused
local function pp(data)
  textutils.pagedPrint(pretty.render(pretty.pretty(data),51))
end


-- Configuration

-- TODO: Move this to a config file and write a setup script.
-- A list of the names input chests
local inputChestNames = {
  "ironchest:obsidian_chest_2"
}

-- a list of the names of storage chests
local storageChestNames = {
  "ironchest:diamond_chest_0",
  "ironchest:diamond_chest_1",
  "ironchest:diamond_chest_2",
  "ironchest:diamond_chest_3",
  "ironchest:diamond_chest_4",
  "ironchest:diamond_chest_5",
  "ironchest:diamond_chest_6",
  "ironchest:diamond_chest_7",
  "ironchest:diamond_chest_8",
  "ironchest:diamond_chest_9",
  "ironchest:diamond_chest_10",
  "ironchest:diamond_chest_11",
  "ironchest:diamond_chest_12",
  "ironchest:diamond_chest_13",
  "ironchest:diamond_chest_14",
  "ironchest:diamond_chest_15"
}

-- the location of the monitor, or nil if none.
-- luacheck: ignore monitorSide unused
local monitorSide = "top"
local POLL_SECONDS = 2 -- how often to poll the input chests
local modemSide = "bottom"

-- wrap each of the chests in inputChestNames and storageChestNames
local inputChests = {}
for _, chestName in ipairs(inputChestNames) do
  -- FIXME: handle errors during wrapping.
  table.insert(inputChests, peripheral.wrap(chestName))
end

local storageChests = {}
for _, chestName in ipairs(storageChestNames) do
  -- FIXME: handle errors during wrapping.
  table.insert(storageChests, peripheral.wrap(chestName))
end

-- Find the first storage that contains at least one of the given item.
-- itemName (string): namespaced item id, e.g. "minecraft:stone"
-- Returns:
--   number, nil      - index of first storage that has >= 1 of the item
--   nil, nil         - item not found in any storage
--   nil, string      - an error occurred; string describes the error
-- TODO: handle full chests
-- TODO: have this return a list of chests.
-- TODO: read up on iterators and consider using one here.
local function findChestsWithItem(itemName)
  -- look in each storage chest
  for idx, chest in ipairs(storageChests) do
    local items = chest.list()
    for _, destItem in pairs(items) do
      if itemName == destItem.name then
        -- TODO: Verify that there is room for more of this item.
        return idx
    end -- end if itemName == destItem.name
  end  -- end for each item in chest
end -- end for each chest
  return nil, nil -- not found
end -- end function findChestWithItem

-- move an item stack from one chest to another
-- fill in any partial stacks first.
-- srcSlot  (int): slot number in srcChest
-- iSrcChest (int): index of source chest
-- iDstChest   (int): index of destination chest
-- Returns:
--   number, nil - number of items left over that
--                 could not be moved
--   nil, string - an error occurred; string
--                 describes the error

-- used when we have determined that a chest
-- contains at least some of the item.

local function
  moveItemStack(srcSlot, iSrcChest, iDstChest)

  local srcChestPeriph = inputChests[iSrcChest]
  -- FIXME: If everything works, remove this unused variable.
  -- luacheck: ignore srcChestName unused
  local srcChestName = peripheral.getName(srcChestPeriph)
  local srcItemDetails = srcChestPeriph.getItemDetail(srcSlot)
  local srcItemName = srcItemDetails.name
  local dstChestPeriph = storageChests[iDstChest]
  local dstChestName = peripheral.getName(dstChestPeriph)

  local remainingToMove = srcItemDetails.count

  -- used to hold pcall results
  local ok, result

  ok, result = dstChestPeriph.list()
  if not ok then
    return nil,
      "Error listing destination chest: \n" .. result
  end
  local dstChestList = result

  -- first, look for partial stacks to fill
  for dstSlot, dstItem in pairs(dstChestList) do
    if srcItemName == dstItem.name then
      -- found a matching item, check for partial stack
      if dstItem.count < dstChestPeriph.getItemLimit(dstSlot) then
        -- move items into the partial stack
        ok, result = pcall(
        srcChestPeriph.pushItems,
        dstChestName,
        srcSlot,
        remainingToMove,
        dstSlot)
        if not ok then
          -- FIXME: should we abort the whole move here?
          print("Error during pushItems: " .. result)
          break
        end
        remainingToMove = remainingToMove - result
        if remainingToMove == 0 then
          -- all items moved
          return 0, nil
        end
        -- end if partial stack
      end
      -- end if matching item
    end
    -- end for each dstSlot
  end

  -- if we get here, there are still items to move
  ok, result = pcall(
  srcChestPeriph.pushItems,
  dstChestName,
  srcSlot)
  if not ok then
    return nil, "Error during pushItems to empty slots: \n" .. result
  end
  remainingToMove = remainingToMove - result
  return remainingToMove, nil
  -- end function moveItemStack
end


-- Open the modem for rednet communication
-- TODO: handle errors during rednet.open
rednet.open(modemSide)

-- set up the first timer
local pollTimerID = os.startTimer(POLL_SECONDS)

while true do
  -- Wait for an event.
  local event, timerOrSenderID = os.pullEvent()

  if event == "timer" and timerOrSenderID == pollTimerID then
    -- look for items in each input chest
    -- TODO: write the main loop.
    -- reset the timer
    pollTimerID = os.startTimer(POLL_SECONDS)
  end
  -- handle other events here
end

