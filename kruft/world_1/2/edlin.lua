function editLine(initialText)
    local text = initialText or ""
    local cursorPos = #text + 1
    local cursorBlink = true
    local cursorTimer = os.startTimer(0.5)
    local ctrlHeld = false
    
    local function findWordBoundary(pos, direction)
        if direction < 0 then  -- Left
            pos = pos - 1
            while pos > 1 and text:sub(pos, pos):match("%s") do
                pos = pos - 1
            end
            while pos > 1 and not text:sub(pos - 1, pos - 1):match("%s") do
                pos = pos - 1
            end
            return pos
        else  -- Right
            while pos <= #text and text:sub(pos, pos):match("%s") do
                pos = pos + 1
            end
            while pos <= #text and not text:sub(pos, pos):match("%s") do
                pos = pos + 1
            end
            return pos
        end
    end
    
    local function redraw()
        local _, y = term.getCursorPos()
        term.setCursorPos(1, y)
        term.clearLine()
        term.write(text)
        term.setCursorPos(cursorPos, y)
        if cursorBlink then
            term.write("_")
            term.setCursorPos(cursorPos, y)
        end
    end
    
    while true do
        redraw()
        
        local event, param = os.pullEvent()
        
        if event == "timer" and param == cursorTimer then
            cursorBlink = not cursorBlink
            cursorTimer = os.startTimer(0.5)
            
        elseif event == "char" then
            text = text:sub(1, cursorPos - 1) .. param .. text:sub(cursorPos)
            cursorPos = cursorPos + 1
            cursorBlink = true
            os.cancelTimer(cursorTimer)
            cursorTimer = os.startTimer(0.5)
            
        elseif event == "key" then
            if param == keys.leftCtrl or param == keys.rightCtrl then
                ctrlHeld = true
                
            elseif param == keys.enter then
                print()
                return text
                
            elseif param == keys.backspace then
                if cursorPos > 1 then
                    text = text:sub(1, cursorPos - 2) .. text:sub(cursorPos)
                    cursorPos = cursorPos - 1
                end
                
            elseif param == keys.delete then
                if cursorPos <= #text then
                    text = text:sub(1, cursorPos - 1) .. text:sub(cursorPos + 1)
                end
                
            elseif param == keys.left then
                if ctrlHeld then
                    cursorPos = findWordBoundary(cursorPos, -1)
                else
                    cursorPos = math.max(1, cursorPos - 1)
                end
                
            elseif param == keys.right then
                if ctrlHeld then
                    cursorPos = findWordBoundary(cursorPos, 1)
                else
                    cursorPos = math.min(#text + 1, cursorPos + 1)
                end
                
            elseif param == keys.home then
                cursorPos = 1
                
            elseif param == keys["end"] then
                cursorPos = #text + 1
            end
            
            cursorBlink = true
            os.cancelTimer(cursorTimer)
            cursorTimer = os.startTimer(0.5)
        
        elseif event == "key_up" then
            if param == keys.leftCtrl or param == keys.rightCtrl then
                ctrlHeld = false
            end
        end
    end
end

-- Example usage
term.clear()
term.setCursorPos(1, 1)
print("Single Line Editor Demo")
print("Press Enter when done editing")
print()

term.write("Edit text: ")
local result = editLine("prepopulated text here")
print("You entered: " .. result)

print()
term.write("Edit name: ")
local name = editLine("John Doe")
print("Name: " .. name)

print()
term.write("Edit empty: ")
local empty = editLine("")
print("Result: " .. empty)
