-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg
-- A ridiculously simple and naive tree farm program.
-- Written for CC:Tweaked

-- Logs in slot 1, saplings slot 2, fuel slot 16.

-- If you're using oak trees, place a slab, fence
-- or glass 6 to 8 blocks above the sapling to
-- prevent large oak growth.

-- TODO: Add code to place a slab, fence or glass above oak saplings.
-- TODO: Add code to detect what features to use.
-- TODO: Allow sapling consilidation.
-- TODO: Use sticks for fuel.
-- TODO: Add use of a furnace below the turtle for charcoal production.
-- TODO: Allow overflow saplings to be used for fuel.

while true do
    -- Plant a tree in front of the turtle.
    turtle.select(2)
    if not turtle.compare() then
        turtle.place()
    end
    -- Wait for the tree to grow.
    turtle.select(1)
    -- While the block in front of you is not a log, wait.
    while not turtle.compare() do
        sleep(1)
    end
    -- When the block in front of you is a log, dig it and any blocks above it.
    turtle.dig()
    turtle.forward()
    while turtle.compareUp() do
        turtle.digUp()
        turtle.up()
    end
    -- Return to the ground
    while not turtle.inspectDown() do
        turtle.down()
    end
    -- TODO: Factor suck in all directions code.
    -- TODO: write code to advance one  turn forward
    -- Suck in each direction
    turtle.suck()
    turtle.turnLeft()
    turtle.suck()
    turtle.turnLeft()
    turtle.suck()
    turtle.turnLeft()
    turtle.suck()
    turtle.turnLeft()
    -- move back to the starting position.
    turtle.back()
    -- Suck some more
    turtle.turnLeft()
    turtle.suck()
    turtle.turnLeft()
    turtle.suck()
    turtle.turnLeft()
    turtle.suck()
    turtle.turnLeft()
    turtle.suck()
    -- Refuel if needed
    if turtle.getFuelLevel() < 20 then
        turtle.select(16)
        turtle.refuel(1)
    end
end

