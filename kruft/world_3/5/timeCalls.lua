-- Time list() vs getItemDetail() on a chest

local chestName = "ironchest:diamond_chest_46"
local chest = peripheral.wrap(chestName)
local chestSize = chest.size()

local total = 0
-- Test list()
-- local startTime = os.epoch("utc")
-- for slot = 1, chest.size() do
--   local items = chest.list()
--   if items[slot] ~= nil then
--       total = total + 1
--   end
-- end
-- local listTime = os.epoch("utc") - startTime
-- if total == 0 then
--     print("Chest is empty!")
-- end
-- total = 0

-- -- Test getItemDetail()
-- startTime = os.epoch("utc")
-- for slot = 1, chest.size() do
--   local detail = chest.getItemDetail(slot)
--   if detail ~= nil then
--     -- slot has item
--   end
-- end
-- local detailTime = os.epoch("utc") - startTime
-- if total == 0 then
--     print("Chest is empty!")
-- end
-- total = 0

-- startTime = os.epoch("utc")
-- for slot = 1, chest.size() do
--     local detail = chest.getItemDetail(slot)
--   local items = chest.list()
--   if items[slot] ~= nil and detail ~= nil then
--     total = total + 1
--   end
-- end
-- local bothTime = os.epoch("utc") - startTime
-- if total == 0 then
--     print("Chest is empty!")
-- end

-- Test pushItems by moving the stack in the last slot to the current slot and back.
largeLimit = 2147483647 -- Max 32 bit integer.
startTime = os.epoch("utc")
for slot = 1, chest.size() do
    chest.pushItems(chestName, chestSize, largeLimit, slot)
    chest.pushItems(chestName, slot, largeLimit, chestSize)
end
local pushTime = os.epoch("utc") - startTime
print("pushItems() time: " .. pushTime .. " ms")


-- print("list() time: " .. listTime .. " ms")
-- print("getItemDetail() time: " .. detailTime .. " ms")
-- print("Ratio: " .. string.format("%.2f", listTime / detailTime))
-- print("Both time: " .. bothTime .. " ms")
