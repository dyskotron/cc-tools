-- Compact Sync Script for Downloading Files

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

-- Server Configuration
local SERVER_URL = "https://spectacled-clammy-mask.glitch.me"
local FILES_COMMAND = "/files"
local DOWNLOAD_COMMAND = "/download"

-- Fetch and process file metadata
local function fetchFileMetadata()
    print("Fetching file metadata from server...")

    local response = http.get(SERVER_URL .. FILES_COMMAND)
    if not response then
        print("Error: Unable to fetch file list from server.")
        return nil, nil
    end

    local raw_data = response.readAll()
    response.close()

    if not raw_data or raw_data == "" then
        print("Error: Server returned an empty response.")
        return nil, nil
    end

    print("Raw Data Received:\n" .. raw_data)

    local files = {}
    local totalBytes = 0

    for line in raw_data:gmatch("[^\n]+") do
        local filename, size = line:match("([^|]+)|(%d+)")
        if filename and size then
            size = tonumber(size)
            table.insert(files, {name = filename, size = size})
            totalBytes = totalBytes + size
            print("Parsed file:", filename, "Size:", size)
        else
            print("Warning: Could not parse line:", line)
        end
    end

    if #files == 0 then
        print("No valid files found.")
        return nil, nil
    end

    print("File metadata fetched successfully.")
    return files, totalBytes
end


-- Download a single file
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

-- Download all files from the server
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

-- Main Execution
local function main()
    print("Starting file sync...")
    downloadAllFiles()
    print("File sync complete.")
end

main()