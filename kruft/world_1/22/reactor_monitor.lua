-- Powah Uraninite Reactor Monitor
-- CC:Tweaked Lua program for monitoring a Powah mod Uraninite Reactor

--------------------------------------------------
-- Configuration Constants
--------------------------------------------------

-- Peripheral locations
local REACTOR_SIDE = "top"
local TELEMETRY_MODEM_SIDE = "bottom"

-- Telemetry
-- Uses the computer's label as the ID. Defaults to "reactor_01" if no label is set.
local REACTOR_ID = os.getComputerLabel() or "reactor_01"
local TELEMETRY_PROTOCOL = "reactor_telemetry"

-- Tank capacity (not provided by API)
local COOLANT_TANK_CAPACITY = 1000  -- mB

-- Resource thresholds (item counts out of 64)
local SLOT_WARNING_THRESHOLD = 63   -- Yellow if at or below this
local SLOT_CRITICAL_THRESHOLD = 32  -- Red if below this

-- Coolant thresholds (mB)
local COOLANT_WARNING_THRESHOLD = 800   -- Yellow if below (80%)
local COOLANT_CRITICAL_THRESHOLD = 500  -- Red if below (50%)

-- Temperature thresholds (API value 0-100)
local TEMP_GREEN_MAX = 25    -- Green: 0-25 (0-250*C)
local TEMP_YELLOW_MAX = 75   -- Yellow: 25-75 (250-750*C)
                             -- Red: 75-100 (750-1000*C)

-- Energy averaging
local AVERAGE_WINDOW_SECONDS = 60

-- Display refresh rate (seconds)
local REFRESH_RATE = 0.5

--------------------------------------------------
-- Peripheral Setup
--------------------------------------------------

local reactor = peripheral.wrap(REACTOR_SIDE)
local monitor = peripheral.find("monitor")

if not reactor then
    error("Reactor not found on side: " .. REACTOR_SIDE)
end

if not monitor then
    error("No monitor found on network")
end

-- Set up monitor
monitor.setTextScale(1.0)
monitor.clear()

-- Set up telemetry modem
local telemetryModem = peripheral.wrap(TELEMETRY_MODEM_SIDE)
if telemetryModem and telemetryModem.isWireless and telemetryModem.isWireless() then
    rednet.open(TELEMETRY_MODEM_SIDE)
end

--------------------------------------------------
-- Energy Tracking Variables
--------------------------------------------------

local lastStoredEnergy = 0
local lastTime = os.clock()
local netFET = 0
local energyHistory = {}  -- Array of {time, deltaEnergy} for averaging

--------------------------------------------------
-- Helper Functions
--------------------------------------------------

-- Format large numbers with K and M suffixes
local function formatEnergy(value)
    if value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fK", value / 1000)
    else
        return string.format("%.0f", value)
    end
end

-- Format FE/t with sign
local function formatFET(value)
    local sign = value >= 0 and "+" or ""
    return sign .. formatEnergy(value)
end

-- Get color for temperature (API value 0-100)
local function getTempColor(temp)
    if temp <= TEMP_GREEN_MAX then
        return colors.green
    elseif temp <= TEMP_YELLOW_MAX then
        return colors.yellow
    else
        return colors.red
    end
end

-- Get color for item slot (count 0-64)
local function getItemColor(count)
    if count >= 64 then
        return colors.green
    elseif count >= SLOT_CRITICAL_THRESHOLD then
        return colors.yellow
    else
        return colors.red
    end
end

-- Get color for coolant (0-1000 mB)
local function getCoolantColor(amount)
    if amount >= COOLANT_WARNING_THRESHOLD then
        return colors.green
    elseif amount >= COOLANT_CRITICAL_THRESHOLD then
        return colors.yellow
    else
        return colors.red
    end
end

-- Get color for status
local function getStatusColor(status)
    if status == "ONLINE" then
        return colors.green
    else
        -- PAUSED
        return colors.yellow
    end
end

-- Get item count from a specific slot
local function getSlotCount(slot)
    local item = reactor.getItemDetail(slot)
    if item then
        return item.count
    end
    return 0
end

-- Get liquid coolant amount from tank
local function getCoolantAmount()
    local tanks = reactor.tanks()
    if tanks and tanks[1] then
        return tanks[1].amount or 0
    end
    return 0
end

-- Calculate percentage
local function percentage(current, max)
    if max == 0 then return 0 end
    return (current / max) * 100
end

