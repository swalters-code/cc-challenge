-- Interactive Lua REPL that logs each input (prefixed) and its pretty-printed output/error to a file.
-- Usage: lua_logger <logfile>
-- The file output uses an internal Lua-code-style pretty-printer that aims to produce
-- valid Lua expressions which (when reasonably simple) evaluate back to the same structure.
-- Limitations:
--  - Functions, userdata and threads are not serialised; they become "nil --[[unsupported]]".
--  - Cyclic tables are detected and replaced by "{} --[[cycle]]" (still valid Lua, but not faithful).
--  - Metatables are not preserved.
-- These trade-offs keep the output valid Lua while remaining readable and editor-like.

local tArgs = { ... }
if #tArgs ~= 1 then
    print("Usage: lua_logger <logfile>")
    print("This is an interactive Lua prompt that logs I/O to the given file.")
    print("To run a lua program, just type its name.")
    return
end

local logPath = tArgs[1]
if shell and shell.resolve then pcall(function() logPath = shell.resolve(logPath) end) end

local function safe_call(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil
end

local function make_prefix()
    local name = safe_call(function() if os.getComputerLabel then return os.getComputerLabel() end end) or ""
    if not name or name == "" then name = "computer" end

    local id = safe_call(function() if os.getComputerID then return tostring(os.getComputerID()) end end) or ""
    if not id or id == "" then
        id = safe_call(function() if computer and computer.getID then return tostring(computer.getID()) end end) or "unknown"
    end

    local timestamp = safe_call(function() if os.date then return os.date("%Y-%m-%d-%H-%M-%S") end end)
    if not timestamp then
        if textutils and textutils.formatTime and os and os.time then
            timestamp = textutils.formatTime(os.time(), true)
        else
            timestamp = "unknown-time"
        end
    end

    return " -- " .. tostring(name) .. ":" .. tostring(id) .. ":" .. tostring(timestamp) .. "> "
end

local function appendLog(text)
    local ok, fh_or_err = pcall(fs.open, logPath, "a")
    if not ok or not fh_or_err then
        printError("Failed to write to log file: " .. tostring(fh_or_err))
        return
    end
    local fh = fh_or_err

    if type(text) ~= "string" then
        if textutils and textutils.serialise then
            text = textutils.serialise(text)
        else
            text = tostring(text)
        end
    end

    text = text:gsub("\r\n", "\n")
    local pos = 1
    while true do
        local nl = string.find(text, "\n", pos, true)
        if not nl then
            fh.writeLine(string.sub(text, pos))
            break
        end
        fh.writeLine(string.sub(text, pos, nl - 1))
        pos = nl + 1
    end

    fh.close()
end

-- Pretty-printer that outputs Lua code-like representation.
-- Aims for readable, properly indented output that evaluates back to the same basic structure.
local function is_identifier(s)
    return type(s) == "string" and s:match("^[%a_][%w_]*$") ~= nil
end

local function escape_string(s)
    -- Use %q to escape reliably (includes quotes and escapes).
    -- For readability, keep it as %q.
    return string.format("%q", s)
end

local function is_array_like(t)
    -- Determine if table is a simple array 1..n with no holes
    local maxn = 0
    local count = 0
    for k, _ in pairs(t) do
        if type(k) == "number" and k > 0 and math.floor(k) == k then
            if k > maxn then maxn = k end
        end
        count = count + 1
    end
    return maxn > 0 and maxn == count
end

local function table_length_sequence(t)
    local n = 0
    for i = 1, math.huge do
        if t[i] == nil then break end
        n = n + 1
    end
    return n
end

local function serialize_lua(value, opts)
    opts = opts or {}
    local indent_str = string.rep(" ", opts.indent or 2)
    local maxDepth = opts.maxDepth or 1000
    local visited = {}  -- table -> true to detect cycles

    local function serialize(val, depth)
        if depth > maxDepth then
            return "nil --[[max depth]]"
        end

        local t = type(val)
        if t == "nil" then return "nil" end
        if t == "boolean" then return tostring(val) end
        if t == "number" then return tostring(val) end
        if t == "string" then return escape_string(val) end
        if t == "function" then return "nil --[[function]]" end
        if t == "thread" or t == "userdata" then return "nil --[[unsupported]]" end

        if t == "table" then
            if visited[val] then
                return "{} --[[cycle]]"
            end
            visited[val] = true

            -- Distinguish array-like vs map-like
            local n = table_length_sequence(val)
            local array_like = (n > 0 and (n == (#(val)))) -- fallback; #(val) isn't reliable, so rely on n and pair count heuristics
            -- Build ordered lists: first numeric 1..n, then other keys sorted for stability
            local parts = {}

            -- Helper to produce indentation
            local function ind(level) return string.rep(indent_str, level) end

            -- Collect non-array keys for stable ordering
            local map_keys = {}
            local key_count = 0
            for k, _ in pairs(val) do
                if not (type(k) == "number" and k >= 1 and math.floor(k) == k and k <= n) then
                    key_count = key_count + 1
                    map_keys[key_count] = k
                end
            end
            table.sort(map_keys, function(a, b)
                local ta, tb = type(a), type(b)
                if ta == tb then
                    return tostring(a) < tostring(b)
                end
                return ta < tb
            end)

            -- Decide whether to render compactly on one line or multi-line
            local can_compact = (n == 0 and key_count == 0) or (n + key_count <= 4)
            if n == 0 and key_count == 0 then
                visited[val] = nil
                return "{}"
            elseif can_compact then
                -- compact single-line form: { v1, v2, k = v, ... }
                local items = {}
                for i = 1, n do
                    table.insert(items, serialize(val[i], depth + 1))
                end
                for _, k in ipairs(map_keys) do
                    local ks
                    if is_identifier(k) then
                        ks = tostring(k)
                    else
                        ks = "[" .. serialize(k, depth + 1) .. "]"
                    end
                    local vs = serialize(val[k], depth + 1)
                    table.insert(items, ks .. " = " .. vs)
                end
                visited[val] = nil
                return "{ " .. table.concat(items, ", ") .. " }"
            else
                -- multi-line form
                local lines = {}
                table.insert(lines, "{")
                -- array part
                for i = 1, n do
                    local v = val[i]
                    local s = serialize(v, depth + 1)
                    table.insert(lines, ind(depth + 1) .. s .. ",")
                end
                -- map part
                for _, k in ipairs(map_keys) do
                    local ks
                    if is_identifier(k) then
                        ks = tostring(k)
                    else
                        ks = "[" .. serialize(k, depth + 1) .. "]"
                    end
                    local vs = serialize(val[k], depth + 1)
                    table.insert(lines, ind(depth + 1) .. ks .. " = " .. vs .. ",")
                end
                table.insert(lines, ind(depth) .. "}")
                visited[val] = nil
                return table.concat(lines, "\n")
            end
        end

        -- fallback
        return "nil --[[" .. tostring(val) .. "]]"
    end

    return serialize(value, 0)
end

-- Keep original pretty for terminal output
local pretty = require "cc.pretty"
local exception = require "cc.internal.exception"

local running = true
local tCommandHistory = {}
local tEnv = {
    ["exit"] = setmetatable({}, {
        __tostring = function() return "Call exit() to exit." end,
        __call = function() running = false end,
    }),
    ["_echo"] = function(...) return ... end,
}
setmetatable(tEnv, { __index = _ENV })

do
    local make_package = require "cc.require".make
    local dir = shell and shell.dir and shell.dir() or "."
    tEnv.require, tEnv.package = make_package(tEnv, dir)
end

if term.isColour() then term.setTextColour(colours.yellow) end
print("Interactive Lua prompt (logging to " .. tostring(logPath) .. ").")
print("Call exit() to exit.")
term.setTextColour(colours.white)

local chunk_idx, chunk_map = 1, {}
while running do
    write("lua> ")

    local input = read(nil, tCommandHistory, function(sLine)
        if settings.get("lua.autocomplete") then
            local nStartPos = string.find(sLine, "[a-zA-Z0-9_%.:]+$")
            if nStartPos then sLine = string.sub(sLine, nStartPos) end
            if #sLine > 0 then return textutils.complete(sLine, tEnv) end
        end
        return nil
    end)

    if input:match("%S") and tCommandHistory[#tCommandHistory] ~= input then
        table.insert(tCommandHistory, input)
    end

    -- Log the raw input, prefixed per request
    appendLog(make_prefix() .. input)

    if settings.get("lua.warn_against_use_of_local") and input:match("^%s*local%s+") then
        if term.isColour() then term.setTextColour(colours.yellow) end
        print("To access local variables in later inputs, remove the local keyword.")
        term.setTextColour(colours.white)
    end

    local name, offset = "=lua[" .. chunk_idx .. "]", 0

    local func, err = load(input, name, "t", tEnv)
    if load("return " .. input) then
        func = load("return _echo(" .. input .. "\n)", name, "t", tEnv)
        offset = 13 -- "return _echo("
    end

    if func then
        chunk_map[name] = { contents = input, offset = offset }
        chunk_idx = chunk_idx + 1

        local results = table.pack(exception.try(func))
        if results[1] then
            for i = 2, results.n do
                local value = results[i]
                -- Terminal output (original pretty)
                local ok_term, serialised = pcall(pretty.pretty, value, {
                    function_args = settings.get("lua.function_args"),
                    function_source = settings.get("lua.function_source"),
                })
                if ok_term then
                    pretty.print(serialised)
                else
                    print(tostring(value))
                end

                -- File output: use our Lua-code-style pretty printer
                local logged = serialize_lua(value, { indent = 2, maxDepth = 20 })
                appendLog("OUTPUT:")
                appendLog(logged)
            end
        else
            local errMsg = tostring(results[2])
            printError(errMsg)
            appendLog("ERROR: " .. errMsg)

            if results[3] then
                appendLog("TRACEBACK:")
                if type(results[3]) == "string" then
                    appendLog(results[3])
                elseif textutils and textutils.serialise then
                    appendLog(textutils.serialise(results[3]))
                else
                    appendLog(tostring(results[3]))
                end
            end

            exception.report(results[2], results[3], chunk_map)
        end
    else
        local parser = require "cc.internal.syntax"
        if parser.parse_repl(input) then
            printError(err)
            appendLog("PARSE_ERROR: " .. tostring(err))
        end
    end
end
