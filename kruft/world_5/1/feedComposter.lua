-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel shell
-- Written for CC:Tweaked

-- Feed a composter from an input chest, place output into output
-- chest.

-- Turtles can only suck items out of a composter on the top side,
-- and a composter cannot be wrapped as a peripheral.

-- TODO: Add blacklisting/whitelisting of items to compost.

local inputChestSide = "front"
local outputChestSide = "bottom"
local sleepTime = 15

print("Taking from chest on " .. inputChestSide ..
  " and outputting to chest on " .. outputChestSide)

local inputSlot = 1
local outputSlot = 2

local function suckInput()
  if turtle.getItemCount(inputSlot) > 0 then
    return
  end
  turtle.select(inputSlot)
  if inputChestSide == "bottom" then
    return turtle.suckDown()
  elseif inputChestSide == "front" then
    return turtle.suck()
  end
  error("Invalid input chest side: " .. inputChestSide)
end

local function dropOutput()
    turtle.select(outputSlot)
  if outputChestSide == "bottom" then
    return turtle.dropDown()
  elseif outputChestSide == "front" then
    return turtle.drop()
  end
  error("Invalid output chest side: " .. outputChestSide)
end

local function suckBoneMeal()
    turtle.select(outputSlot)
    return turtle.suckUp()
end

local function dropComposter()
    turtle.select(inputSlot)
    turtle.placeUp()
end

while true do
    -- Suck input items
    suckInput()
    local inputCount = turtle.getItemCount(inputSlot)
  if inputCount > 0 then
    dropComposter()
    local ok, data = turtle.inspectUp()
    print(data.state.level)
    if data.state.level >= 7 then
        suckBoneMeal()
        dropOutput()
    end
  else
    sleep(sleepTime)
  end
end
