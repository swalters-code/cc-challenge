local height = tonumber(arg[1])

for i = 1, height do
  turtle.digUp()
  turtle.dig()
  turtle.turnLeft()
  turtle.dig()
  turtle.turnLeft()
  turtle.dig()
  turtle.turnLeft()
  turtle.dig()
  turtle.up()
end

for i = 1, height do
   turtle.down()
end

