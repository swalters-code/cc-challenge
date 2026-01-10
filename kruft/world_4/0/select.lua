-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg
-- Select a turtle slot
-- Written for CC:Tweaked

if #arg < 1 then
    print("Usage: select <slot>")
    return
end
local slot = tonumber(arg[1])
if slot == nil or slot < 1 or slot > 16 then
    print("Invalid slot: " .. arg[1])
    return
end
turtle.select(slot)
