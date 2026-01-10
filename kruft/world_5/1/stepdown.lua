-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel shell
-- Written for CC:Tweaked

-- build a floating block stairs going downwards
-- TODO: add support for upwards.

local count = tonumber(arg[1]) or 1

local function findBlock()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
        turtle.select(slot)
        return true
        end
    end
    return false
end

for _ = 1, count do
  if not findBlock() then
    print("Out of blocks!")
    return
  end
  turtle.dig()
  turtle.forward()
  turtle.digDown()
  turtle.down()
  turtle.placeDown()
end

-- Go back home.
for _ = 1, count do
  turtle.up()
  turtle.back()
end
