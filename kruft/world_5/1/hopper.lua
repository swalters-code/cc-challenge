-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel shell
-- Written for CC:Tweaked

-- Look at me!
-- I'm a turtle!
-- I'm a hopper!
-- I'm a topper!

-- I use suck and drop to move items between
-- inventories, pick them up from the world, or
-- spew them everywhere. If the machine I'm feeding
-- won't accept the items I'm trying to shove into
-- them, then I just spew them out into the
-- world. Whee!

-- Usage: "topper <in> <out> [sleepTime]"

local input = arg[1] or "top"
local output = arg[2] or "bottom"
local sleepTime = 5 or tonumber(arg[3])

-- FIXME: Add a way to hold the items in the
--        turtle.  Right now it spits them out into
--        the world while waiting for the inventory
--        to clear.

-- TODO: Change to a manual squeezer mechanism
--       (measure state and emit a redstone pulse
--       when done squeezing.)
-- TODO: Add support for turning for input/output sides.
-- TODO: Add support for whitelisting/blacklisting item types.


directions = {
    ["top"] = true,
    ["bottom"] = true,
    ["front"] = true,
    -- ["back"] = true,
    -- ["left"] = true,
    -- ["right"] = true,
}

if not directions[input] then
    error("Invalid input direction: " .. input)
end

if not directions[output] then
    error("Invalid output direction: " .. output)
end

while true do
    local workToDo = false
    if input == "top" then
        turtle.suckUp()
    elseif input == "bottom" then
        turtle.suckDown()
    else
        turtle.suck()
    end
    for i = 1,16 do
        turtle.select(i)
        local count = turtle.getItemCount(i)
        if count > 0 then
            workToDo = true
            if output == "top" then
                turtle.dropUp()
            elseif output == "bottom" then
                turtle.dropDown()
            else
                turtle.drop()
            end
        end
    end
    if not workToDo then
        sleep(sleepTime)
    end
end
