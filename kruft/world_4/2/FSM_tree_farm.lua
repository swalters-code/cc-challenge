-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg settings sleep
-- A finite state machine for a tree farm turtle.
-- Written for CC:Tweaked

-- Logs in slot 1, saplings slot 2, fuel slot 16.

-- If you're using oak trees, place a slab, fence
-- or glass 6 to 8 blocks above the sapling to
-- prevent large oak growth.

-- Each state is resumable.  That is, if the
-- computer gets stopped, we can start the program,
-- load the state and continue from where we left
-- off.  To accomplish this, you must change state
-- after every turtle move or breaking an item
-- you'll later test for.

-- List of States
-- idle: Waiting for a tree to grow and performing maintenance tasks.
-- travel_up_before_leaves: Moving up one level of the tree.
-- travel_up_break_leaves: Breaking leaves in all four directions at the current level.
-- travel_down_before_leaves: Moving down one level of the tree.
-- travel_down_break_leaves: Breaking leaves in all four directions at the current level.
-- return_suck_ground: Sucking items in the left, back, and right directions.
-- return_move_back: Moving back to the starting position.
-- return_suck_home: Sucking items in all four directions at the starting position.



local state = {
  node = "idle",
  prevNode = "",
  direction = 0, -- 0=forward,1=left,2=back,3=right
}

function state:save()
  -- Create a temporary table with only serializable fields
  local tempState = {
    node = self.node,
    prevNode = self.prevNode,
    direction = self.direction,
  }
  -- Save the temporary table under the name "state"
  settings.set("state", tempState)
  settings.save()
end

function state:load()
  settings.load()
  local savedState = settings.get("state")
  if savedState then
    self.node = savedState.node
    self.prevNode = savedState.prevNode
    self.direction = savedState.direction
  else
    self.node = "idle"
    self.prevNode = nil
    self.direction = 0
  end
end

-- luacheck: ignore unused self
function state:clear()
  -- Remove the "state" key from the settings file
  settings.unset("state")
  -- Save the changes to persist the removal
  settings.save()
end


function state:transition(nextState)
  self.node = nextState
  self:save()
end

function state:left(nextState)
  local timeBefore = os.clock("utc")
  turtle.turnLeft()
  self.direction = (self.direction + 1) % 4
  self.node = nextState
  self:save()
  local timeAfter = os.clock("utc")
  local ticks = (timeAfter - timeBefore) * 20
  print("Turn left took " .. tostring(ticks) .. " ticks")
end

function state:right(nextState)
  turtle.turnRight()
  local timeBefore = os.clock("utc")
  self.direction = (self.direction - 1) % 4
  self.node = nextState
  self:save()
  local timeAfter = os.clock("utc")
  local ticks = (timeAfter - timeBefore) * 20
  print("Turn right took " .. tostring(ticks) .. " ticks")
end

function state:forward(nextState)
  turtle.forward()
  self.node = nextState
  self:save()
end

function state:back(nextState)
  turtle.back()
  self.node = nextState
  self:save()
end

function state:up(nextState)
  turtle.up()
  self.node = nextState
  self:save()
end

function state:down(nextState)
  turtle.down()
  self.node = nextState
  self:save()
end

function state:init()
  settings.load()
  if settings.get("state") then
    self:load()
  else
    self.node = "idle"
    self.direction = 0
    self:save()
  end
end

function state:run()
  while true do
    -- Store the previous state (for logging)
    local stashNode = self.node
    self:dispatch(self, self.node)
    self.prevNode = stashNode
  end
end

-- FIXME: Move these variables.
local treeSlot = 2
local logSlot = 1
local fuelSlot = 16
local idleTime = 15
local saplingTypes =
  {["minecraft:sapling"] = true,
    ["minecraft:oak_sapling"] = true,
    ["minecraft:spruce_sapling"] = true,
    ["minecraft:birch_sapling"] = true,
    ["minecraft:jungle_sapling"] = true,
    ["minecraft:acacia_sapling"] = true,
    ["minecraft:dark_oak_sapling"] = true,
  }
  

local function plantTree()
  local selection = turtle.getSelectedSlot()
  turtle.select(2)
  if turtle.getItemCount(2) == 0 then
    print("Out of saplings!")
    turtle.select(selection)
    return false
  end
  if turtle.place() then
    turtle.select(selection)
    return true
  else
    turtle.select(selection)
    return false
  end
end


-- TODO: Add states for sucking items and managing the furnace.

