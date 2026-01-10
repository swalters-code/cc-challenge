local reader_side
for _, id in ipairs(peripheral.getNames()) do
  local t = peripheral.getType(id)
  if t == "block_reader" or t == "blockReader" then
    reader_side = id
    break
  end
  local methods = peripheral.getMethods(id) or {}
  for _, m in ipairs(methods) do
    if m == "getBlockName" then
      reader_side = id
      break
    end
  end
  if reader_side then break end
end

assert(reader_side, "no block_reader found")
local p = peripheral.wrap(reader_side)
local methods = peripheral.getMethods(reader_side) or {}

local results = {}
for _, m in ipairs(methods) do
  results[m] = p[m]()
end

local blockName = results.getBlockName or "block"
local filename = (blockName:gsub(":", "_"):gsub("%s+", "_")) .. ".txt"

local info = {
  reader = { side = reader_side, type = peripheral.getType(reader_side), methods = methods },
  results = results,
}

local fh = fs.open(filename, "w")
fh.write(textutils.serialize(info))
fh.close()

print("Wrote " .. filename)
