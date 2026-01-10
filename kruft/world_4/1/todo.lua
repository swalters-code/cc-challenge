local isUsing = true
local maxX, maxY = term.getSize()
local color1 = colors.lime
local color2 = colors.white
if fs.exists("/.todocfg") then
  local opfile = fs.open("/.todocfg", "r")
  color1 = tonumber(opfile.readLine())
  color2 = tonumber(opfile.readLine())
  opfile.close()
end

local colnames = {[0] = "White",
                [1] = "Orange",
                [2] = "Magenta",
                [3] = "Light Blue",
                [4] = "Yellow",
                [5] = "Lime",
                [6] = "Pink",
                [7] = "Gray",
                [8] = "Light Gray",
                [9] = "Cyan",
                [10] = "Purple",
                [11] = "Blue",
                [12] = "Brown",
                [13] = "Green",
                [14] = "Red",
                [15] = "Black"}
               
local numconv = {[0] = colors.white,
                [1] = colors.orange,
                [2] = colors.magenta,
                [3] = colors.lightBlue,
                [4] = colors.yellow,
                [5] = colors.lime,
                [6] = colors.pink,
                [7] = colors.gray,
                [8] = colors.lightGray,
                [9] = colors.cyan,
                [10] = colors.purple,
                [11] = colors.blue,
                [12] = colors.brown,
                [13] = colors.green,
                [14] = colors.red,
                [15] = colors.black}

--Maybe need to rewrite this :P
local choice = 0
local choice2 = 0
while numconv[choice] ~= color1 do
    choice=choice+1
end 
while numconv[choice2] ~= color2 do
    choice2=choice2+1
end
local taskFile = "/.tasks"
local page = 1
local Options = false

local function getTasks()
 if not fs.exists(taskFile) then
  local A = fs.open(taskFile, "w")
  A.write("{}")
  A.close()
  return {}
 else
  local A = fs.open(taskFile, "r")
  local tmp = textutils.unserialize(A.readAll())
  A.close()
  return tmp
 end
end

local function redraw(page)
 if isUsing and not Options then
    local tasks = getTasks()
    local nMaxY = maxY - 2
 
    term.clear()
    term.setCursorPos(1,1)
    term.setBackgroundColour(color1)
    if color1 ~= color2 and color1 ~= colors.white then
        term.setTextColour(color2)
    elseif color1 == color2 and color1 ~= colors.white then
        term.setTextColor(colors.white)
    else
        term.setTextColor(colors.black)
    end
    term.clearLine()
    print(" + / -  |")
    term.setCursorPos(maxX-12,1)
    print("Options  Exit")
    
    for i=1, nMaxY do
        if i%2 == 1 and color1 ~= color2 then
            term.setBackgroundColour(color2)
            term.setTextColour(color1)
        elseif color1 ~= color2 then
            term.setBackgroundColour(color1)
            term.setTextColour(color2)
        elseif color1 == colors.white then
            term.setBackgroundColor(color1)
            term.setTextColor(colors.black)
        else
            term.setBackgroundColor(color1)
            term.setTextColor(colors.black)
        end
  
        term.setCursorPos(1,1+i)
        term.clearLine()
  
        local num = i+(nMaxY*(page-1))
  
        if tasks[num] ~= nil then
            write(num..": "..tasks[num])
        else
            write(num..": ")
        end
    end
 
 if maxY%2 == 0 and color1 ~= color2 then
  term.setBackgroundColour(color2)
  term.setTextColour(color1)
 elseif color1 ~= color2 then
  term.setBackgroundColour(color1)
  term.setTextColour(color2)
 elseif color1 == colors.white then
    term.setBackgroundColor(color1)
    term.setTextColor(colors.black)
 else
    term.setBackgroundColor(color1)
    term.setTextColor(colors.white)
 end 
