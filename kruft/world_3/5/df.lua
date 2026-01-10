local path = "/"  -- Root drive; change to "disk/" for a floppy, etc.

local totalSpace = fs.getCapacity(path)
local freeSpace = fs.getFreeSpace(path)
local usedSpace = totalSpace - freeSpace

print("Total space: " .. totalSpace .. " bytes")
print("Free space: " .. freeSpace .. " bytes")
print("Used space: " .. usedSpace .. " bytes")

-- Optional: Readable format (KB/MB)
local totalKB = math.floor(totalSpace / 1024)
local freeKB = math.floor(freeSpace / 1024)
local usedKB = math.floor(usedSpace / 1024)
print("Total: " .. totalKB .. " KB, Free: " .. freeKB .. " KB, Used: " .. usedKB .. " KB")
