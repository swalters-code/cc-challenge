-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel shell
-- Written for CC:Tweaked

-- Pipe fluids from any number of tanks into another.

local outputTank = "bottom"
local inputTankNames = {
  "left",
  "right",
}

local sleepTime = 30

local output = peripheral.wrap(outputTank)
assert(output,
       "Could not find output tank on side: " .. outputTank)

local inputTanks = {}
for _, name in pairs(inputTankNames) do
  inputTanks[name] = peripheral.wrap(name)
  if not inputTanks[name]
    or inputTanks[name].tanks -- Make sure it's a tank
      == nil
  then
    error("Could not find input tank on side: " .. name)
  end
end


while true do
  for name, tank in pairs(inputTanks) do
    local tanks = tank.tanks()
    -- There is a well known bug in CC:Tweaked tank
    -- handling where a tank only shows up in tank()
    -- when there is fluid in it.
    if #tanks > 0 then
      output.pullFluid(name)
    end
  end
  sleep(sleepTime)
end