local function dispatch(self, state, node)
    if self.prevNode and self.prevNode ~= node then
        -- TODO: Add node descriptions.
        print(tostring(self.prevNode) .. " -> " .. tostring(node))
    end
    -- sleep(1)
  if node == "idle" then
    -- Description: The turtle waits for a tree to grow and performs maintenance tasks.
    -- Implementation:
    -- If no tree is planted, plant one.
    plantTree()
    -- Use sticks and excess saplings as fuel.
    local usedFuel = false
        for slot = 1, 16 do
            turtle.select(slot)
            local itemDetail = turtle.getItemDetail()
            if itemDetail
                and slot ~= fuelSlot
                and slot ~= logSlot
                and slot ~= treeSlot
            then
                if itemDetail.name == "minecraft:stick"
                    or saplingTypes[itemDetail.name]
                then
                    usedFuel = true
                    turtle.refuel(itemDetail.count)
                end
            end
        end
        while turtle.getFuelLevel() < 320 do
            turtle.select(fuelSlot)
            turtle.refuel(1)
            usedFuel = true
        end
    if turtle.getItemCount(fuelSlot) < 16 then
      print("Fuel low in slot " .. tostring(fuelSlot))
    end
    if usedFuel then
      print("Fuel level: " .. tostring(turtle.getFuelLevel()))
    end

    -- Detect if a tree has grown.
    turtle.select(logSlot)
    if turtle.compare() then
      -- A tree has grown, transition to travel_up_before_leaves.
      state.node = "travel_up"
      state:save()
      return
    else
      -- No tree has grown, remain in idle.
      sleep(idleTime)
      -- TODO: Go to refuel states. (manage furnace and inventory)
    end

  elseif node == "travel_up" then
    -- travel_up
    -- Description: The first step in traveling up the tree.
    turtle.digUp() -- Break the leaves above.
    state:up("travel_up_before_leaves")

  elseif node == "travel_up_before_leaves" then
    -- travel_up_before_leaves state implementation
    self:left("travel_up_break_leaves")

  elseif node == "travel_up_break_leaves" then
    if self.direction == 0 then
      turtle.select(1)
      if turtle.compare() then
        -- There's still a log in front, continue up.
        turtle.digUp() -- Break the leaves above.
        self:up("travel_up_before_leaves")
      else
        -- No log detected, transition to travel_down_before_leaves.
        turtle.digUp() -- Break the leaves above.
        turtle.dig()   -- Break the leaves in the current direction.
        self:forward("travel_down_before_leaves")
      end
    else
      turtle.dig() -- Break the leaves in the current direction.
      self:left("travel_up_break_leaves")
    end

  elseif node == "travel_down_before_leaves" then
    -- travel_down_before_leaves
    -- Description: The turtle moves down one level of the tree.
    -- Implementation:
    -- 1. Move down one level.
    -- 2. Transition to travel_down_break_leaves.
    turtle.dig()
    state:left("travel_down_break_leaves")

  elseif node == "travel_down_break_leaves" then
    if self.direction == 0 then
      turtle.select(1)
      if turtle.compareDown() then
        -- There's still a log below, continue down.
        turtle.digDown() -- Break the log below.
        self:down("travel_down_before_leaves")
      else
        -- No log detected below, transition to return_suck_ground.
        turtle.suck()
        self:left("return_suck_ground")
      end
    else
      turtle.dig() -- Break the leaves in the current direction.
      self:left("travel_down_break_leaves")
    end

  elseif node == "return_suck_ground" then
    turtle.suck()
      if self.direction == 3 then
        -- We are facing right.
        self:right("return_move_back")
      else
        self:left("return_suck_ground")
      end

  elseif node == "return_move_back" then
    self:forward("return_suck_home")
  elseif node == "return_suck_home" then
    -- TODO: We can manage the furnace facing dir 2.
    turtle.suck()
    if self.direction == 3 then
      -- We are facing right.
      self:left("idle")
    else
      self:right("return_suck_home")
    end

  elseif node == "refuel" then
    -- TODO: Implement refuel state here. (manage furnace and inventory)
  else
    error("Unknown state: " .. tostring(node))
  end
end



-- travel_down_break_leaves
-- Description: The turtle breaks leaves in all four directions at the current level.
-- Implementation:
-- 1. Use the direction variable to track which direction the turtle is facing.
-- 2. Break leaves in the current direction.
-- 3. Turn left and repeat until all four directions are covered.
-- 4. Transition back to travel_down_before_leaves to move down again.
-- 5. Transition to return_suck_ground when no log is detected below.

-- return_suck_ground
-- Description: The turtle sucks items in the left, back, and right directions.
-- Implementation:
-- 1. If direction == left: Suck, turn left -> return_suck_ground.
-- 2. If direction == back: Suck, turn left -> return_suck_ground.
-- 3. If direction == right: Suck, turn right -> return_move_back.

-- return_move_back
-- Description: The turtle moves back to the starting position.
-- Implementation:
-- 1. If forward: Move forward -> return_suck_home.

-- return_suck_home
-- Description: The turtle sucks items in all four directions at the starting position.
-- Implementation:
-- 1. If direction == back: Suck, turn left -> return_suck_home.
-- 2. If direction == left: Suck, turn left -> return_suck_home.
-- 3. If direction == forward: Suck, turn left -> return_suck_home.
-- 4. If direction == right: Suck, turn left -> idle.



-- TODO: Add code to save state while moving.
-- TODO: Add code to place a slab, fence or glass above oak saplings.
-- TODO: Add code to detect what features to use.
-- TODO: Allow sapling consilidation.
-- TODO: Use sticks for fuel.
-- TODO: Add use of a furnace below the turtle for charcoal production.
-- TODO: Allow overflow saplings to be used for fuel.

state:init()
state.dispatch = dispatch
print(state.node)
state:run()
