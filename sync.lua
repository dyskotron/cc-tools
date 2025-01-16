--------------------------------------------------------------------------
-- BASE 64 ENCODER
--------------------------------------------------------------------------
local base64 = {}
local base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
local charAt, indexOf = {}, {}

local blshift = bit32 and bit32.lshift or bit.blshift
local brshift = bit32 and bit32.rshift or bit.brshift
local band = bit32 and bit32.band or bit.band
local bor = bit32 and bit32.bor or bit.bor

for i = 1, #base64chars do
	local char = base64chars:sub(i,i)
	charAt[i-1] = char
	indexOf[char] = i-1
end

function base64.encode(data)
	local data = type(data) == "table" and data or {tostring(data):byte(1,-1)}

	local out = {}
	local b
	for i = 1, #data, 3 do
		b = brshift(band(data[i], 0xFC), 2) -- 11111100
		out[#out+1] = charAt[b]
		b = blshift(band(data[i], 0x03), 4) -- 00000011
		if i+0 < #data then
			b = bor(b, brshift(band(data[i+1], 0xF0), 4)) -- 11110000
			out[#out+1] = charAt[b]
			b = blshift(band(data[i+1], 0x0F), 2) -- 00001111
			if i+1 < #data then
				b = bor(b, brshift(band(data[i+2], 0xC0), 6)) -- 11000000
				out[#out+1] = charAt[b]
				b = band(data[i+2], 0x3F) -- 00111111
				out[#out+1] = charAt[b]
			else out[#out+1] = charAt[b].."="
			end
		else out[#out+1] = charAt[b].."=="
		end
	end
	return table.concat(out)
end

function base64.decode(data)
--	if #data%4 ~= 0 then error("Invalid base64 data", 2) end

	local decoded = {}
	local inChars = {}
	for char in data:gmatch(".") do
		inChars[#inChars+1] = char
	end
	for i = 1, #inChars, 4 do
		local b = {indexOf[inChars[i]],indexOf[inChars[i+1]],indexOf[inChars[i+2]],indexOf[inChars[i+3]]}
		decoded[#decoded+1] = bor(blshift(b[1], 2), brshift(b[2], 4))%256
		if b[3] < 64 then decoded[#decoded+1] = bor(blshift(b[2], 4), brshift(b[3], 2))%256
			if b[4] < 64 then decoded[#decoded+1] = bor(blshift(b[3], 6), b[4])%256 end
		end
	end
	return decoded
end

--------------------------------------------------------------------------
-- PROGRESS BAR
--------------------------------------------------------------------------
local progressBar = {}

-- Renders a progress bar in the middle of the screen.
-- progress: 0..1 (0%..100%)
-- message: short string describing what's happening
function progressBar.render(progress, message)
    -- Always clear before drawing the "frame"
    term.clear()
    term.setCursorPos(1, 1)

    local w, h = term.getSize()

    -- Position message in the middle (slightly above the bar)
    local msgX = math.floor((w - #message) / 2) + 1
    local msgY = math.floor(h / 2) - 1
    term.setCursorPos(msgX, msgY)
    term.write(message)

    -- Build the progress bar
    local barWidth = 30
    local filled = math.floor(progress * barWidth)
    local bar = string.rep("=", filled) .. string.rep("-", barWidth - filled)

    -- Center the bar
    local barX = math.floor((w - (barWidth + 2)) / 2) + 1 -- brackets [ ]
    local barY = msgY + 1
    term.setCursorPos(barX, barY)
    term.write("[" .. bar .. "]")

    -- Show numeric percentage
    local percent = math.floor(progress * 100)
    term.write(" " .. percent .. "%")
end

--------------------------------------------------------------------------
-- MAIN SYNC CODE
--------------------------------------------------------------------------


-- Configuration
local SERVER_URL = "http://localhost:8000/"  -- Change to the correct IP if needed
local DOWNLOAD_PATH = "/download"           -- Path for downloading files
local UPLOAD_PATH = "/upload"               -- Path for uploading files
local LOG_FILE = "sync_log.log"             -- Log file for syncing attempts

-- Function to log messages to the log file
function logMessage(message)
    local logFile = fs.open(LOG_FILE, "a")
    if logFile then
        logFile.write(message .. "\n")
        logFile.close()
    else
        print("Error: Unable to open log file.")
    end

    --print(message)
end

-- Function to explicitly clear the contents of the log file
function clearLogFile()
    local logFile = fs.open(LOG_FILE, "w")
    if logFile then
        logFile.close()
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

-- Re-define urlEncode to handle spaces
function urlEncode(str)
    return str:gsub("([^%w %-%_%.%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "+")
end

--------------------------------------------------------------------------
-- UPLOAD LOGIC (unchanged)
--------------------------------------------------------------------------
function uploadFile(filename)
    logMessage("Preparing to upload file: " .. filename)

    local file = fs.open(filename, "r")
    if not file then
        logMessage("Error: Could not open file " .. filename)
        return
    end

    local content = file.readAll()
    file.close()

    logMessage("File size: " .. #content .. " bytes")

    local encodedContent = base64.encode(content)
    encodedContent = urlEncode(encodedContent)

    local encodedFilename = urlEncode(filename)
    local data = "filename=" .. encodedFilename .. "&data=" .. encodedContent

    logMessage("POST data: " .. data)

    local url = SERVER_URL .. "upload"
    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["Content-Length"] = tostring(#data)
    }

    logMessage("Sending POST request...")
    local response, statusCode = http.post(url, data, headers)
    if response then
        logMessage("Response Code: " .. tostring(statusCode))
        logMessage("File uploaded successfully: " .. filename)
    else
        logMessage("Error: Failed to upload " .. filename)
        logMessage("Status Code: " .. (tostring(statusCode) or "Unknown"))
    end
end

function uploadAllFiles()
    local files = fs.list("/")
    if not files then
        local errorMsg = "Error: Unable to list files in the root directory"
        logMessage(errorMsg)
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
        logMessage(errorMsg)
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
function downloadFile(filename)
    local url = SERVER_URL .. DOWNLOAD_PATH .. "?filename=" .. filename
    local response = http.get(url)
    if not response then
        logMessage("Failed to download " .. filename)
        return
    end

    local data = response.readAll()
    response.close()

    -- Create the directory if necessary
    local dir = fs.getDir(filename)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end

    -- Write in chunks, rendering progress bar for ~6 seconds
    local totalBytes = #data
    local chunkCount = 60
    local chunkSize = math.max(1, math.floor(totalBytes / chunkCount))

    local file = fs.open(filename, "w")
    if not file then
        logMessage("Failed to write " .. filename)
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

        sleep(0.1) -- Adjust timing for desired effect
    end
    file.close()

    -- Log download completion
    logMessage("Downloaded: " .. filename)
end

-- Function to download all files
function downloadAllFiles(uploadedFiles)
    for _, filename in ipairs(uploadedFiles) do
        downloadFile(filename)
    end
end

--------------------------------------------------------------------------
-- TRIM HELPER
--------------------------------------------------------------------------
function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------
function main()
    clearLogFile()

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
        -- Download and update files
        logMessage("Sync started. Updating files...\n")

        -- 1) Get comma-separated list of files from the server
        local listUrl = SERVER_URL .. "/files"
        local listResponse = http.get(listUrl)
        if listResponse then
            local raw_data = listResponse.readAll()
            listResponse.close()

            logMessage("Server response: " .. raw_data .. "\n")

            -- 2) Parse comma-separated list into a table
            local files = {}
            for filename in raw_data:gmatch("([^,]+)") do
                filename = trim(filename)
                table.insert(files, filename)
            end

            -- 3) Update each file with the latest version
            if files then
                downloadAllFiles(files)
                logMessage("All files updated successfully.\n")
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