-- Reactor Command Center
-- Version: 2.0.0 (Activity-Based Twiddler)
-- Description: Centralized monitoring for Powah reactors and resource logistics.

--------------------------------------------------------------------------------
-- 1. Configuration & Constants
--------------------------------------------------------------------------------

local CONFIG = {
    PROTOCOL = "reactor_telemetry",
    TIMEOUT_THRESHOLD = 30, -- seconds to mark offline
    SCAN_RATE = 5,          -- seconds between inventory scans (Data)
    TEXT_SCALE = 1.0,       -- Scale 1.0
    
    -- Resource Definitions
    RESOURCES = {
        {
            label = "Uraninite",
            drawer = "functionalstorage:ender_drawer_3",
            max = 8320,
            items = {
                ["powah:uraninite"]=true, 
                ["ftbmaterials:uranium_ingot"]=true
            }, 
        },
        {
            label = "Coal",
            drawer = "functionalstorage:ender_drawer_4",
            max = 8256,
            items = {["minecraft:coal"]=true},
        },
        {
            label = "Redstone",
            drawer = "functionalstorage:ender_drawer_1",
            max = 8256,
            items = {["minecraft:redstone"]=true},
        },
        {
            label = "Snowballs",
            drawer = "functionalstorage:ender_drawer_0",
            max = 8256,
            items = {["minecraft:snowball"]=true},
        },
        {
            label = "Seeds",
            drawer = "functionalstorage:ender_drawer_2",
            max = 11968, -- Physical limit
            items = {["chicken_roost:chicken_food_tier_8"]=true}, 
        }
    }
}

-- Colors
local C_BG = colors.black
local C_TEXT = colors.white
local C_GOOD = colors.lime
local C_WARN = colors.yellow
local C_BAD = colors.red
local C_HEADER = colors.lightGray

local TWIDDLER_CHARS = {"|", "/", "-", "\\"}

--------------------------------------------------------------------------------
-- 2. State Management
--------------------------------------------------------------------------------

local state = {
    reactors = {},          -- Key: ID, Value: { last_seen, payload, status }
    resources = {},         -- Stores current counts and rate data
    monitor = nil,          -- Peripheral wrapper
    roosts = {},            -- List of found roost/feeder peripherals
    twiddler_frame = 1,     -- Animation frame
    needs_render = true,    -- Flag to trigger render
    
    -- Grid Statistics
    grid = {
        last_total_stored = 0,
        last_calc_time = 0,
        true_net = 0,       
        gen_net = 0,        
        stored = 0,
        max = 0,
        free = 0,
        running = 0,
        total_count = 0,
        cap_percent = 0
    }
}

-- Initialize resource state
for i, res in ipairs(CONFIG.RESOURCES) do
    state.resources[i] = {
        count = 0,
        percent = 0,
        prev_count = 0,
        last_drop_time = os.clock(),
        rate_str = "***",
        avg_str = "***",
        history = {}, 
        status = "OK"
    }
end

--------------------------------------------------------------------------------
-- 3. Helper Functions
--------------------------------------------------------------------------------

local function formatNumber(num)
    local absNum = math.abs(num)
    local prefix = (num < 0) and "-" or ""
    
    if absNum >= 1000000 then
        return string.format("%s%.1fM", prefix, absNum / 1000000)
    elseif absNum >= 1000 then
        return string.format("%s%.1fk", prefix, absNum / 1000)
    else
        return string.format("%s%d", prefix, math.floor(absNum))
    end
end

local function formatTime(seconds)
    if seconds == 0 then return "***" end
    if seconds < 1 then
        return string.format(">%.1f/s", 1/seconds)
    end
    return string.format("%ds/i", math.floor(seconds)) 
end

local function findPeripherals()
    state.monitor = peripheral.find("monitor")
    if not state.monitor then
        error("No Advanced Monitor found.")
    end
    if state.monitor.isColor() then
        state.monitor.setTextScale(CONFIG.TEXT_SCALE)
    end
    
    state.roosts = {}
    local periphs = peripheral.getNames()
    for _, p in ipairs(periphs) do
        local pType = peripheral.getType(p) or ""
        if string.find(pType, "roost") or string.find(pType, "feeder") then 
             table.insert(state.roosts, peripheral.wrap(p))
        end
    end
end

--------------------------------------------------------------------------------
-- 4. Core Logic
--------------------------------------------------------------------------------

