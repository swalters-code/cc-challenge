-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel shell
-- Written for CC:Tweaked

-- Drop an anvil on books and enchanted tools.

-- TODO: Add a chest above for input and reading
--       the enchants on a item.

local anvilSlot = 1
local bookSlot = 2

local itemCount = 0

for slot = 1, 16 do
  if slot ~= anvilSlot
    and slot ~= bookSlot
      and turtle.getItemCount(slot) > 0
  then
    turtle.select(slot)
    turtle.dropDown(1)
    turtle.select(bookSlot)
    turtle.dropDown(1)
    turtle.select(slot)
    itemCount = itemCount + 1
  end
end

if itemCount > 0 then
  turtle.select(anvilSlot)
  turtle.placeDown()
  sleep(2)
  turtle.down()
  turtle.digDown()
  turtle.suckDown()
  turtle.down()
  -- FIXME: Only sucks one item at a time. Keep sucking.
  turtle.suck()
  turtle.up()
  turtle.up()
end
