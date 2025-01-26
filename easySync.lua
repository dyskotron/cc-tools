-- Simplified Sync Script for Downloading Files

-- Base64 Encoding/Decoding (Required for File Data)
local base64 = {}
local base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
local charAt, indexOf = {}, {}
local blshift = bit32.lshift
local brshift = bit32.rshift
local band = bit32.band
local bor = bit32.bor

for i = 1, #base64chars do
    local char = base64chars:sub(i, i)
    charAt[i - 1] = char
    indexOf[char] = i - 1
end

function base64.decode(data)
    local decoded = {}
    local inChars = {}
    for char in data:gmatch(".") do
        inChars[#inChars + 1] = char
    end
    for i = 1, #inChars, 4 do
        local b = {indexOf[inChars[i]], indexOf[inChars[i + 1]], indexOf[inChars[i + 2]], indexOf[inChars[i + 3]]}
        decoded[#decoded + 1] = bor(blshift(b[1], 2), brshift(b[2], 4)) % 256
        if b[3] < 64 then
            decoded[#decoded + 1] = bor(blshift(b[2], 4), brshift(b[3], 2)) % 256
            if b[4] < 64 then
                decoded[#decoded + 1] = bor(blshift(b[3], 6), b[4]) % 256
            end
        end
    end
    return string.char(unpack(decoded))
end

-- Progress Bar Display
local function renderProgressBar(progress, message)
    term.clear()
    term.setCursorPos(1, 1)

    local w, h = term.getSize()
    local msgX = math.floor((w - #message) / 2) + 1
    local msgY = math.floor(h / 2) - 1
    term.setCursorPos(msgX, msgY)
    term.write(message)

    local barWidth = 30
    local filled = math.floor(progress * barWidth)
    local bar = string.rep("=", filled) .. string.rep("-", barWidth - filled)

    local barX = math.floor((w - (barWidth + 2)) / 2) + 1
    local barY = msgY + 1
    term.setCursorPos(barX, barY)
    term.write("[" .. bar .. "]")

    local percent = math.floor(progress * 100)
    term.write(" " .. percent .. "%")
end

-- Download Logic
local SERVER_URL = "https://cooperative-whispering-jaborosa.glitch.me"
local FILES_COMMAND = "/files"
local DOWNLOAD_COMMAND = "/download"

local function fetchFileMetadata()
    local response = http.get(SERVER_URL .. FILES_COMMAND)
    if not response then
        print("Error: Unable to fetch file list from server.")
        return nil, nil
    end

    local raw_data = response.readAll()
    response.close()

    local files = {}
    local totalBytes = 0

    for line in raw_data:gmatch("[^\n]+") do
        local filename, size = line:match("([^|]+)|(%d+)")
        if filename and size then
            size = tonumber(size)
            table.insert(files, {name = filename, size = size})
            totalBytes = totalBytes + size
        end
    end

    return files, totalBytes
end

local function downloadFile(filename)
    local url = SERVER_URL .. DOWNLOAD_COMMAND .. "?filename=" .. textutils.urlEncode(filename)
    local response = http.get(url)
    if not response then
        print("Failed to fetch file: " .. filename)
        renderProgressBar(1.0, "Failed: " .. filename)
        sleep(1)
        return
    end

    local data = response.readAll()
    response.close()

    local dir = fs.getDir(filename)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end

    local file = fs.open(filename, "w")
    file.write(data)
    file.close()
end

local function downloadAllFiles()
    local files, totalBytes = fetchFileMetadata()
    if not files or #files == 0 then
        print("No files to download.")
        renderProgressBar(1.0, "No files to update.")
        sleep(1)
        return
    end

    local bytesDownloaded = 0
    for _, file in ipairs(files) do
        downloadFile(file.name)
        bytesDownloaded = bytesDownloaded + file.size
        local progress = bytesDownloaded / totalBytes
        renderProgressBar(progress, "Updating: " .. file.name)
    end

    print("All files downloaded successfully.")
    renderProgressBar(1.0, "All files updated.")
    sleep(2)
end

-- Initialize and Run
local function main()
    print("Starting file sync...")
    downloadAllFiles()
    print("File sync complete.")
end

main()