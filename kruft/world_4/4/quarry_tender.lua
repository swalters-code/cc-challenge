-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg settings sleep
-- Written for CC:Tweaked

-- Collect items from the quarry dump chest and
-- move them to the inventories below that chest.
-- Wait at the input chest until items are
-- available.  Move to the bottom inventory (so
-- that drawers can be below chests and thus not
-- block them.) Place as many items as you can into
-- the inventories, one at a time.
--

-- How far down to go to get to the last inventory.

local t = turtle

local depth = tonumber(arg[1]) or 12
local idleTime = 15

local function inventoryFull()
  for slot = 1, 15 do
    t.select(slot)
    if t.getItemCount(slot) == 0 then
      return false
    end
  end
  return true
end

local function pullInItems()
  -- Wait until we can suck in items into slot 1.
  t.select(1)
  while t.getItemCount(1) == 0 do
    sleep(idleTime)
    t.suck()
  end
  for i = 2, 15 do
    t.select(i)
    t.suck()
  end
end

local function goToBottom()
  for _ = 1, depth - 1 do
    t.down()
  end
end

local function depositItems()
  for slot = 1, 15 do
    t.select(slot)
    t.drop()
  end
end

while true do
  local firstFuel = t.getFuelLevel()
    pullInItems()
  if not inventoryFull() then
    sleep(idleTime)
  else
    goToBottom()
    for _ = 1, depth - 1 do
      depositItems()
      t.up()
    end
  end
  local lastFuel = t.getFuelLevel()
  local fuelUsed = firstFuel - lastFuel
  print("Fuel: " .. lastFuel .. " (used " .. fuelUsed .. ")")
end