local function scanInventory()
    local currentTime = os.clock()

    for i, config in ipairs(CONFIG.RESOURCES) do
        local resState = state.resources[i]
        local totalCount = 0

        -- Scan Drawer
        if peripheral.isPresent(config.drawer) then
            local drawer = peripheral.wrap(config.drawer)
            local list = drawer.list()
            if list then
                for slot, item in pairs(list) do
                    if config.items[item.name] then
                        totalCount = totalCount + item.count
                    end
                end
            end
        end

        -- Scan Roosts
        for _, container in ipairs(state.roosts) do
            pcall(function() 
                local list = container.list()
                if list then
                    for slot, item in pairs(list) do
                        if config.items[item.name] then
                            totalCount = totalCount + item.count
                        end
                    end
                end
            end)
        end

        -- Rate Calculation
        local previous = resState.prev_count
        
        if totalCount < previous then
            local delta = previous - totalCount
            local elapsed = currentTime - resState.last_drop_time
            if elapsed <= 0 then elapsed = CONFIG.SCAN_RATE end

            local secondsPerItem = elapsed / delta
            local itemsPerSecond = delta / elapsed
            
            resState.last_drop_time = currentTime
            resState.rate_str = formatTime(secondsPerItem)
            
            table.insert(resState.history, 1, itemsPerSecond)
            if #resState.history > 10 then table.remove(resState.history) end
            
            local sum = 0
            for _, rate in ipairs(resState.history) do sum = sum + rate end
            local avgRate = sum / #resState.history
            
            if avgRate > 0 then
                resState.avg_str = formatTime(1 / avgRate)
            else
                resState.avg_str = "***"
            end
        
        elseif totalCount > previous then
            resState.last_drop_time = currentTime
        else 
            if (currentTime - resState.last_drop_time) > 300 then
                resState.rate_str = "***"
            end
        end

        resState.prev_count = totalCount
        resState.count = totalCount
        resState.percent = (totalCount / config.max) * 100
        
        if resState.percent < 90 then resState.status = "LOW!" else resState.status = "OK" end
    end
end

local function checkLiveness()
    local now = os.clock()
    for id, reactor in pairs(state.reactors) do
        if (now - reactor.last_seen) > CONFIG.TIMEOUT_THRESHOLD then
            reactor.status = "offline"
        end
    end
end

local function calculateGridStats()
    local now = os.clock()
    local agg = {
        running = 0, total_count = 0, stored = 0, max = 0, gen_net = 0, free = 0, cap_percent = 0
    }
    
    for id, r in pairs(state.reactors) do
        agg.total_count = agg.total_count + 1
        if r.status == "online" then agg.running = agg.running + 1 end

        if r.status ~= "offline" then
            if r.payload then
                local s = r.payload.storedEnergy or 0
                local m = r.payload.maxEnergy or 0
                agg.stored = agg.stored + s
                agg.max = agg.max + m
                agg.gen_net = agg.gen_net + (r.payload.netFET or 0)
            end
        end
    end
    
    if agg.max > 0 then
        agg.cap_percent = (agg.stored / agg.max) * 100
        agg.free = agg.max - agg.stored
    end

    local true_net = 0
    if state.grid.last_calc_time > 0 then
        local dt = now - state.grid.last_calc_time
        local ticks = dt * 20
        if ticks > 0 then
            local delta = agg.stored - state.grid.last_total_stored
            true_net = delta / ticks
        end
    end

    state.grid.running = agg.running
    state.grid.total_count = agg.total_count
    state.grid.stored = agg.stored
    state.grid.max = agg.max
    state.grid.free = agg.free
    state.grid.cap_percent = agg.cap_percent
    state.grid.gen_net = agg.gen_net
    state.grid.true_net = true_net
    
    state.grid.last_total_stored = agg.stored
    state.grid.last_calc_time = now
end

--------------------------------------------------------------------------------
-- 5. Rendering
--------------------------------------------------------------------------------

local function drawText(mon, x, y, text, color)
    mon.setCursorPos(x, y)
    mon.setTextColor(color)
    mon.write(text)
end

