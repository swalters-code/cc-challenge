local side = ...
assert(side, "Usage: peripheral_info <side>")

local p = assert(peripheral.wrap(side), "no peripheral on " .. side)
local typename = peripheral.getType(side) or side
local methods = peripheral.getMethods(side)
local keys = {}
for k in pairs(p) do keys[#keys+1] = k end

local info = {
  type = typename,
  side = side,
  methods = methods,
  keys = keys,
}

-- inventory: size/list/slots
if p.size and p.list then
  local n = p.size()
  local listing = p.list()
  local slots = {}
  for k, v in pairs(listing) do
    local slotnum = tonumber(k) or k
    slots[#slots+1] = { slot = slotnum, contents = v }
  end
  if p.getItemDetail then
    for i = 1, n do
      local det = p.getItemDetail(i)
      if det then
        local found = false
        for _, s in ipairs(slots) do
          if s.slot == i then
            s.contents = det
            found = true
            break
          end
        end
        if not found then slots[#slots+1] = { slot = i, contents = det } end
      end
    end
  end
  info.inventory = { size = n, slots = slots }
end

-- tanks: prefer getTanks, fall back to getTankInfo
if p.getTanks or p.getTankInfo then
  local tanks = p.getTanks and p.getTanks() or p.getTankInfo()
  info.tanks = tanks
end

-- standard energy-ish methods
local energyMethods = {
  "getEnergyStored",
  "getMaxEnergyStored",
  "getEnergy",
  "getMaxEnergy",
  "getEUStored",
  "getMaxEUStored",
  "getEU",
  "getStoredEnergy",
  "getMaxStoredEnergy",
}
local energy = {}
for _, m in ipairs(energyMethods) do
  if p[m] then energy[m] = p[m]() end
end
if next(energy) then info.energy = energy end

local filename = typename .. ".txt"
local fh = fs.open(filename, "w")
fh.write(textutils.serialize(info))
fh.close()

print("Wrote " .. filename)
