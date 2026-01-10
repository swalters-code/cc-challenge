-- update_from_github.lua
-- Simple GitHub -> CC:Tweaked updater for private repos using a Personal Access Token.
-- This version: stop using raw.githubusercontent.com and instead fetch blob contents
-- directly from the GitHub API (/git/blobs/:sha). That avoids CDN caching and works
-- with private repos when authenticated properly.
-- Configure these:
local OWNER = "swalters-code"
local REPO  = "turtle-logistics"
local BRANCH = "main"           -- branch to pull from

-- Specify exactly one or two repo-relative directories to download.
-- Defaults: "src" and "dev-tools"
-- Provide values like {"src"} or {"src", "dev-tools"}.
-- Entries may include a trailing slash; they will be normalized.
local DOWNLOAD_DIRS = { "src", "dev-tools" }

-- Hardcoded destination directory on the turtle (set this to the folder you want)
-- Set to "" to write files directly at the repo-relative root
local DEST_DIR = "/logistics"

-- Token file on the turtle (single line containing the token)
local TOKEN_FILE = "/TOKEN_FILE"

local http = http
local fs = fs
local textutils = textutils
local math = math
local string = string

local function normalize_dir(d)
  if not d then return "" end
  -- trim whitespace
  d = d:match("^%s*(.-)%s*$") or ""
  -- remove leading or trailing slashes
  d = d:gsub("^/*", ""):gsub("/*$", "")
  return d
end

-- validate and normalize DOWNLOAD_DIRS
do
  if type(DOWNLOAD_DIRS) ~= "table" then
    error("DOWNLOAD_DIRS must be a table like {\"src\"} or {\"src\", \"dev-tools\"}")
  end
  if #DOWNLOAD_DIRS < 1 or #DOWNLOAD_DIRS > 2 then
    error("Specify exactly one or two directories in DOWNLOAD_DIRS")
  end
  local seen = {}
  for i,d in ipairs(DOWNLOAD_DIRS) do
    if type(d) ~= "string" then error("DOWNLOAD_DIRS entries must be strings") end
    local nd = normalize_dir(d)
    if nd == "" then error("DOWNLOAD_DIRS entries must not be empty") end
    if seen[nd] then error("DOWNLOAD_DIRS contains duplicates: " .. nd) end
    seen[nd] = true
    DOWNLOAD_DIRS[i] = nd
  end
end

local function read_token()
  if not fs.exists(TOKEN_FILE) then
    error("Token file not found: " .. TOKEN_FILE .. ". Create it and put your GitHub token on a single line.")
  end
  local f = fs.open(TOKEN_FILE, "r")
  local t = f.readAll()
  f.close()
  t = t and t:gsub("%s+", "") or ""
  if t == "" then error("Token file is empty") end
  return t
end

local function gh_api_request(path)
  local token = read_token()
  local url = "https://api.github.com" .. path
  local headers = {
    Authorization = "token " .. token,
    ["User-Agent"] = "CC-Tweaked-Updater",
    Accept = "application/vnd.github.v3+json",
  }
  local ok, result = pcall(http.get, url, headers)
  if not ok or not result then
    return nil, "HTTP request failed to " .. url
  end
  local body = result.readAll()
  result.close()
  return body, nil
end

-- List tree (recursive) to find blobs
local function get_tree()
  local path = string.format("/repos/%s/%s/git/trees/%s?recursive=1", OWNER, REPO, BRANCH)
  local body, err = gh_api_request(path)
  if err then return nil, err end
  local data = textutils.unserializeJSON(body)
  if not data or not data.tree then
    return nil, "Failed to parse tree response"
  end
  return data.tree, nil
end

-- Base64 decoder (small pure-Lua implementation)
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local b64lookup = {}
for i = 1, #b64chars do
  b64lookup[string.sub(b64chars, i, i)] = i - 1
end

