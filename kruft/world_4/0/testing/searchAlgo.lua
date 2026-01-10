-- for _, v in ipairs({ 1, 1, 2, 2, 2, 2 }) do
--   for s = 1, math.min(v, 2) do
--     turtle.forward()
--     turtle.placeDown()
--   end
--   if v < 3 then turtle.turnLeft() end
-- end

t = turtle

for _ = 0, 3 do
  t.forward()
  t.placeDown()
  local success, data = t.inspect()
  if success then
    if furnaceTypes[data.name] then
      t.turnRight()
      t.turnRight()
      return "idle"
    end
  end
  t.back()
  t.turnLeft()
end
