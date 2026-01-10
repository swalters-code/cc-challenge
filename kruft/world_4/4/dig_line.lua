-- -*- mode: lua-ts; lua-ts-indent-offset: 2; fill-column: 51; -*-
-- luacheck: globals turtle arg
-- Dig a 1x3 line forward.
-- Written for CC:Tweaked

local t = turtle

if #arg < 1 then
  print("Usage: dig_line <length>")
  print("Digs a 1x3 line forward of given length.")
  print("Place turtle at the height you want the middle row to be dug.")
  return
end

local length = tonumber(arg[1]) or 1
if length < 1 then
  print("Length must be at least 1.")
  return
end

for i = 0, length do
  if i < length then
    t.dig()
    t.forward()
  end
  t.digUp()
  t.digDown()
end

