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
  -- Show equipped tools
  
end
shell.run("tree_farm")

