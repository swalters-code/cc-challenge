-- Simple CC:Tweaked "cat" that types out a file
-- Usage: cat.lua <file>

local fs = fs
local shell = shell
local args = {...}

if #args ~= 1 then
  io.stderr:write("Usage: cat.lua <file>\n")
  return
end

local function is_absolute(p)
  return p:sub(1,1) == "/"
end

local path = args[1]

-- Resolve relative paths to the current working directory unless an absolute path is given.
if not is_absolute(path) then
  if shell and type(shell.resolve) == "function" then
    -- Prefer shell.resolve when available (handles .., ~, etc.)
    path = shell.resolve(path)
  else
    -- Fallback: try to prepend the current working directory if available,
    -- otherwise use ./ to indicate a relative path.
    local cwd = "."
    if shell and type(shell.getWorkingDirectory) == "function" then
      cwd = shell.getWorkingDirectory()
    end

    if cwd == "." then
      path = "./" .. path
    else
      if cwd:sub(-1) == "/" then
        path = cwd .. path
      else
        path = cwd .. "/" .. path
      end
    end
  end
end

local handle, err = fs.open(path, "r")
if not handle then
  io.stderr:write(("cat: %s: %s\n"):format(path, err or "cannot open"))
  return
end

-- Prefer readAll (if available), otherwise fall back to chunked readLine/read
if type(handle.readAll) == "function" then
  local ok, content = pcall(handle.readAll, handle)
  if ok then
    io.write(content)
    handle.close()
    return
  end
end

if type(handle.read) == "function" then
  while true do
    local chunk = handle.read(8192)
    if not chunk or chunk == "" then break end
    io.write(chunk)
  end
  handle.close()
  return
end

if type(handle.readLine) == "function" then
  while true do
    local line = handle.readLine()
    if not line then break end
    io.write(line, "\n")
  end
  handle.close()
  return
end

-- If we get here, just close the handle
handle.close()
