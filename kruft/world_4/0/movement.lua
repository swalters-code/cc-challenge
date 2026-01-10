-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- Written for CC:Tweaked

-- Incorrect Code Behavior:

-- goTo uses wrong turnTo calls: turnTo(left) for
-- +x (turns to -z instead), turnTo(forward) for +z
-- (turns to +x instead), etc., causing incorrect
-- navigation.

-- back manually calls turtle.turnLeft() twice
-- without updating state.heading, leading to state
-- desync during retries (uses original heading
-- instead of turned one).

-- down has inconsistent indentation (extra spaces
-- on some lines).

-- Non-Concordant Comments/Code:

-- state.heading comment says "0 = forward (+z)",
-- but code/inline implements 0 as +x.

-- back doc param says "move forward", should be
-- "backward".

-- getState doc omits heading in returns.

-- goTo comment says "nill", should be "nil".

-- Likely Typos:

-- "positivve" in state.z comment (positive).
-- "backword" in back doc (backward).


-- A library to keep track of turtle movement.f

-- TODO: Add move functions that call a
--       user-defined function after each
--       successful move.

-- TODO: Add waypoint support.

-- TODO: Add support for negative move counts and turns.

local movement = {}

movement.config = {
  -- Number of times to retry a movement before giving up.
  -- Set to zero to disable retries.
  ---@type number
  moveRetries = 3,
  -- Dig on front when we can't move forward.
  -- Defaults to false to avoid destructive defaults.
  ---@type boolean
  digMoves = false,
  -- Attack things when we can't move forward.
  -- Defaults to false to avoid destructive defaults.
  ---@type boolean
  aggroMoves = false,
  -- Number of seconds to sleep between dig retries.
  -- Useful for blocks that fall, like gravel or sand.
  ---@type number
  digRetrySleep = 0.5,
  -- Number of seconds to sleep between attack retries.
  ---@type number
  attackRetrySleep = 0.5,
}

-- Internal representation of the turtle's position.
local state = {
  -- This stupid scheme matches the one in Minecraft.
  -- forward positive
  ---@type integer
  x = 0,
  -- vertical, positive up
  ---@type integer
  y = 0,
  -- right positivve
  ---@type integer
  z = 0,
  -- Clockwise direction while looking down on the turtle.
  -- 0 = forward (+z), 1 = right (+x), 2 = back (-z), 3 = left (-x)
  ---@type integer
  heading = 0, -- 0 = +x, 1 = +z, 2 = -x, 3 = -z
}

-- Direction constants for clarity.

-- Pointed forward (+x)
local forward = 0
-- Pointed right (+z)
local right = 1
-- Pointed backward (-x)
local backward = 2
-- Pointed left (-z)
local left = 3


--- Get the current turtle state relative to the start.
---@return integer x The position in the forward axis
---@return integer y The position in the vertical axis
---@return integer z The position in the right axis
local function getState()
  return state.x, state.y, state.z, state.heading
end

local function setState(x, y, z, heading)
  state.x = x
  state.y = y
  state.z = z
  state.heading = normHeading(heading)
end

-- Reset the turtle state to the origin facing forward.
--- TODO: Allow setting this to a waypoint or an arbitrary position.
---@return nil
local function setStart()
  setState(0, 0, 0, 0)
end

--- Normalize a heading to 0-3
---@param dir integer The direction to normalize
---@return integer The normalized direction
local function normHeading(dir)
  return ((dir % 4) + 4) % 4
end
local deltas = {
  -- heading = 0: +x (forward)
  [0] = { x = 1, z = 0 },
  -- heading = 1: +z (right)
  [1] = { x = 0, z = 1 },
  -- heading = 2: -x (backward)
  [2] = { x = -1, z = 0 },
  -- heading = 3: -z (left)
  [3] = { x = 0, z = -1 },
}

--- Turn the turtle to the right (clockwise) by argument steps.
---@param steps integer Number of turns to make.
---@return nil
local function turnRight(steps)
  steps = steps % 4
  if steps == 0 then
    return
  elseif steps == 1 then
    turtle.turnRight()
    state.heading = normHeading(state.heading + 1)
  elseif steps == 2 then
    turtle.turnRight()
    turtle.turnRight()
    state.heading = normHeading(state.heading + 2)
  else -- steps == 3
    turtle.turnLeft()
    state.heading = normHeading(state.heading - 1)
  end
end

--- Turn the turtle to the left (counter-clockwise) by argument steps.
---@param steps integer Number of turns to make.
local function turnLeft(steps)
  steps = steps % 4
  if steps == 0 then
    return
  elseif steps == 1 then
    turtle.turnLeft()
    state.heading = normHeading(state.heading - 1)
  elseif steps == 2 then
    turtle.turnLeft()
    turtle.turnLeft()
    state.heading = normHeading(state.heading - 2)
  else -- steps == 3
    turtle.turnRight()
    state.heading = normHeading(state.heading + 1)
  end
end

--- Turn the turtle to face targetHeading.
---@param targetHeading integer The heading to face.
---@return nil
local function turnTo(targetHeading)
  local delta = normHeading(targetHeading - state.heading)
  if delta == 0 then
    return
  elseif delta == 1 then
    turnRight(1)
  elseif delta == 2 then
    turnRight(2)
  else -- delta == 3
    turnLeft(1)
  end
