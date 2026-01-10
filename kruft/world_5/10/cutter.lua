-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel shell
-- Written for CC:Tweaked

-- Operate a cutting board

-- TODO: Add support for input chest
-- TODO: Add support for multiple tools
--       predicated on item being cut.

local sleepTime = 10
local toolSlot = 1

for slot = 1, 16 do
  if slot ~= toolSlot
    and turtle.getItemCount(slot) > 0
  then
    turtle.select(slot)
    turtle.drop()
    turtle.select(toolSlot)
    turtle.place()
  end
end
