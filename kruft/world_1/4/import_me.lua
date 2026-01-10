-- Compact importer that waits for a portable inventory to be placed on top of the computer,
-- then imports only item types that are already present in an Applied Energistics network
-- via an Advanced Peripherals ME Bridge. It prints each imported stack (item name and count).
-- The program loops forever: when the inventory is removed it notes that and goes back to waiting
-- for the next inventory to be placed.
-- Run on the computer: lua import_me.lua

local INVENTORY_SIDE = "top"
local SLEEP_POLL = 0.6
local sides = {"front","back","left","right","top","bottom"}

local function findMeBridge()
  for _, n in ipairs(peripheral.getNames()) do
    if (peripheral.getType(n) or ""):lower():find("me_bridge") then return n end
  end
  return nil
end

local function getMeItemNames(meName)
  if not meName then return nil end
  local methods = peripheral.getMethods(meName) or {}
  local candidates = {}

  for _, m in ipairs(methods) do
    local ml = m:lower()
    if ml:find("item") or ml:find("store") or ml:find("list") or ml:find("available") then
      table.insert(candidates, m)
    end
  end

  -- common fallbacks
  for _, m in ipairs({"getAvailableItems","listItems","getItems","getStoredItems","list"}) do
    local found = false
    for _, c in ipairs(candidates) do if c == m then found = true; break end end
    if not found then table.insert(candidates, m) end
  end

  for _, method in ipairs(candidates) do
    local ok, res = pcall(peripheral.call, meName, method)
    if ok and type(res) == "table" and next(res) then
      local names = {}
      for k, v in pairs(res) do
        if type(v) == "table" then
          if v.name then names[v.name] = true
          elseif v.item then names[v.item] = true end
        elseif type(k) == "string" then
          names[k] = true
        elseif type(v) == "string" then
          names[v] = true
        end
      end
      if next(names) then return names, method end
    end
  end

  return nil
end

local function isInventoryPresent(side)
  if not peripheral.isPresent(side) then return false end
  local methods = peripheral.getMethods(side) or {}
  for _, m in ipairs(methods) do
    local ml = m:lower()
    if ml == "list" or ml:find("list") or ml == "getall" then return true end
  end
  return false
end

local function waitForInventory()
  print("Waiting for an inventory to be placed on top...")
  while true do
    if isInventoryPresent(INVENTORY_SIDE) then
      -- try to wrap it; wrapping may fail transiently if placed quickly
      local ok, p = pcall(peripheral.wrap, INVENTORY_SIDE)
      if ok and p then
        print("Inventory detected on top.")
        return p
      end
    end
    os.sleep(SLEEP_POLL)
  end
end

-- Attempt to import one stack of the given itemName from the inventory side into the ME bridge.
-- Returns true if import succeeded (bridge reported success / moved something).
local function tryImportStack(meName, itemName)
  for _, side in ipairs(sides) do
    local ok, res = pcall(peripheral.call, meName, "importItem", { name = itemName }, side)
    if ok and res then return true end
  end
  return false
end

-- Main loop: wait for inventory, import eligible items, detect removal, repeat.
print("import_me.lua starting. Place your portable inventory on top of the computer.")
while true do
  -- Wait for inventory to be placed
  local chest = waitForInventory()

  -- Find ME bridge and the items currently stored
  local meName = findMeBridge()
  if not meName then
    print("Warning: No me_bridge peripheral found. Waiting for an ME Bridge to be attached.")
  end

  local meItems = getMeItemNames(meName)
  if not meItems then
    print("Warning: Couldn't determine items in the ME system (bridge method autodetect failed).")
    print("If the bridge is present, run: print(textutils.serialise(peripheral.getMethods('<meName>'))) and adapt the script.")
    -- We still continue: user may want to place an inventory later once bridge is fixed.
  else
    print("Discovered items in ME system.")
  end

  local importedStacks = 0

  -- Loop while inventory remains placed; detect removal by checking peripheral.isPresent
  while peripheral.isPresent(INVENTORY_SIDE) do
    -- refresh wrap each iteration in case the peripheral object changed
    local okWrap, curChest = pcall(peripheral.wrap, INVENTORY_SIDE)
    if not okWrap or not curChest then
      -- Treat as removed
      break
    end

    local items = curChest.list() or {}
    local movedThisPass = false

    -- Scan slots and import the first eligible stack we can move, then restart scanning.
    for slot, stack in pairs(items) do
      if not peripheral.isPresent(INVENTORY_SIDE) then break end
      local itemName = stack.name or stack.id
      local count = stack.count or 1
      if itemName and meItems and meItems[itemName] then
        local moved = tryImportStack(meName, itemName)
        if moved then
          importedStacks = importedStacks + 1
          print(string.format("Imported: %s x%d (slot %d)", itemName, count, slot))
          movedThisPass = true
          break -- inventory changed; restart scanning from fresh list
        end
      end
    end

    if not movedThisPass then
      -- Nothing moved this pass. Sleep a bit, but continue monitoring for removal or new items.
      os.sleep(0.5)
    end
  end

  -- Inventory was removed (or peripheral.wrap failed). Report and loop back to wait for next.
  print("Inventory removed from top. Finished session: Imported stacks: " .. importedStacks)
  print("Waiting for next inventory...")
  -- small sleep to avoid busy-looping if peripheral rapidly toggles
  os.sleep(0.6)
end

