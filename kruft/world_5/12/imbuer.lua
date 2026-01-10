-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg fs textutils sleep
-- luacheck: globals peripheral parallel shell
-- Written for CC:Tweaked

-- Automate adjacent Ars Nouveau Imbuement chambers

local chestName = "top"
local sleepTime = 10

local rawMaterials = {
  ["minecraft:lapis_lazuli"] = true,
  ["minecraft:amethyst_shard"] = true,
  ["minecraft:amethyst_block"] = true,
}

local products = {
  ["ars_nouveau:source_gem"] = true,
  ["ars_nouveau:source_gem_block"] = true,
}

local chest = peripheral.wrap(chestName)
assert(chest,
       "Could not find chest on side: " .. chestName)
print("Using chest on " .. chestName)
local chestSize = chest.size()
-- Find all adjacent imbuement chambers
---@type ccTweaked.peripheral.wrappedPeripheral[]
local imbuers = {}

for _, pName in pairs(peripheral.getNames()) do
  if pName:find("ars_nouveau:imbuement_chamber") then
    local imbuer = peripheral.wrap(pName)
    if imbuer then
      table.insert(imbuers, imbuer)
      print("Found imbuement chamber: " .. pName)
    end
  end
end

for _, side in pairs({
  "top",
  "bottom",
  "front",
  "back",
  "left",
  "right",
}) do
  local s = peripheral.wrap(side)
  if s ~= nil then
    local pName = peripheral.getType(s)
    print(pName)
    if pName and pName:find("ars_nouveau:imbuement_chamber") then
      table.insert(imbuers, s)
      print("Found imbuement chamber: " .. pName)
    end
  end
end

if #imbuers == 0 then
  error("No imbuement chambers found")
end

while true do
  for _, imbuer in pairs(imbuers) do
    local item = imbuer.getItemDetail(1)
    if item ~= nil then
      if products[item.name] then
        imbuer.pushItems(chestName, 1)
        item = nil
      end
    end
      -- Imbuer is empty, try to fill it
    if item == nil then
      for slot, material in pairs(chest.list()) do
        if rawMaterials[material.name] then
            local moved =
              imbuer.pullItems(chestName, slot)
            if moved > 0 then
              break
            end
        end
      end
    end
  end
  sleep(sleepTime)
end
