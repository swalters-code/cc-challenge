local chest = peripheral.wrap("left")
local name = "left"

print(chest.pushItems(name, 3, 64, 1)) -- prints 0
print(chest.pullItems(name, 3, 64, 1)) -- prints >0 and moves the stack
