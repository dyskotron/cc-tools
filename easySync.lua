progressBar = {}
logger = {}

function logger.logMessage(string)
    print(string)
end

function logger.clearLogFile()

end

-- Progress Bar Display
function progressBar.render(progress, message)
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
local SERVER_URL = "https://publish-fragrant-cloud-3528.fly.dev"
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

-- Configuration
local SERVER_URL = "https://publish-fragrant-cloud-3528.fly.dev"  -- Updated Fly.io Server URL
local DOWNLOAD_COMMAND = "/download"
local FILES_COMMAND = "/files"

--------------------------------------------------------------------------
-- DOWNLOAD LOGIC
--------------------------------------------------------------------------

-- Fetch and prepare file metadata from the server
function fetchFileMetadata()
    local url = SERVER_URL .. FILES_COMMAND
    local response = http.get(url)
    if not response then
        logger.logMessage("Error: Unable to fetch file list from server.")
        return nil, nil
    end

    local raw_data = response.readAll()
    response.close()

    logger.logMessage("Raw server response:\n" .. raw_data)

    local files = {}
    local totalBytes = 0

    for line in raw_data:gmatch("[^\n]+") do
        logger.logMessage("Processing line: " .. tostring(line))

        -- Extract filename and size
        local filename, size = line:match("([^|]+)|(%d+)")
        if filename and size then
            size = tonumber(size)
            if size >= 0 then
                table.insert(files, {name = filename, size = size})
                totalBytes = totalBytes + size
                logger.logMessage("Added file: " .. filename .. ", Size: " .. size)
            else
                logger.logMessage("Invalid file size (negative): " .. tostring(filename))
            end
        else
            logger.logMessage("Failed to parse line: " .. tostring(line))
        end
    end

    if #files == 0 then
        logger.logMessage("No valid files found in metadata response.")
        return nil, nil
    end

    logger.logMessage("Parsed files: " .. textutils.serialize(files))
    return files, totalBytes
end

function downloadFile(filename)
    logger.logMessage("Starting download for: " .. filename)

    local url = SERVER_URL .. DOWNLOAD_COMMAND .. "?filename=" .. textutils.urlEncode(filename)
    local response = http.get(url)
    if not response then
        logger.logMessage("Failed to fetch file from server: " .. filename)
        progressBar.render(1.0, "Failed: " .. filename)
        sleep(1)
        return
    end

    local data = response.readAll()
    response.close()
    logger.logMessage("Received data for: " .. filename)

    -- Create the directory if necessary
    local dir = fs.getDir(filename)
    if not fs.exists(dir) then
        fs.makeDir(dir)
        logger.logMessage("Created directory: " .. dir)
    end

    -- Write in chunks with progress bar updates
    local totalBytes = #data
    local chunkCount = 60
    local chunkSize = math.max(1, math.floor(totalBytes / chunkCount))

    local file = fs.open(filename, "w")
    if not file then
        logger.logMessage("Failed to open file for writing: " .. filename)
        return
    end

    local downloaded = 0
    for i = 1, totalBytes, chunkSize do
        local chunk = data:sub(i, i + chunkSize - 1)
        file.write(chunk)
        downloaded = downloaded + #chunk

        -- Update progress bar
        local progress = math.min(downloaded / totalBytes, 1.0)
        progressBar.render(progress, "Downloading: " .. filename)

        sleep(0.3) -- Adjust timing for desired effect
    end
    file.close()

    logger.logMessage("Completed download: " .. filename)
    progressBar.render(1.0, "Update complete: " .. filename)
    sleep(0.5)
end

function downloadAllFiles(files, totalBytes)
    if not files or #files == 0 then
        logger.logMessage("No files to download.")
        progressBar.render(1.0, "No files to update.")
        sleep(1)
        return
    end

    local bytesDownloaded = 0

    for _, file in ipairs(files) do
        local filename = file.name
        local fileSize = file.size

        if filename == nil then
            logger.logMessage("Error: filename is nil for file object: " .. textutils.serialize(file))
        else
            logger.logMessage("Downloading: " .. filename)
        end

        local url = SERVER_URL .. DOWNLOAD_COMMAND .. "?filename=" .. textutils.urlEncode(filename)
        local response = http.get(url)
        if not response then
            logger.logMessage("Error: Failed to download " .. filename)
            progressBar.render(bytesDownloaded / totalBytes, "Failed: " .. filename)
            sleep(1)
            return
        end

        local data = response.readAll()
        response.close()

        -- Create directories if necessary
        local dir = fs.getDir(filename)
        if not fs.exists(dir) then
            fs.makeDir(dir)
            logger.logMessage("Created directory: " .. dir)
        end

        -- Save the file
        local fileHandle = fs.open(filename, "w")
        if fileHandle then
            fileHandle.write(data)
            fileHandle.close()
        else
            logger.logMessage("Error: Failed to save file " .. filename)
        end

        -- Update cumulative progress
        bytesDownloaded = bytesDownloaded + fileSize
        local progress = bytesDownloaded / totalBytes
        progressBar.render(progress, "Updating: " .. filename)

        -- Simulate download time proportional to file size
        local sleepTime = fileSize / totalBytes * 6  -- Adjust for total duration
        sleep(sleepTime)
    end
    logger.logMessage("All files downloaded successfully.")
    progressBar.render(1.0, "All files updated.")
end

--------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------
function main()
    logger.clearLogFile()
    logger.logMessage("Sync started. Downloading files...\n")

    -- Fetch metadata and process files
    local files, totalBytes = fetchFileMetadata()
    if files and totalBytes then
        downloadAllFiles(files, totalBytes)
        logger.logMessage("All files updated successfully.\n")
    else
        logger.logMessage("Error: Failed to fetch file metadata.\n")
    end
end

-- Run the main function
main()