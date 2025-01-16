-- Logger module
local Logger = {}

local logFilePath
local writeToTerminal
local writeToFile
local fileHandle

-- Initialize the logger (detailed configuration)
function Logger.initWithParams(config)
    logFilePath = config.logFilePath or "log.txt" -- Default file path
    writeToTerminal = config.writeToTerminal ~= false -- Default to true
    writeToFile = config.writeToFile ~= false -- Default to true

    if writeToFile then
        -- Open the log file in the appropriate mode
        local mode = config.clearLog and "w" or "a"
        fileHandle = fs.open(logFilePath, mode)

        -- If appending, add a visual separator
        if mode == "a" then
            fileHandle.write("\n=== New Log Start ===\n")
            fileHandle.flush() -- Ensure the separator is written
        end
    end
end

-- Simplified initialization with optional parameters
function Logger.init(writeToTerminal, writeToFile, logFilePath)
    Logger.initWithParams({
        logFilePath = logFilePath or "log.txt", -- Default file name
        writeToTerminal = writeToTerminal ~= false, -- Default to true
        writeToFile = writeToFile ~= false, -- Default to true
        clearLog = true -- Always clear log with this method
    })
end

-- Log a message
function Logger.log(message)
    if writeToTerminal then
        print(message)
    end

    if writeToFile and fileHandle then
        fileHandle.write(message .. "\n")
        fileHandle.flush() -- Flush after every log write
    end
end

-- Close the log file (should be called on program exit if writing to a file)
function Logger.close()
    if fileHandle then
        fileHandle.close()
        fileHandle = nil
    end
end

return Logger