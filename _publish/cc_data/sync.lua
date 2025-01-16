local base64 = require("Modules.base64")

-- Configuration
local SERVER_URL = "http://localhost:8000/"  -- Change to the correct IP if needed
local DOWNLOAD_PATH = "/download"           -- Path for downloading files
local UPLOAD_PATH = "/upload"               -- Path for uploading files
local LOG_FILE = "sync_log.log"             -- Log file for syncing attempts

-- Function to log messages to the log file
function logMessage(message)
    -- Open the log file in append mode to avoid clearing the contents
    local logFile = fs.open(LOG_FILE, "a")
    if logFile then
        logFile.write(message .. "\n")  -- Add newline for better formatting
        logFile.close()
    else
        print("Error: Unable to open log file.")
    end

    print(message)
end

-- Function to explicitly clear the contents of the log file
function clearLogFile()
    local logFile = fs.open(LOG_FILE, "w")  -- Open in write mode to clear the file
    if logFile then
        logFile.close()  -- Just close the file to clear its contents
    else
        logMessage("Error: Unable to open log file.")
    end
end

-- URL Encoding in Lua
function urlEncode(str)
    return (str:gsub("[^%w_%-%.~]", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

-- URL Decoding in Lua
function urlDecode(str)
    return (str:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

function table.contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Function to URL encode data
function urlEncode(str)
    return str:gsub("([^%w %-%_%.%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "+")
end

-- Function to upload a file to the server (with manual Base64 encoding and URL encoding)
function uploadFile(filename)
    logMessage("Preparing to upload file: " .. filename)

    local file = fs.open(filename, "r")
    if not file then
        logMessage("Error: Could not open file " .. filename)
        return
    end

    local content = file.readAll()

    -- Log the file size
        logMessage("File size: " .. #content .. " bytes")

    -- Check for non-ASCII characters
    for i = 1, #content do
        local byte = string.byte(content, i)
        if byte > 127 then
            print("Non-ASCII character found: ", byte)
        end
    end

    file.close()

    -- Base64 encode the file content manually
    local encodedContent = base64.encode(content)
    local encodedContent = urlEncode(encodedContent)

    --logMessage("content: " .. content)
    --logMessage("Base64-encoded content: " .. encodedContent)

    -- URL encode the filename but NOT the content
    local encodedFilename = urlEncode(filename)

    -- Prepare the POST data (only base64-encoded content, not URL encoded)
    local data = "filename=" .. encodedFilename .. "&data=" .. encodedContent

    -- Log the POST data for debugging
    logMessage("POST data: " .. data)

    -- Create a POST request and send the file to the server
    local url = SERVER_URL .. "upload"  -- Replace with the correct server IP
    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["Content-Length"] = tostring(#data)
    }

    logMessage("Sending POST request...")
    local response, statusCode = http.post(url, data, headers)
    if response then
        logMessage("Response Code: " .. tostring(statusCode))    -- Log response code
        logMessage("File uploaded successfully: " .. filename)
    else
        logMessage("Error: Failed to upload " .. filename)
        logMessage("Status Code: " .. (tostring(statusCode) or "Unknown"))
    end
end

-- Function to upload all .lua files (excluding the "rom" folder)
function uploadAllFiles()
    local files = fs.list("/")  -- List the files in the root directory

    if not files then
        local errorMsg = "Error: Unable to list files in the root directory"
        logMessage(errorMsg)
        return
    end

    local uploadedFiles = {}

    for _, filename in ipairs(files) do
        -- Skip the "rom" folder and only upload .lua files
        if filename ~= "rom" then
            if string.match(filename, "%.lua$") then
                uploadFile(filename)
                table.insert(uploadedFiles, filename)
            elseif fs.isDir(filename) then
                -- Recursively upload files in subdirectories (skip "rom" folder)
                uploadAllFilesInDirectory(filename, uploadedFiles)
            end
        end
    end

    return uploadedFiles
end

-- Function to scan subdirectories and upload .lua files (excluding "rom")
function uploadAllFilesInDirectory(directory, uploadedFiles)
    local files = fs.list(directory)

    if not files then
        local errorMsg = "Error: Unable to list files in directory: " .. directory
        logMessage(errorMsg)
        return
    end

    for _, filename in ipairs(files) do
        -- Skip the "rom" folder and only upload .lua files
        if filename ~= "rom" then
            if string.match(filename, "%.lua$") then
                uploadFile(directory .. "/" .. filename)
                table.insert(uploadedFiles, directory .. "/" .. filename)
            elseif fs.isDir(directory .. "/" .. filename) then
                -- Recursively scan subdirectories
                uploadAllFilesInDirectory(directory .. "/" .. filename, uploadedFiles)
            end
        end
    end
end

-- Function to download a file
function downloadFile(filename)
    local url = SERVER_URL .. DOWNLOAD_PATH .. "?filename=" .. filename
    local response = http.get(url)
    if response then
        local data = response.readAll()
        response.close()

        -- Extract the directory from the filename
        local dir = fs.getDir(filename)
        logMessage("target directory: " ..  dir)
        if not fs.exists(dir) then
            -- Create the directory if it doesn't exist
            fs.makeDir(dir)
            logMessage("creating directory: " ..  dir)
        end

        -- Open the file for writing
        local file = fs.open(filename, "w")
        if file then
            file.write(data)
            file.close()
            logMessage("Downloaded: " .. filename)
        else
            logMessage("Failed to write " .. filename)
        end
    else
        logMessage("Failed to download " .. filename)
    end
end

-- Function to download all files
function downloadAllFiles(uploadedFiles)
    for _, filename in ipairs(uploadedFiles) do
        downloadFile(filename)
    end
end

function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function main()

    clearLogFile()

    -- Accessing arguments
    local args = {}
    if #arg > 0 then
        for i, v in ipairs(arg) do
            table.insert(args, v)
        end
    end

    if args[1] == "up" then
        -- Upload files
        logMessage("Sync started. Uploading files...\n")
        local uploadedFiles = uploadAllFiles()

        if #uploadedFiles > 0 then
            logMessage("Sync completed. Files uploaded.\n")
        else
            logMessage("Error: No files uploaded.\n")
        end
    else
        -- Download files
        logMessage("Sync started. Downloading files...\n")

        -- Get list of files to download (from the server)
        local url = SERVER_URL .. "/files"
        local response = http.get(url)

        if response then
            local raw_data = response.readAll()  -- Get the raw response data
            response.close()

            -- Log the raw response for debugging
            logMessage("Server response: " .. raw_data .. "\n")

            -- Parse the comma-separated list of files
            local files = {}
            for filename in raw_data:gmatch("([^,]+)") do
                filename = trim(filename)  -- Remove leading/trailing spaces
                table.insert(files, filename)
            end

            -- Check if 'files' is valid
            if files then
                for _, filename in ipairs(files) do
                    logMessage("Downloading " .. filename .. "...\n")

                    -- Download each file
                    local download_url = SERVER_URL .. "/download/" .. filename
                    local file_response = http.get(download_url)

                    if file_response then
                        local data = file_response.readAll()
                        file_response.close()

                        -- Save the file locally
                        local file = fs.open(filename, "w")
                        if file then
                            file.write(data)
                            file.close()
                            logMessage("File " .. filename .. " downloaded successfully.\n")
                        else
                            logMessage("Failed to write " .. filename .. ".\n")
                        end
                    else
                        logMessage("Error: Unable to download " .. filename .. ".\n")
                    end
                end
            else
                logMessage("Error: Invalid file list received from server.\n")
            end
        else
            logMessage("Error: Unable to fetch the file list from the server.\n")
        end
    end
end

-- Run the main function
main()