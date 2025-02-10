local progressBar = require("Modules.ui.progressBar")
local logger = require("Modules.utils.logger")
local tableUtils = require("Modules.utils.tableUtils")

--------------------------------------------------------------------------
-- DOWNLOAD LOGIC
--------------------------------------------------------------------------

--TODO: add hash store to easySync, create proper-er ui/progress bar here, and make it barebones in easysync
--TODO: Add removing files from server to downloading client

-- Server Configuration
local SERVER_URL = "https://publish-fragrant-cloud-3528.fly.dev"
local FILES_COMMAND = "/files"
local DOWNLOAD_COMMAND = "/download"

local metadataFile = ".sync_metadata"

-- Load stored metadata (previously downloaded file hashes)
local function loadMetadata()
    if not fs.exists(metadataFile) then return {} end
    local file = fs.open(metadataFile, "r")
    local data = textutils.unserialize(file.readAll())
    file.close()
    return data or {}
end

-- Save updated metadata
local function saveMetadata(metadata)
    local file = fs.open(metadataFile, "w")
    file.write(textutils.serialize(metadata))
    file.close()
end

-- Function to calculate MD5 of a local file
local function calculate_md5(filename)
    if not fs.exists(filename) then
        return nil  -- Return nil if file doesn't exist
    end

    local file = fs.open(filename, "rb")
    if not file then return nil end

    local content = file.readAll()
    file.close()

    -- Generate a simple checksum-based hash
    local hash = 0
    for i = 1, #content do
        hash = (hash + (string.byte(content, i) * i)) % 1000000007
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
        return
    end

    local metadata = loadMetadata()  -- Load stored hashes
    local totalFiles = 0
    for _ in pairs(server_files) do totalFiles = totalFiles + 1 end

    local updatedCount = 0
    local count = 0
    for filename, server_md5 in pairs(server_files) do

        local stored_md5 = metadata[filename] or "nil"
        local progress = count / totalFiles

        if stored_md5 == server_md5 then
            logger.info("Skipping " .. filename .. ", already up-to-date")
        else
            progressBar.render(progress, "Downloading: " .. filename)
            downloadFile(filename)
            updatedCount = updatedCount + 1
            metadata[filename] = server_md5  -- ✅ Update hash after downloading
        end

        count = count + 1
    end

    saveMetadata(metadata)  -- ✅ Save metadata only once after all downloads
    if updatedCount == 0 then
        progressBar.render(1.0, "All files already up to date.")
    else
        local fileStr = "files."
        if(updatedCount == 1) then fileStr = "file." end
        progressBar.render(1.0, "Sucesfully updated " .. updatedCount .. " " .. fileStr)
    end
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
    else
        logger.info("Error: Failed to fetch file metadata.\n")
    end
end

-- Run the main function
main()