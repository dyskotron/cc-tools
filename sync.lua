local progressBar = require("Modules.ui.progressBar")
local logger = require("Modules.utils.logger")
local tableUtils = require("Modules.utils.tableUtils")

--------------------------------------------------------------------------
-- DOWNLOAD LOGIC
--------------------------------------------------------------------------

-- Server Configuration
local SERVER_URL = "https://publish-fragrant-cloud-3528.fly.dev"
local FILES_COMMAND = "/files"
local DOWNLOAD_COMMAND = "/download"

-- Function to calculate MD5 of a local file
local function calculate_md5(filename)
    local file = fs.open(filename, "rb")
    if not file then return nil end

    local content = file.readAll()
    file.close()

    -- Compute a simple hash using ASCII sum & modulo
    local hash = 0
    for i = 1, #content do
        hash = (hash + string.byte(content, i) * i) % 1000000007  -- Unique checksum
    end

    return tostring(hash)  -- Convert to string for safe comparison
end

-- Fetch file metadata with MD5 hashes
local function fetchFileMetadata()
    logger.info("Fetching file metadata from server...")

    local response = http.get(SERVER_URL .. FILES_COMMAND)
    if not response then
        logger.info("Error: Unable to fetch file list from server.")
        return nil
    end

    local raw_data = response.readAll()
    response.close()

    logger.info("Raw server response:\n" .. raw_data)

    local files = {}

    for line in raw_data:gmatch("[^\n]+") do
        local filename, hash = line:match("([^|]+)|([a-f0-9]+)")
        if filename and hash then
            files[filename] = hash
        else
            logger.info("Warning: Could not parse line: " .. line)
        end
    end

    if next(files) == nil then
        logger.info("No valid files found.")
        return nil
    end

    logger.info("File metadata fetched successfully.")
    return files
end

-- Download a single file
local function downloadFile(filename)

    logger.info("Downloading: " .. filename)

    local url = SERVER_URL .. DOWNLOAD_COMMAND .. "?filename=" .. textutils.urlEncode(filename)
    local response = http.get(url)
    if not response then
        logger.info("Failed to fetch file from server: " .. filename)
        progressBar.render(1.0, "Failed: " .. filename)
        sleep(1)
        return
    end

    local data = response.readAll()
    response.close()

    -- Ensure the directory exists
    local dir = fs.getDir(filename)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end

    -- Save the file
    local fileHandle = fs.open(filename, "wb")
    if fileHandle then
        fileHandle.write(data)
        fileHandle.close()
        logger.info("Downloaded: " .. filename)
    else
        logger.info("Error: Failed to save file " .. filename)
    end
end

-- Download all files that have changed
local function downloadAllFiles(server_files)
    if not server_files or next(server_files) == nil then
        logger.info("No files to download.")
        progressBar.render(1.0, "No files to update.")
        sleep(1)
        return
    end

    local progressCount = 0
    local totalFiles = tableUtils.tableLength(server_files)

    for filename, server_md5 in pairs(server_files) do
        local local_md5 = calculate_md5(filename)

        if local_md5 == server_md5 then
            logger.info("Skipping " .. filename .. ", already up-to-date")
        else
            downloadFile(filename)
            local progress = progressCount / totalFiles
            progressBar.render(progress, "Downloading: " .. filename)
            progressCount = progressCount + 1;
        end
    end

    logger.info("All files downloaded successfully.")
    progressBar.render(1.0, "All files updated.")
end

--------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------
local function main()
    logger.init(false, true, true, "sync.log")
    logger.info("Sync started. Downloading files...\n")

    -- Fetch metadata and process files
    local server_files = fetchFileMetadata()
    if server_files then
        downloadAllFiles(server_files)
        logger.info("All files updated successfully.\n")
    else
        logger.info("Error: Failed to fetch file metadata.\n")
    end
end

-- Run the main function
main()