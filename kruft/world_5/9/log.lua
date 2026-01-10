turtle.dig()
turtle.forward()
while turtle.compareUp() do
  turtle.digUp()
  turtle.up()
end
while not turtle.detectDown() do
  turtle.down()
end

