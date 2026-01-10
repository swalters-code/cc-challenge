 -- computer:6:2025-11-27-17-35-17> p = peripheral.wrap("back")
 -- computer:6:2025-11-27-17-35-19> p
OUTPUT:
{
  getEnergy = nil --[[function]],
  getEnergyCapacity = nil --[[function]],
  getItemDetail = nil --[[function]],
  getItemLimit = nil --[[function]],
  list = nil --[[function]],
  pullFluid = nil --[[function]],
  pullItems = nil --[[function]],
  pushFluid = nil --[[function]],
  pushItems = nil --[[function]],
  size = nil --[[function]],
  tanks = nil --[[function]],
}
 -- computer:6:2025-11-27-17-35-28> p.tanks()
OUTPUT:
{}
 -- computer:6:2025-11-27-17-35-35> p.tanks(1)
OUTPUT:
{}
 -- computer:6:2025-11-27-17-35-41> p.tanks("1")
OUTPUT:
{}
 -- computer:6:2025-11-27-17-36-21> p.tanks()
OUTPUT:
{ { amount = 10000, name = "mffs:fortron_fluid" } }
 -- computer:6:2025-11-27-17-37-25> p.tanks()
OUTPUT:
{ { amount = 10000, name = "mffs:fortron_fluid" } }
 -- computer:6:2025-11-27-17-38-26> p.getFluidInTank(1)
ERROR: lua[8]:1: attempt to call field 'getFluidInTank' (a nil value)
TRACEBACK:
 -- computer:6:2025-11-27-17-39-44> p = peripheral.wrap("back")
 -- computer:6:2025-11-27-17-39-51> p.getFluidInTank(1)
ERROR: lua[2]:1: attempt to call field 'getFluidInTank' (a nil value)
TRACEBACK:
