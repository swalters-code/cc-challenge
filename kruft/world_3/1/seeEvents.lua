while true do
    local event = { os.pullEvent() }
    local output = "Event: " .. event[1]
    for i = 2, #event do
        output = output .. ", Arg" .. (i - 1) .. ": " .. tostring(event[i])
    end
    print(output)
end
