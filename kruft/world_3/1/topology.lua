-- topology.lua
-- Run this on any computer/turtle with a wired modem on the network

local file = fs.open("topology.txt", "w")
file.writeLine("=== INVENTORY TOPOLOGY SCAN ===")
file.writeLine(os.date("%Y-%m-%d %H:%M:%S"))
file.writeLine("")

local count = 0

for _, name in ipairs(peripheral.getNames()) do
    if peripheral.hasType(name, "inventory") then
        count = count + 1
        local inv = peripheral.wrap(name)
        local ptype = peripheral.getType(name) -- e.g. "minecraft:chest", "sophisticatedstorage:barrel"

        file.writeLine(string.format("Peripheral: %s", name))
        file.writeLine(string.format("    Type: %s", ptype))

        local list = inv.list()
        local firstSlot = next(list) -- nil if empty
        if firstSlot then
            local detail = inv.getItemDetail(firstSlot)
            if detail then
                local displayName = detail.displayName or detail.name
                file.writeLine(string.format("    First item: %s  (id: %s)", displayName, detail.name))
            end
        end
        file.writeLine("") -- blank line between entries
    end
end

file.writeLine(string.format("Found %d inventory peripheral(s) on the network.", count))
file.close()

print(string.format("Topology scan complete → %d inventories written to topology.txt", count))
