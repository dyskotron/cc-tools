local base64 = require("Modules.base64")
local progressBar = require("Modules.ui.progressBar")
local stringUtils = require("Modules.stringUtils")
local logger = require("Modules.ui.logger")

-- Configuration
local SERVER_URL = "http://localhost:8000/"  -- Change to the correct IP if needed
local UPLOAD_COMMAND =  "/upload"               -- url for uploading files
local DOWNLOAD_COMMAND =  "/download"           -- url for downloading files
local FILES_COMMAND =  "/files"               -- url for uploading files

function table.contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------
-- UPLOAD LOGIC
--------------------------------------------------------------------------
function uploadFile(filename)
    logger.logMessage("Preparing to upload file: " .. filename)

    local file = fs.open(filename, "r")
    if not file then
        logger.logMessage("Error: Could not open file " .. filename)
        return
    end

    local content = file.readAll()
    file.close()

    logger.logMessage("File size: " .. #content .. " bytes")

    local encodedContent = base64.encode(content)
    encodedContent = stringUtils.urlEncode(encodedContent)

    local encodedFilename = stringUtils.urlEncode(filename)
    local data = "filename=" .. encodedFilename .. "&data=" .. encodedContent

    logger.logMessage("POST data: " .. data)

    local url = SERVER_URL .. UPLOAD_COMMAND
    local headers = {
        ["Content-Type"] = "application/x-www-form-stringUtils.urlEncoded",
        ["Content-Length"] = tostring(#data)
    }

    logger.logMessage("Sending POST request...")
    local response, statusCode = http.post(url, data, headers)
    if response then
        logger.logMessage("Response Code: " .. tostring(statusCode))
        logger.logMessage("File uploaded successfully: " .. filename)
    else
        logger.logMessage("Error: Failed to upload " .. filename)
        logger.logMessage("Status Code: " .. (tostring(statusCode) or "Unknown"))
    end
end

function uploadAllFiles()
    local files = fs.list("/")
    if not files then
        local errorMsg = "Error: Unable to list files in the root directory"
        logger.logMessage(errorMsg)
        return {}
    end

    local uploadedFiles = {}

    for _, filename in ipairs(files) do
        if filename ~= "rom" then
            if string.match(filename, "%.lua$") then
                uploadFile(filename)
                table.insert(uploadedFiles, filename)
            elseif fs.isDir(filename) then
                uploadAllFilesInDirectory(filename, uploadedFiles)
            end
        end
    end

    return uploadedFiles
end

function uploadAllFilesInDirectory(directory, uploadedFiles)
    local files = fs.list(directory)
    if not files then
        local errorMsg = "Error: Unable to list files in directory: " .. directory
        logger.logMessage(errorMsg)
        return
    end

    for _, filename in ipairs(files) do
        if filename ~= "rom" then
            if string.match(filename, "%.lua$") then
                uploadFile(directory .. "/" .. filename)
                table.insert(uploadedFiles, directory .. "/" .. filename)
            elseif fs.isDir(directory .. "/" .. filename) then
                uploadAllFilesInDirectory(directory .. "/" .. filename, uploadedFiles)
            end
        end
    end
end

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

    -- Log raw server response for debugging
    logger.logMessage("Raw server response:\n" .. raw_data)


    local files = {}
    local totalBytes = 0

    for line in raw_data:gmatch("[^\n]+") do
        -- Log each line being processed
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

    -- Log the final parsed files for debugging
    logger.logMessage("Parsed files: " .. textutils.serialize(files))
    return files, totalBytes
end


function downloadFile(filename)
    logger.logMessage("Starting download for: " .. filename)

    local url = SERVER_URL .. DOWNLOAD_COMMAND .. "?filename=" .. filename
    local response = http.get(url)
    if not response then
        logger.logMessage("Failed to fetch file from server: " .. filename)
        progressBar.render(1.0, "Failed: " .. filename)
        sleep(1) -- Brief pause to show failure
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


-- Function to download all files
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
            logger.logMessage("Downloading: ERR filname is nil???    the file:" .. file)
        else
            logger.logMessage("Downloading: " .. filename)
        end


        local url = SERVER_URL .. DOWNLOAD_COMMAND .. "?filename=" .. filename
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
    sleep(2) -- Pause to show final progress
end

--------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------
function main()

    logger.clearLogFile()

    local args = {}
    if #arg > 0 then
        for i, v in ipairs(arg) do
            table.insert(args, v)
        end
    end

    if args[1] == "up" then
        -- Upload files
        logger.logMessage("Sync started. Uploading files...\n")
        local uploadedFiles = uploadAllFiles()
        if #uploadedFiles > 0 then
            logger.logMessage("Sync completed. Files uploaded.\n")
        else
            logger.logMessage("Error: No files uploaded.\n")
        end

    else
        -- Download and update files
        logger.logMessage("Sync started. Updating files...\n")

        -- Fetch metadata and process files
        local files, totalBytes = fetchFileMetadata()
        if files and totalBytes then
            -- Download and update files
            downloadAllFiles(files, totalBytes)
            logger.logMessage("All files updated successfully.\n")
        else
            logger.logMessage("Error: Failed to fetch file metadata.\n")
        end
    end
end

-- Run the main function
main()