end
--- Move the turtle forward count times, updating state.
---@param count integer The number of times to move forward. Defaults to 1.
---@return integer The number of successful moves.
local function forward(count)
  count = count or 1
  -- How many times we were actually able to move forward.
  local successfulMoves = 0
  for _ = 1, count do
    local gaveUp = true
    -- Start from 0 so that we try at least once.
    for _ = 0, movement.config.moveRetries do
      if not turtle.forward() then
        if movement.config.digMoves
          and turtle.detect()
        then
          turtle.dig()
          sleep(movement.config.digRetrySleep)
        else
          if movement.config.aggroMoves then
            turtle.attack()
          else
            sleep(movement.config.attackRetrySleep)
          end
        end
      else
        -- Successful move, update state and break out of retry loop.
        local delta = deltas[normHeading(state.heading)]
        state.x = state.x + delta.x
        state.z = state.z + delta.z
        successfulMoves = successfulMoves + 1
        gaveUp = false
        break
      end
    end
    if gaveUp then
      return successfulMoves
    end
  end
  return successfulMoves
end


--- Move the turtle backward count times, updating
--- state.  If the turtle cannot move backword, it
--- will turn around and dig and/or attack whatever
--- is blocking it.  It will not turn back until it
--- has reached its destination, or it has
--- exhausted its retries.
---@param count integer The number of times to move forward. Defaults to 1.
---@return integer The number of successful moves.
local function back(count)
  count = count or 1
  -- How many times we were actually able to move backward.
  local successfulMoves = 0
  --- Did we turn around to attack/dig?
  local turnedAround = false
  for _ = 1, count do
    local gaveUp = true
    -- Start from 0 so that we try at least once.
    for _ = 0, movement.config.moveRetries do
      local moveSuccess
      if turnedAround then
        moveSuccess = turtle.forward()
      else
        moveSuccess = turtle.back()
      end
      if not moveSuccess then
        if not turnedAround then
          -- FIXME: Figure out if I should be using
          --        the new turn code. (which
          --        updates heading)
          turtle.turnLeft()
          turtle.turnLeft()
          turnedAround = true
        end
        if movement.config.digMoves
          and turtle.detect()
        then
          turtle.dig()
          sleep(movement.config.digRetrySleep)
        else
          if movement.config.aggroMoves then
            turtle.attack()
          else
            sleep(movement.config.attackRetrySleep)
          end
        end
      else
        -- Successful move, update state and break out of retry loop.
        local delta = deltas[normHeading(state.heading)]
        state.x = state.x - delta.x
        state.z = state.z - delta.z
        successfulMoves = successfulMoves + 1
        gaveUp = false
        break
      end
    end
    if gaveUp then
      if turnedAround then
        -- Turn back to original heading.
        turtle.turnLeft()
        turtle.turnLeft()
      end
      return successfulMoves
    end
  end
  if turnedAround then
    -- Turn back to original heading.
    turtle.turnLeft()
    turtle.turnLeft()
  end
  return successfulMoves
end

local function up(count)
  count = count or 1
  local successfulMoves = 0
  for _ = 1, count do
    local gaveUp = true
    for _ = 0, movement.config.moveRetries do
      if not turtle.up() then
        if movement.config.digMoves
          and turtle.detectUp()
        then
          turtle.digUp()
          sleep(movement.config.digRetrySleep)
        else
          if movement.config.aggroMoves then
            turtle.attackUp()
          else
            sleep(movement.config.attackRetrySleep)
          end
        end
      else
        state.y = state.y + 1
        successfulMoves = successfulMoves + 1
        gaveUp = false
        break
      end
    end
    if gaveUp then
      return successfulMoves
    end
  end
  return successfulMoves
end

local function down(count)
    count = count or 1
    local successfulMoves = 0
    for _ = 1, count do
        local gaveUp = true
        for _ = 0, movement.config.moveRetries do
        if not turtle.down() then
            if movement.config.digMoves
            and turtle.detectDown()
            then
            turtle.digDown()
            sleep(movement.config.digRetrySleep)
            else
            if movement.config.aggroMoves then
                turtle.attackDown()
            else
                sleep(movement.config.attackRetrySleep)
            end
            end
        else
            state.y = state.y - 1
            successfulMoves = successfulMoves + 1
            gaveUp = false
            break
        end
        end
        if gaveUp then
        return successfulMoves
        end
    end
    return successfulMoves
end

-- Go to a position relative to the start.
-- If h is nill, do not manage heading.
-- Travels first in the y, then x, then z axes.
-- TODO: Allow goto relative to current position.
-- TODO: Allow specifying a waypoint.
-- TODO: Handle travel failure.
local function goTo(x, y, z, h)
  -- TODO: If we're blocked, switch to a different axis.
  local cX, cY, cZ, _ = getState()
  if y > cY then
    up(y - cY)
  elseif y < cY then
    down(cY - y)
  end
  if x > cX then
    turnTo(left)     -- +x
    forward(x - cX)
  elseif x < cX then
    turnTo(right)   -- -x
    forward(cX - x)
  end
  if z > cZ then
    turnTo(forward)     -- +z
    forward(z - cZ)
  elseif z < cZ then
    turnTo(back)     -- -z
    forward(cZ - z)
  end
    if h ~= nil then
        turnTo(h)
    end
end

movement.turnRight = turnRight
movement.turnLeft = turnLeft
movement.turnTo = turnTo
movement.forward = forward
movement.back = back
movement.up = up
movement.down = down
movement.getState = getState
movement.setState = setState
movement.setStart = setStart
movement.goTo = goTo

return movement