term.setCursorPos(2,maxY)
 term.clearLine()
 write("<")
 term.setCursorPos((maxX/2-#tostring(page)/2)+1,maxY)
 write(page)
 term.setCursorPos(maxX-1,maxY)
 write(">")
 elseif not isUsing and not Options then --Exited program
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    print("Goodbye !")
 elseif isUsing and Options then
    term.setBackgroundColor(colors.gray)
    if color1 ~= colors.white then
        term.setTextColor(colors.white)
    else
        term.setTextColor(colors.black)
    end
    term.clear()
    color1 = numconv[choice]
    color2 = numconv[choice2]
    term.setCursorPos(1,1)
    term.setBackgroundColor(color1)
    term.clearLine()
    term.setCursorPos(maxX-(maxX-2),1)
    print("Options")
    term.setCursorPos(math.ceil(maxX/2)+1,1)
    print("|")
    term.setCursorPos(maxX-6,1)
    print("Return")
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.setCursorPos(15,3)
    print("<->")
    paintutils.drawLine(14,4,14+string.len(colnames[choice]),4,numconv[choice])
    term.setCursorPos(3,4)
    if color1 ~= colors.white then
        term.setTextColor(colors.white)
    else
        term.setTextColor(colors.black)
    end
    print("1st color : " .. colnames[choice])
    term.setBackgroundColor(colors.gray)
    paintutils.drawLine(14,6,14+string.len(colnames[choice2]),6,numconv[choice2])
    if color2 ~= colors.white then
        term.setTextColor(colors.white)
    else
        term.setTextColor(colors.black)
    end
    term.setCursorPos(3,6)
    print("2nd color : " .. colnames[choice2])
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.setCursorPos(15,7)
    print("<->")
    term.setCursorPos(5,10)
    print("About this program")
    term.setCursorPos(4,12)
    print("HD's Todo list V1.6")
    term.setCursorPos(1,14)
    print("-masterdisasterHD : Orignal program and idea")
    term.setCursorPos(1,17)
    print("-s0r00t : V1.5 enhancements")
    
 end
end

local function saveTasks(tbl)
 local A = fs.open(taskFile, "w")
 A.write(textutils.serialize(tbl))
 A.close()
end

local function addTask()
 local tasks = getTasks()
 term.setBackgroundColour(colors.black)
 term.setTextColour(colors.white)
 term.clear()
 term.setCursorPos(1,1)
 term.setCursorBlink(true)
 write("Task: ")
 local tsk = read()
 table.insert(tasks, tsk)
 saveTasks(tasks)
end

local function delTask()
 local tasks = getTasks()
 term.setBackgroundColour(colors.black)
 term.setTextColour(colors.white)
 term.clear()
 term.setCursorPos(1,1)
 write("Task number: ")
 local tsknmbr = tonumber(read())
 table.remove(tasks, tsknmbr)
 saveTasks(tasks)
end

local function showTask(pg, pos, h, w)
 local tasks = getTasks()
 local step1 = (h-2)*(pg-1)
 local step2 = (pos-1)+step1
 term.setBackgroundColour(color2)
 term.setTextColour(color1)
 term.clear()
 term.setCursorPos(1,1)
 if tasks[step2] ~= nil then
  write("Task #"..step2..":")
  local text = tasks[step2]
  local k = 1
  for i=1, h-1 do
   term.setCursorPos(1,i+1)
   for j=1,w do
    write(string.sub(text, k, k))
    k = k + 1
   end
  end
 term.setCursorPos(1,h)
 write("Press any key to continue")
 os.pullEvent("key")
 end
end

--Program loop
redraw(page)
local maxX, maxY = term.getSize()
while isUsing do
 sleep(0)
 ev, b, xPos, yPos = os.pullEvent()
 if ev == "mouse_click" then
  if xPos == 2 and yPos == 1 and not Options then
   addTask()
  elseif xPos == 6 and yPos == 1 and not Options then
   delTask()
  elseif xPos >= maxX-12 and xPos <= maxX-4 and yPos == 1 and not Options then
  Options = true
  elseif xPos >=maxX-3 and xPos <= maxX and yPos == 1 and not Options then
  isUsing = false
  elseif xPos == 2 and yPos == maxY and not Options then
   if page > 1 then
    page = page - 1
   end
  elseif xPos == maxX-1 and yPos == maxY and not Options then
   page = page + 1
  elseif xPos > 1 and yPos < maxY and not Options then
   showTask(page, yPos, maxY, maxX)
  elseif xPos >= maxX-6 and xPos <= maxX-1 and yPos == 1 and Options then
   Options = false
   local opfile = fs.open("/.todocfg", "w")
   opfile.writeLine(color1)
   opfile.write(color2)
   opfile.close()
  elseif xPos == 15 and yPos == 3 and Options then
    if choice-1 ~= -1 then
        choice = choice-1
    else
        choice = 15
    end
    redraw(page)
  elseif xPos == 17 and yPos == 3 and Options then
    if choice+1 ~= 16 then
        choice = choice+1
    else
        choice = 0
    end
    redraw(page)
  elseif xPos == 15 and yPos == 7 and Options then
    if choice2-1 ~= -1 then
        choice2 = choice2-1
    else
        choice2 = 15
    end
    redraw(page)
  elseif xPos == 17 and yPos == 7 and Options then
    if choice2+1 ~= 16 then
        choice2 = choice2+1
    else
        choice2 = 0
    end
    redraw(page)
   end
 elseif ev == "mouse_scroll" then
  if b == -1 then
   if page > 1 then page = page - 1 end
  elseif b == 1 then
   page = page + 1
  end
 end
 redraw(page)
end