local outName = "debug.txt"

local names = peripheral.getNames and peripheral.getNames() or { "left", "right", "front", "back", "top", "bottom" }
local report = { scanned = names, peripherals = {}, reader = nil }

-- helper to call a method safely and capture result or error string
local function safeCall(fn, ...)
  local ok, res = pcall(fn, ...)
  if ok then return { ok = true, result = res } end
  return { ok = false, error = tostring(res) }
end

for _, id in ipairs(names) do
  local entry = { id = id, type = peripheral.getType(id), methods = peripheral.getMethods(id) or {}, wrapped = false, methodCalls = {} }
  local ok, w = pcall(peripheral.wrap, id)
  if ok and w then
    entry.wrapped = true
    local wrapped = w

    -- call every exposed method with no arguments (capture success/failure and returned value or error)
    for _, m in ipairs(entry.methods) do
      local fn = wrapped[m]
      if type(fn) == "function" then
        entry.methodCalls[m] = safeCall(fn)
      else
        entry.methodCalls[m] = { ok = false, error = "not a function" }
      end
    end

    -- inventory helpers: size, list, getItemDetail
    if wrapped.size and type(wrapped.size) == "function" then
      local s = wrapped.size()
      entry.inventory = { size = s }
      if wrapped.list and type(wrapped.list) == "function" then
        -- pcall to avoid any unexpected runtime errors
        local ok2, listres = pcall(wrapped.list)
        entry.inventory.list = ok2 and listres or { __error = tostring(listres) }
      end
      if wrapped.getItemDetail and type(wrapped.getItemDetail) == "function" and s and type(s) == "number" then
        entry.inventory.slots = {}
        for i = 1, s do
          local ok3, det = pcall(wrapped.getItemDetail, i)
          entry.inventory.slots[i] = ok3 and det or { __error = tostring(det) }
        end
      end
    end

    -- tanks if present
    if wrapped.tanks and type(wrapped.tanks) == "function" then
      entry.tanks = safeCall(wrapped.tanks)
    end

    -- probe push/pull methods by attempting a no-arg call so we can capture signature-style errors without performing transfers
    for _, probe in ipairs({ "pushItems", "pullItems", "pushFluid", "pullFluid" }) do
      if wrapped[probe] and type(wrapped[probe]) == "function" then
        entry.methodCalls[probe .. "_probe_no_args"] = safeCall(wrapped[probe])
      end
    end
  else
    entry.wrapError = tostring(w)
  end
  report.peripherals[#report.peripherals + 1] = entry
end

-- find block reader by type or by methods
local reader_id
for _, p in ipairs(report.peripherals) do
  if p.type == "block_reader" or p.type == "blockReader" then
    reader_id = p.id
    break
  end
  for _, m in ipairs(p.methods or {}) do
    if m == "getBlockName" then
      reader_id = p.id
      break
    end
  end
  if reader_id then break end
end

if reader_id then
  local r = { id = reader_id, type = peripheral.getType(reader_id), methods = peripheral.getMethods(reader_id) or {} }
  local ok, wrapped = pcall(peripheral.wrap, reader_id)
  if ok and wrapped then
    r.wrapped = true
    r.calls = {}
    -- documented reader calls
    for _, m in ipairs({ "getBlockName", "isTileEntity", "getBlockData", "getBlockStates", "getConfiguration", "getName" }) do
      if wrapped[m] and type(wrapped[m]) == "function" then
        r.calls[m] = safeCall(wrapped[m])
      else
        r.calls[m] = { ok = false, error = "not available" }
      end
    end
  else
    r.wrapped = false
    r.wrapError = tostring(wrapped)
  end
  report.reader = r

  -- try to correlate reader side with a peripheral id (same side)
  for _, p in ipairs(report.peripherals) do
    if p.id == reader_id then
      report.reader.correspondingPeripheral = p
      break
    end
  end
end

-- Robust serializer that handles repeated tables / cycles by emitting <REF:n>
local function isArray(t, keys)
  if #keys == 0 then return false end
  for i = 1, #keys do
    if keys[i] ~= i then return false end
  end
  return true
end

local function serialize(val)
  local seen = {}
  local counter = 0

  local function ser(v, indent)
    indent = indent or ""
    local t = type(v)
    if t == "nil" then return "nil" end
    if t == "number" or t == "boolean" then return tostring(v) end
    if t == "string" then return string.format("%q", v) end
    if t == "function" then return string.format("%q", "<function:" .. tostring(v) .. ">") end
    if t == "thread" or t == "userdata" then return string.format("%q", "<" .. t .. ":" .. tostring(v) .. ">") end
    if t ~= "table" then return string.format("%q", "<" .. t .. ":" .. tostring(v) .. ">") end

    if seen[v] then
      return string.format("%q", ("<REF:%d>"):format(seen[v]))
    end
    counter = counter + 1
    seen[v] = counter

    -- collect keys deterministically
    local keys = {}
    for k in pairs(v) do keys[#keys+1] = k end
    table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)

    local out = {}
    if isArray(v, keys) then
      -- array style
      if #keys == 0 then return "{}" end
      out[#out+1] = "{"
      for i, k in ipairs(keys) do
        local vv = v[k]
        out[#out+1] = indent .. "  " .. ser(vv, indent .. "  ") .. (i < #keys and "," or "")
      end
      out[#out+1] = indent .. "}"
      return table.concat(out, "\n")
    else
      out[#out+1] = "{"
      for i, k in ipairs(keys) do
        local kk = k
        local vvv = v[k]
        local keyRep
        if type(kk) == "string" and kk:match("^[_%a][_%w]*$") then
          keyRep = kk
        else
          keyRep = "[" .. ser(kk, indent .. "  ") .. "]"
        end
        out[#out+1] = indent .. "  " .. keyRep .. " = " .. ser(vvv, indent .. "  ") .. (i < #keys and "," or "")
      end
      out[#out+1] = indent .. "}"
      return table.concat(out, "\n")
    end
  end

  return ser(val, "")
end

-- write out report
local fh = fs.open(outName, "w")
fh.write(serialize(report))
fh.close()

print("Wrote " .. outName)
