-- File Output Redirector
-- Usage: tofile <filename> <program> [args...]

local args = { ... }

if #args < 2 then
    print("Usage: tofile <filename> <program> [args...]")
    return
end

local filename = table.remove(args, 1)
local program = table.remove(args, 1)

-- Open file for writing
local file = fs.open(filename, "w")
if not file then
    print("Error: Could not open file '" .. filename ..  "' for writing.")
    return
end

-- Create a fake terminal that writes to the file
local fakeTerm = {}
local cursorX, cursorY = 1, 1
local width, height = term.getSize()
local lines = {}

-- Initialize empty lines
for i = 1, height do
    lines[i] = string.rep(" ", width)
end

-- Helper to update a line with text at position
local function updateLine(y, x, text)
    if y < 1 or y > height then return end
    local line = lines[y] or string.rep(" ", width)
    local before = line:sub(1, x - 1)
    local after = line:sub(x + #text)
    lines[y] = (before .. text .. after):sub(1, width)
end

function fakeTerm. write(text)
    text = tostring(text)
    updateLine(cursorY, cursorX, text)
    cursorX = cursorX + #text
end

function fakeTerm.blit(text, fg, bg)
    fakeTerm.write(text)
end

function fakeTerm.clear()
    for i = 1, height do
        lines[i] = string.rep(" ", width)
    end
end

function fakeTerm.clearLine()
    lines[cursorY] = string.rep(" ", width)
end

function fakeTerm.getCursorPos()
    return cursorX, cursorY
end

function fakeTerm.setCursorPos(x, y)
    cursorX, cursorY = math.floor(x), math.floor(y)
end

function fakeTerm.setCursorBlink(blink)
    -- No-op
end

function fakeTerm.isColor()
    return false
end

function fakeTerm.isColour()
    return false
end

function fakeTerm.getSize()
    return width, height
end

function fakeTerm. scroll(n)
    if n > 0 then
        for i = 1, height - n do
            lines[i] = lines[i + n]
        end
        for i = height - n + 1, height do
            lines[i] = string.rep(" ", width)
        end
    elseif n < 0 then
        for i = height, 1 - n, -1 do
            lines[i] = lines[i + n]
        end
        for i = 1, -n do
            lines[i] = string.rep(" ", width)
        end
    end
end

function fakeTerm.setTextColor(color) end
function fakeTerm.setTextColour(colour) end
function fakeTerm.setBackgroundColor(color) end
function fakeTerm.setBackgroundColour(colour) end
function fakeTerm. getTextColor() return colors.white end
function fakeTerm.getTextColour() return colours.white end
function fakeTerm.getBackgroundColor() return colors.black end
function fakeTerm. getBackgroundColour() return colours.black end
function fakeTerm. setPaletteColor(... ) end
function fakeTerm.setPaletteColour(...) end
function fakeTerm.getPaletteColor(color) return term.native(). getPaletteColor(color) end
function fakeTerm.getPaletteColour(colour) return term.native().getPaletteColour(colour) end

-- Redirect terminal to our fake one
local oldTerm = term. redirect(fakeTerm)

-- Run the program
local ok, err = pcall(function()
    shell.run(program, table.unpack(args))
end)

-- Restore terminal
term.redirect(oldTerm)

-- Write lines to file (trim trailing empty lines)
local lastLine = height
for i = height, 1, -1 do
    if lines[i]:match("%S") then
        lastLine = i
        break
    end
end

for i = 1, lastLine do
    file. writeLine(lines[i]:gsub("%s+$", ""))
end

file.close()

if not ok then
    print("Error running program: " .. tostring(err))
else
    print("Output written to " .. filename)
end