local function render()
    local mon = state.monitor
    mon.setBackgroundColor(C_BG)
    mon.clear()
    
    local w, h = mon.getSize()
    local g = state.grid
    
    -- Twiddler (Increment Frame)
    local tIdx = (state.twiddler_frame % 4) + 1
    state.twiddler_frame = state.twiddler_frame + 1
    drawText(mon, w, 1, TWIDDLER_CHARS[tIdx], C_TEXT)
    
    -- Global Resources
    drawText(mon, 2, 1, "RES       | COUNT  | %   | CUR      | AVG      | STS", C_HEADER)
    drawText(mon, 2, 2, string.rep("-", w-4), C_HEADER)
    
    for i, res in ipairs(CONFIG.RESOURCES) do
        local s = state.resources[i]
        local y = 2 + i
        local colorStatus = (s.status == "OK") and C_GOOD or C_BAD
        
        local lineBase = string.format("%-9s | %-6s | %3d%% | %-8s | %-8s | ", 
            string.sub(res.label, 1, 9), formatNumber(s.count), math.floor(s.percent), s.rate_str, s.avg_str
        )
        drawText(mon, 2, y, lineBase, C_TEXT)
        mon.setTextColor(colorStatus)
        mon.write(s.status)
    end

    -- System Totals
    local yOffset = 9
    drawText(mon, 2, yOffset, "SYSTEM TOTALS", C_HEADER)
    drawText(mon, 2, yOffset+1, string.format("Running: [%d] / [%d]", g.running, g.total_count), C_TEXT)
    
    local trueNetColor = (g.true_net >= 0) and C_GOOD or C_BAD
    drawText(mon, 2, yOffset+2, "Net: ", C_TEXT)
    local trueNetStr = string.format("%+d FE/t", math.floor(g.true_net))
    drawText(mon, 7, yOffset+2, trueNetStr, trueNetColor)
    
    local genVal = formatNumber(g.gen_net)
    if g.gen_net >= 0 then genVal = "+" .. genVal end 
    drawText(mon, 7 + #trueNetStr, yOffset+2, string.format(" (%s Gen)", genVal), colors.gray)
    
    local storedStr = string.format("Stored: %s / %s (%s) %d%%", 
        formatNumber(g.stored), formatNumber(g.max), formatNumber(g.free), math.floor(g.cap_percent)
    )
    drawText(mon, 2, yOffset+3, storedStr, C_TEXT)

    -- Reactor Grid
    yOffset = 14
    drawText(mon, 2, yOffset, "ID         | S | PWR% | NET      | AVG      | TEMP | RES%", C_HEADER)
    drawText(mon, 2, yOffset+1, string.rep("-", w-4), C_HEADER)
    
    local sortedKeys = {}
    for k in pairs(state.reactors) do table.insert(sortedKeys, k) end
    table.sort(sortedKeys)
    
    for idx, key in ipairs(sortedKeys) do
        local r = state.reactors[key]
        local y = yOffset + 1 + idx
        if y > h then break end 
        local p = r.payload or {}
        
        local sChar = "S"; local sColor = C_BAD
        if r.status == "online" then sChar = "R"; sColor = C_GOOD 
        elseif r.status == "paused" then sChar = "P"; sColor = C_WARN end
        
        local pwr = 0
        if p.maxEnergy and p.maxEnergy > 0 then pwr = (p.storedEnergy/p.maxEnergy)*100 end
        
        local netStr = "---"; local avgStr = "---"; local tempStr = "---"; local resP = "---"
        if r.status ~= "offline" then
            netStr = formatNumber(p.netFET or 0)
            avgStr = formatNumber(p.avgFET or 0)
            tempStr = string.format("%d", p.temperature or 0)
            resP = "OK" 
        end
        
        drawText(mon, 2, y, string.format("%-10s", string.sub(key, 1, 10)), C_TEXT)
        drawText(mon, 13, y, sChar, sColor)
        drawText(mon, 15, y, string.format("  | %3d%% | %-8s | %-8s | %-4s | %s", pwr, netStr, avgStr, tempStr, resP), C_TEXT)
    end
    
    state.needs_render = false
end

--------------------------------------------------------------------------------
-- 6. Main Loops
--------------------------------------------------------------------------------

local function telemetryListener()
    local modemSide = nil
    for _, side in ipairs(rs.getSides()) do
        if peripheral.getType(side) == "modem" then
            if peripheral.call(side, "isWireless") then
                modemSide = side
                break
            end
        end
    end
    if modemSide then rednet.open(modemSide); print("Listening on " .. modemSide)
    else print("Warning: No wireless modem found!") end
    
    while true do
        local senderId, message = rednet.receive(CONFIG.PROTOCOL)
        if type(message) == "table" and message.id then
            state.reactors[message.id] = {
                last_seen = os.clock(),
                payload = message,
                status = message.status or "online" 
            }
            state.needs_render = true -- Trigger render on next loop pass (or immediately via parallel event)
            os.queueEvent("trigger_render") -- Wake up systemTick
        end
    end
end

local function systemTick()
    findPeripherals() 
    local timerId = os.startTimer(CONFIG.SCAN_RATE)
    
    -- Initial Render
    scanInventory()
    calculateGridStats()
    render()
    
    while true do
        local event, p1 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            -- Scheduled Scan
            scanInventory()
            checkLiveness()
            calculateGridStats()
            render() -- Render updates twiddler
            timerId = os.startTimer(CONFIG.SCAN_RATE)
            
        elseif event == "trigger_render" then
            -- Activity heartbeat (from rednet)
            render() -- Render updates twiddler
        end
    end
end

-- Entry Point
term.clear()
print("Reactor Command Center Starting...")
parallel.waitForAny(telemetryListener, systemTick)