local function base64_decode(data)
  if not data or data == "" then return "" end
  -- strip any non-base64 characters (including newlines)
  data = data:gsub('[^%w%+%/%=]', '')
  local bytes = {}
  local bit_str = ""
  local len = #data
  local i = 1
  while i <= len do
    local c = data:sub(i,i)
    if c == '=' then
      -- padding: stop consuming further meaningful chars
      break
    end
    local val = b64lookup[c]
    if not val then
      i = i + 1
    else
      -- convert 6 bits to bit string
      for bit = 5, 0, -1 do
        local bit_val = (val >> bit) & 1
        bit_str = bit_str .. (bit_val == 1 and "1" or "0")
      end
      -- if we have at least 8 bits, convert to a byte
      while #bit_str >= 8 do
        local byte_bits = bit_str:sub(1,8)
        bit_str = bit_str:sub(9)
        local byte = 0
        for j = 1, 8 do
          if byte_bits:sub(j,j) == "1" then
            byte = byte + 2^(8-j)
          end
        end
        table.insert(bytes, string.char(byte))
      end
      i = i + 1
    end
  end
  return table.concat(bytes)
end

-- Fetch blob content by SHA using GitHub API (/repos/:owner/:repo/git/blobs/:sha)
local function fetch_blob_by_sha(sha)
  if not sha or sha == "" then
    return nil, "Missing blob SHA"
  end
  local path = string.format("/repos/%s/%s/git/blobs/%s", OWNER, REPO, sha)
  local body, err = gh_api_request(path)
  if err then return nil, err end
  local data = textutils.unserializeJSON(body)
  if not data or not data.content then
    return nil, "Failed to parse blob response"
  end
  if data.encoding == "base64" then
    local ok, decoded = pcall(base64_decode, data.content)
    if not ok then return nil, "Base64 decode failed" end
    return decoded, nil
  else
    -- If not base64 (unexpected), return raw content
    return data.content, nil
  end
end

local function write_file(path, contents)
  -- create directories as needed
  local dir = path:match("(.*/)")
  if dir and not fs.exists(dir) then
    -- recursively create directories
    local cur = ""
    for part in dir:gmatch("[^/]+") do
      cur = cur .. part .. "/"
      if not fs.exists(cur) then fs.makeDir(cur) end
    end
  end
  local f = fs.open(path, "w")
  f.write(contents)
  f.close()
end

-- Helper: check if repoPath is inside any of DOWNLOAD_DIRS, and return the matching dir and the path relative to that dir
local function match_download_dir(repoPath)
  for _, d in ipairs(DOWNLOAD_DIRS) do
    if repoPath == d then
      -- a blob that exactly matches the directory name is unusual, but treat the file name as the base name
      local name = repoPath:match("[^/]+$") or repoPath
      return d, name
    end
    if repoPath:sub(1, #d + 1) == d .. "/" then
      local rel = repoPath:sub(#d + 2) -- substring after "d/"
      return d, rel
    end
  end
  return nil, nil
end

-- Main
print("Starting GitHub update for " .. OWNER .. "/" .. REPO .. "@" .. BRANCH)
print("Downloading directories: " .. table.concat(DOWNLOAD_DIRS, ", "))

-- normalize DEST_DIR: trim whitespace, treat single "/" as root (empty)
local dest = DEST_DIR or ""
dest = dest:match("^%s*(.-)%s*$") or ""
if dest == "/" then dest = "" end

local tree, err = get_tree()
if not tree then
  print("Error listing repo tree: " .. tostring(err))
  return
end

local count = 0
for _, entry in ipairs(tree) do
  if entry.type == "blob" then
    local matched_dir, relpath = match_download_dir(entry.path)
    if matched_dir then
      print("Fetching: " .. entry.path .. " (blob sha: " .. tostring(entry.sha) .. ") -> " .. (dest == "" and relpath or dest .. "/" .. relpath))
      local contents, ferr = fetch_blob_by_sha(entry.sha)
      if not contents then
        print("  Failed: " .. tostring(ferr))
      else
        -- write to DEST_DIR, placing the file under DEST_DIR with the path relative to the selected download directory
        local outPath
        if dest == "" then
          outPath = relpath
        else
          if fs and fs.combine then
            outPath = fs.combine(dest, relpath)
          else
            outPath = dest .. "/" .. relpath
          end
        end
        -- If relpath somehow is empty (shouldn't normally happen), fall back to base name
        if not outPath or outPath == "" then
          local base = entry.path:match("[^/]+$") or entry.path
          if dest == "" then outPath = base else outPath = (fs and fs.combine) and fs.combine(dest, base) or (dest .. "/" .. base) end
        end
        write_file(outPath, contents)
        count = count + 1
      end
    end
  end
end

print("Update complete. Files updated: " .. tostring(count))
