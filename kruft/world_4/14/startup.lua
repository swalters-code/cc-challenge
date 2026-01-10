-- Make sure we're only using our own motd.txt
if not fs.exists("/motd.txt") then
  local f = fs.open("/motd.txt", "w")
  if f then
    f.write("Booting...")
    f.close()
  end
end
settings.set("motd.path", "/motd.txt")
settings.save()
-- Print the label and ID number
print(os.getComputerLabel() .. " (" .. os.getComputerID() .. ")")
if turtle then
  print("Fuel: " .. turtle.getFuelLevel())
  -- Show equipped tools, if possible.
  if turtle.getEquippedRight then
    local left = turtle.getEquippedLeft()
    if left then
      print("Left: " .. left.name)
    end
    local right = turtle.getEquippedRight()
    if right then
      print("Right: " .. left.name)
    end
  end
end
shell.run("furnace")