-- Center text on a line
local function centerText(text, width)
    local padding = math.floor((width - #text) / 2)
    return string.rep(" ", padding) .. text
end

-- Right-align text
local function rightAlign(text, width)
    local padding = width - #text
    return string.rep(" ", padding) .. text
end

-- Write colored text at position
local function writeAt(mon, x, y, text, textColor, bgColor)
    mon.setCursorPos(x, y)
    mon.setTextColor(textColor or colors.white)
    mon.setBackgroundColor(bgColor or colors.black)
    mon.write(text)
end

-- Draw a horizontal line
local function drawLine(mon, y, width)
    mon.setCursorPos(1, y)
    mon.setTextColor(colors.gray)
    mon.setBackgroundColor(colors.black)
    mon.write(string.rep("-", width))
end

-- Draw progress bar
local function drawProgressBar(mon, y, width, current, max)
    local barWidth = width - 4  -- Leave room for brackets and padding
    local filled = math.floor((current / max) * barWidth)
    
    mon.setCursorPos(2, y)
    mon.setTextColor(colors.white)
    mon.setBackgroundColor(colors.black)
    mon.write("[")
    
    -- Filled portion (blue)
    mon.setBackgroundColor(colors.blue)
    mon.write(string.rep(" ", filled))
    
    -- Empty portion (gray)
    mon.setBackgroundColor(colors.gray)
    mon.write(string.rep(" ", barWidth - filled))
    
    mon.setBackgroundColor(colors.black)
    mon.write("]")
end

--------------------------------------------------
-- Data Collection Functions
--------------------------------------------------

local function getReactorData()
    local data = {}
    
    -- Basic status
    data.isRunning = reactor.isRunning()
    data.temperature = reactor.getTemperature()
    data.storedEnergy = reactor.getStoredEnergy()
    data.maxEnergy = reactor.getEnergyCapacity()
    
    -- Resource counts (slots 2-5)
    data.uraninite = getSlotCount(2)
    data.coal = getSlotCount(3)
    data.redstone = getSlotCount(4)
    data.solid = getSlotCount(5)
    data.coolant = getCoolantAmount()
    
    -- Determine status string (Only ONLINE or PAUSED)
    if data.isRunning then
        data.status = "ONLINE"
    else
        data.status = "PAUSED"
    end
    
    return data
end

local function updateEnergyTracking(data)
    local currentTime = os.clock()
    local deltaTime = currentTime - lastTime
    
    if deltaTime > 0 then
        local deltaEnergy = data.storedEnergy - lastStoredEnergy
        -- Convert to FE per tick (20 ticks per second)
        netFET = deltaEnergy / (deltaTime * 20)
        
        -- Add to history for averaging
        table.insert(energyHistory, {
            time = currentTime,
            delta = deltaEnergy,
            duration = deltaTime
        })
        
        -- Remove old entries beyond the averaging window
        local cutoffTime = currentTime - AVERAGE_WINDOW_SECONDS
        while #energyHistory > 0 and energyHistory[1].time < cutoffTime do
            table.remove(energyHistory, 1)
        end
    end
    
    lastStoredEnergy = data.storedEnergy
    lastTime = currentTime
end

local function getAverageFET()
    if #energyHistory == 0 then
        return 0
    end
    
    local totalDelta = 0
    local totalDuration = 0
    
    for _, entry in ipairs(energyHistory) do
        totalDelta = totalDelta + entry.delta
        totalDuration = totalDuration + entry.duration
    end
    
    if totalDuration == 0 then
        return 0
    end
    
    return totalDelta / (totalDuration * 20)
end

local function getAlerts(data)
    local alerts = {}
    
    local SHUTDOWN_ITEM_THRESHOLD = 32
    local SHUTDOWN_COOLANT_THRESHOLD = 500
    local TEMP_YELLOW_MAX = 75

    if data.uraninite < SHUTDOWN_ITEM_THRESHOLD then
        table.insert(alerts, "low_uraninite")
    end
    if data.coal < SHUTDOWN_ITEM_THRESHOLD then
        table.insert(alerts, "low_coal")
    end
    if data.redstone < SHUTDOWN_ITEM_THRESHOLD then
        table.insert(alerts, "low_redstone")
    end
    if data.solid < SHUTDOWN_ITEM_THRESHOLD then
        table.insert(alerts, "low_solid")
    end
    if data.coolant < SHUTDOWN_COOLANT_THRESHOLD then
        table.insert(alerts, "low_coolant")
    end
    if data.temperature > TEMP_YELLOW_MAX then
        table.insert(alerts, "high_temp")
    end
    
    return alerts
end

--------------------------------------------------
-- Display Functions
--------------------------------------------------

local function updateDisplay(data, avgFET)
    local width, height = monitor.getSize()
    
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local line = 1
    
    -- Line 1: Computer Label
    -- We use REACTOR_ID here since it now holds the label (or fallback)
    writeAt(monitor, 1, line, centerText(REACTOR_ID, width), colors.white)
    line = line + 1

    -- Move everything else down one line
    line = line + 1
    
    -- Line 3: STATUS Header
    writeAt(monitor, 1, line, centerText("STATUS", width), colors.white)
    line = line + 1
    
    -- Line 4: Status Value (centered, color coded)
    local statusColor = getStatusColor(data.status)
    writeAt(monitor, 1, line, centerText(data.status, width), statusColor)
    line = line + 1
    
    -- Line 5: Separator
    drawLine(monitor, line, width)
    line = line + 1
    
    -- Line 6: Temperature
    local displayTemp = data.temperature * 10
    local tempColor = getTempColor(data.temperature)
    writeAt(monitor, 2, line, "Temp: ", colors.white)
    writeAt(monitor, 8, line, string.format("%.1fC", displayTemp), tempColor)
    line = line + 1
    
    -- Line 7: Separator
    drawLine(monitor, line, width)
    line = line + 1
    
    -- Line 8: Resources header
    writeAt(monitor, 2, line, "RESOURCES", colors.white)
    line = line + 1
    
    -- Line 9: Uraninite
    local uranPct = percentage(data.uraninite, 64)
    writeAt(monitor, 2, line, "Uraninite:", colors.white)
    writeAt(monitor, 14, line, string.format("%3.0f%%", uranPct), getItemColor(data.uraninite))
    line = line + 1
    
    -- Line 10: Coal
    local coalPct = percentage(data.coal, 64)
    writeAt(monitor, 2, line, "Coal:", colors.white)
    writeAt(monitor, 14, line, string.format("%3.0f%%", coalPct), getItemColor(data.coal))
    line = line + 1
    
    -- Line 11: Redstone
    local redPct = percentage(data.redstone, 64)
    writeAt(monitor, 2, line, "Redstone:", colors.white)
    writeAt(monitor, 14, line, string.format("%3.0f%%", redPct), getItemColor(data.redstone))
    line = line + 1
    
    -- Line 12: Solid Coolant
    local solidPct = percentage(data.solid, 64)
    writeAt(monitor, 2, line, "Solid:", colors.white)
    writeAt(monitor, 14, line, string.format("%3.0f%%", solidPct), getItemColor(data.solid))
    line = line + 1
    
    -- Line 13: Liquid Coolant
    local coolPct = percentage(data.coolant, COOLANT_TANK_CAPACITY)
    writeAt(monitor, 2, line, "Coolant:", colors.white)
    writeAt(monitor, 14, line, string.format("%3.0f%%", coolPct), getCoolantColor(data.coolant))
    line = line + 1
    
    -- Line 14: Separator
    drawLine(monitor, line, width)
    line = line + 1
    
    -- Line 15: Energy output header
    writeAt(monitor, 2, line, "NET ENERGY OUTPUT", colors.white)
    line = line + 1
    
    -- Line 16: Current FE/t
    local currentFETStr = formatFET(netFET) .. " FE/t"
    writeAt(monitor, 2, line, "Current:", colors.white)
    writeAt(monitor, 12, line, currentFETStr, colors.white)
    line = line + 1
    
    -- Line 17: Average FE/t
    local avgFETStr = formatFET(avgFET) .. " FE/t"
    writeAt(monitor, 2, line, "Average:", colors.white)
    writeAt(monitor, 12, line, avgFETStr, colors.white)
    line = line + 1
    
    -- Line 18: Separator
    drawLine(monitor, line, width)
    line = line + 1
    
    -- Line 19: Energy storage header
    writeAt(monitor, 2, line, "ENERGY STORAGE", colors.white)
    line = line + 1
    
    -- Line 20: Progress bar
    drawProgressBar(monitor, line, width, data.storedEnergy, data.maxEnergy)
    line = line + 1
    
    -- Line 21: Current / Max
    local storageStr = formatEnergy(data.storedEnergy) .. " / " .. formatEnergy(data.maxEnergy) .. " FE"
    writeAt(monitor, 2, line, storageStr, colors.white)
    line = line + 1
    
    -- Line 22: Empty
    line = line + 1
    
    -- Line 23: Percentage (centered)
    local energyPct = percentage(data.storedEnergy, data.maxEnergy)
    writeAt(monitor, 1, line, centerText(string.format("%.1f%%", energyPct), width), colors.white)
end

--------------------------------------------------
-- Telemetry Functions
--------------------------------------------------

local function sendTelemetry(data, avgFET)
    if not telemetryModem then
        return
    end
    
    local packet = {
        id = REACTOR_ID,
        status = string.lower(data.status),
        temperature = data.temperature,
        storedEnergy = data.storedEnergy,
        maxEnergy = data.maxEnergy,
        netFET = netFET,
        avgFET = avgFET,
        resources = {
            uraninite = data.uraninite,
            coal = data.coal,
            redstone = data.redstone,
            solid = data.solid,
            coolant = data.coolant
        },
        alerts = getAlerts(data),
        timestamp = os.epoch("utc")
    }
    
    rednet.broadcast(packet, TELEMETRY_PROTOCOL)
end

--------------------------------------------------
-- Main Execution
--------------------------------------------------

local function performUpdate()
    -- Collect data
    local data = getReactorData()
    
    -- Update logic
    updateEnergyTracking(data)
    local avgFET = getAverageFET()
    
    -- Update UI/Comms
    updateDisplay(data, avgFET)
    sendTelemetry(data, avgFET)
end

local function main()
    print("Uraninite Reactor Monitor Starting...")
    print("Reactor ID: " .. REACTOR_ID)
    print("Press Ctrl+T to terminate")
    
    -- Initialize tracking
    lastStoredEnergy = reactor.getStoredEnergy()
    lastTime = os.clock()
    
    -- Initial update
    performUpdate()
    
    -- Start timer
    local timerId = os.startTimer(REFRESH_RATE)
    
    while true do
        local event, p1 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            -- Periodic refresh
            performUpdate()
            timerId = os.startTimer(REFRESH_RATE)
        end
    end
end

-- Run the main loop
main()
