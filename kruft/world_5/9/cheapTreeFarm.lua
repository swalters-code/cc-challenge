-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel shell
-- Written for CC:Tweaked

-- Simple script to cut down trees in a grid pattern.

-- The turtle starts at one corner of the grid.
-- The grid extends in front and to the lft fo the
-- turtle. This is the mirror of the planting
-- script, so that the turtle ends up ready to
-- plant trees after cutting them down.

-- length and width of the grid in number of trees
local length = 6
local width = 5

-- The number of spaces BETWEEN trees.
local spacing = 2

local t = turtle

for i = 1, width do
    for j = 1, length do
        shell.run("log.lua")
        if j ~= length then
            for _ = 1, spacing do
                t.forward()
            end
        end
    end
    -- Turn around at the end of the row.
    if i ~= width then
        t.forward()
        if i % 2 == 1 then
            t.turnLeft()
        else
            t.turnRight()
        end
        for _ = 1, spacing do
            t.forward()
        end
        t.forward()
        if i %2 == 1 then
            t.turnLeft()
        else
            t.turnRight()
        end
    end
end

-- Get in position for planting
t.back()
