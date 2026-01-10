local function listFiles(path)
    local items = fs.list(path)
    local totalSize = 0
    for _, item in ipairs(items) do
        local fullPath = fs.combine(path, item)
        if fs.isDir(fullPath) then
            totalSize = totalSize + listFiles(fullPath)
        else
            local size = fs.getSize(fullPath)
            print(fullPath .. ": " .. size .. " bytes")
            totalSize = totalSize + size
        end
    end
    return totalSize
end
local totalUsed = listFiles("/")
print("Total used in FS: " .. totalUsed .. " bytes")
