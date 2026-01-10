-- barebones.lua
-- Truly minimal, correct, and zero-CPU-usage example

rednet.open("right")                    -- open your modem (change side if your modem is elsewhere)

local POLL_SECONDS = 2                  -- how often to do the periodic task
local pollTimerID = os.startTimer(POLL_SECONDS)   -- start the first timer now

while true do
    -- This line SUSPENDS the program completely until an event arrives.
    -- The computer uses ZERO CPU while waiting — this is the proper way.
    local event, timerOrSenderID = os.pullEvent()

    ----------------------------------------------------------------
    -- 1. Someone sent us a rednet message
    ----------------------------------------------------------------
    if event == "rednet_message" then
        local senderID = timerOrSenderID          -- first parameter
        local message  = select(2, ...)           -- second parameter
        print("[Rednet] " .. senderID .. " → " .. tostring(message))

    ----------------------------------------------------------------
    -- 2. Our own timer fired → time to poll peripherals / do periodic work
    ----------------------------------------------------------------
    elseif event == "timer" and timerOrSenderID == pollTimerID then
        -- ←←←  YOUR REGULAR CODE GOES HERE  →→→
        print("Periodic poll – time: " .. textutils.formatTime(os.time(), true))
        -- Example: local energy = peripheral.call("left", "getEnergyStored")

        -- Schedule the next poll
        pollTimerID = os.startTimer(POLL_SECONDS)
    end
end
