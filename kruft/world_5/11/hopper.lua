-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel shell
-- Written for CC:Tweaked


-- Look at me! I'm a hopper!
-- Usage: "hopper <in> <out> [sleepTime]"

local input = arg[1] or "top"
local out = arg[2] or "bottom"
local sleepTime = 5 or tonumber(arg[3])

-- TODO: Add support for turning for input/output sides.

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

if not directions[out] then
    error("Invalid output direction: " .. out)
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
            if out == "top" then
                turtle.dropUp()
            elseif out == "bottom" then
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
