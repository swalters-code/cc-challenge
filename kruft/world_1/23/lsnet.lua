-- list all peripherals and print first item in each inventory
-- no item means empty or not an inventory
for _, name in ipairs(peripheral.getNames()) do

    local type = peripheral.getType(name)
    print(name .. " (" .. tostring(type) .. ")")
    for k, v in pairs({peripheral.getType(name)}) do
        print("  inventory: " .. tostring(k) .. " = " .. tostring(v))
    end
    -- local p = peripheral.wrap(name)
    -- write(name .. ": ")
    -- if p.list == nil then
    --     print("  (not an inventory)")
    -- else
    --     for k, v in ipairs(p.list()) do
    --         print(v.name)
    --         break
    --     end
    -- end
end
