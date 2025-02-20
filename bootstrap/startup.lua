local diskPath = "disk/" -- Default mount path for the disk
local easySyncPath = diskPath .. "easySync"
local syncScript = "/sync.lua"

-- Function to check if a file exists
local function fileExists(path)
    local f = fs.open(path, "r")
    if f then
        f.close()
        return true
    end
    return false
end

-- Step 1: Check if easySync exists on the disk, if not, download it
if not fileExists(easySyncPath) then
    print("Downloading easySync...")
    shell.run("pastebin get jUy6tSPY " .. easySyncPath)
end

-- Step 2: Ensure sync.lua exists, if not, run easySync
if not fileExists(syncScript) then
    print("Running easySync to obtain sync.lua...")
    shell.run(easySyncPath)
end

-- Step 3: Run the sync.lua script
print("Running sync.lua...")
shell.run(syncScript)