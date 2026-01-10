-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg settings sleep
-- Written for CC:Tweaked
-- Walk backwards placing blocks behind you.

-- Where to keep the fuel.
local fuelSlot = 16

local t = turtle

local length = tonumber(arg[1]) or 1

-- Find the first non-empty slot.
local function findFirstNonEmptySlot()
  for slot = 1, 16 do
    -- Skip fuel slot.
    if slot ~= fuelSlot then
      if t.getItemCount(slot) > 0 then
        return slot
      end
    end
  end
  return nil
end

for _ = 1, length do
  local slot = findFirstNonEmptySlot()
  if slot == nil then
    print("Out of blocks to place!")
    while slot == nil do
      print("Waiting for blocks...")
      sleep(5)
      slot = findFirstNonEmptySlot()
    end
  end

  t.select(slot)
  t.back()
  t.place()
end
