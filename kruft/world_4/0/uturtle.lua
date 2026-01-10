-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg sleep
-- Written for CC:Tweaked

-- A utility library for turtles.

-- Provides:
-- TODO: Turtle movement tracking.
--   Uses GPS if available, otherwise tracks movement internally.
-- TODO: Turtle movement with retries and optional attacking.
-- Turtle fuel management.
-- Automatic refueling from inventory.
-- Pausing to return for fuel.
-- Item selection by name.
-- Quarry item categorization
--

local uturtle = {}

-- Pull in the turtle API since we pretend to be that.
for k, v in pairs(turtle) do
  uturtle[k] = v
end
-- We'll be overriding many of these below.

--- Location and direction relative to the starting point.
uturtle.state = {
  -- Positive forward, negative for backward
  x = 0,
  -- Height, positive up, negative down
  h = 0,
  -- Positive to the right, negative to the left
  z = 0,
  -- Direction, 0 = forward, 1 = right, 2 = back, 3 = left
  -- Clockwise while looking down on the turtle.
  d = 0,
}

--- Reset the turtle state to the origin facing forward.
---
function uturtle.setStart()
  uturtle.state.x = 0
  uturtle.state.h = 0
  uturtle.state.z = 0
  uturtle.state.d = 0
end

---Attack things when we can't move forward.
---@type boolean
uturtle.aggroMoves = true

-- Number of seconds to sleep between dig retries.
-- Useful for blocks that fall, like gravel or sand.
uturtle.digRetrySleep = 0.5
-- Number of seconds to sleep between attack retries.
uturtle.attackRetrySleep = 0.5

---Number of times to retry a movement before giving up.
---Set to zero to disable retries.
---@type number
uturtle.retryCount = 5

-- TODO: Return number of blocks moved.
---Move the turtle forward a given number of times.
---@param count integer The number of times to move forward. Defaults to 1.
---@return integer The number of successful moves.
function uturtle.forward(count)
  count = count or 1
  for _ = 1, count do
    -- Start from 0 so that we try at least once.
    for _ = 0, uturtle.retryCount do
      if not turtle.forward() then
        if turtle.detect() then
          turtle.dig()
          turtle.sleep(uturtle.digRetrySleep)
        else
          if uturtle.aggroMoves then
            turtle.attack()
          else
            sleep(uturtle.attackRetrySleep)
          end
        end
      else
        -- Successful move, update state and break out of retry loop.
        if uturtle.state.d == 0 then
          uturtle.state.x = uturtle.state.x + 1
        elseif uturtle.state.d == 1 then
          uturtle.state.z = uturtle.state.z + 1
        elseif uturtle.state.d == 2 then
          uturtle.state.x = uturtle.state.x - 1
        elseif uturtle.state.d == 3 then
          uturtle.state.z = uturtle.state.z - 1
        end
        break
      end
    end
  end
end

-- TODO: Return number of blocks moved.
---Move the turtle backward a given number of times.
--- If the turtle cannot move backword, it will
--- turn around and dig and/or attack whatever is blocking it.
---@param count integer The number of times to move forward. Defaults to 1.
---@return integer The number of successful moves.
function uturtle.back(count)
  count = count or 1
  local turnedAround = false
  local moveSuccess
  for _ = 1, count do
    -- Start from 0 so that we try at least once.
    for _ = 0, uturtle.retryCount do
      if turnedAround
      then
        moveSuccess = turtle.forward()
      else
        moveSuccess = turtle.back()
      end
      if not moveSuccess then
        if not turnedAround then
          -- Turn around once.
          uturtle.turnLeft()
          uturtle.turnLeft()
          turnedAround = true
        end
        if uturtle.detect() then
          uturtle.dig()
          sleep(uturtle.digRetrySleep)
        else
          if uturtle.aggroMoves then
            turtle.atack()
          else
            sleep(uturtle.attackRetrySleep)
          end
        end
      else
        -- Successful move, update state and break out of retry loop.
        if not turnedAround then
          -- We moved backward without turning around.
          if uturtle.state.d == 0 then
            uturtle.state.x = uturtle.state.x - 1
          elseif uturtle.state.d == 1 then
            uturtle.state.z = uturtle.state.z - 1
          elseif uturtle.state.d == 2 then
            uturtle.state.x = uturtle.state.x + 1
          elseif uturtle.state.d == 3 then
            uturtle.state.z = uturtle.state.z + 1
          end
        else -- We turned around and moved forward.
          if uturtle.state.d == 0 then
            uturtle.state.x = uturtle.state.x + 1
          elseif uturtle.state.d == 1 then
            uturtle.state.z = uturtle.state.z + 1
          elseif uturtle.state.d == 2 then
            uturtle.state.x = uturtle.state.x - 1
          elseif uturtle.state.d == 3 then
            uturtle.state.z = uturtle.state.z - 1
          end
        end
        break
      end
    end
    if turnedAround then
      -- Turn back to original direction.
      uturtle.turnLeft()
      uturtle.turnLeft()
      turnedAround = false
    end
  end
end

--- Select the first slot containing the given item name.
--- @param itemName string The item name to search for.
--- @return number|boolean The slot number if found, false otherwise.
function uturtle.selectItem(itemName)
  for slot = 1, 16 do
    local itemDetail = turtle.getItemDetail(slot)
    if itemDetail and itemDetail.name == itemName then
      turtle.select(slot)
      return slot
    end
  end
  return false
end
