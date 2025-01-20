local logger = {}

local logFilePath
local writeToTerminal
local writeToFile
local fileHandle

-- Get a timestamp for log entries
local function getTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

-- Helper for ordered interpolation
local function interpolateOrdered(str, ...)
    local values = { ... } -- Collect all variadic arguments into a table
    local index = 1
    return (str:gsub("{.-}", function()
        local value = values[index]
        index = index + 1
        return tostring(value or "") -- Replace with value or empty string if nil
    end))
end

-- Internal function to write a log entry with a level
local function writeLog(level, message, ...)
    -- Interpolate the message with the provided values
    local interpolatedMessage = interpolateOrdered(message, ...)
    local logEntry = string.format("[%s] [%s] %s", getTimestamp(), level, interpolatedMessage)

    if writeToTerminal then
        print(logEntry)
    end

    if writeToFile then
        if not fileHandle then
            error("File handle not initialized. Did you call logger.init?")
        end
        fileHandle.write(logEntry .. "\n")
        fileHandle.flush()
    end
end

-- Initialize the logger (detailed configuration)
function logger.initWithParams(config)
    logFilePath = config.logFilePath or "log.txt" -- Default file path
    writeToTerminal = config.writeToTerminal ~= false -- Default to true
    writeToFile = config.writeToFile ~= false -- Default to true

    if writeToFile then
        -- Open the log file in the appropriate mode
        local mode = config.clearLog and "w" or "a"
        fileHandle = fs.open(logFilePath, mode)

        if not fileHandle then
            error("Failed to open log file: " .. logFilePath)
        end

        -- If appending, add a visual separator
        if mode == "a" then
            fileHandle.write("\n=== New Log Start ===\n")
            fileHandle.flush() -- Ensure the separator is written
        end
    end
end

-- Simplified initialization with optional parameters
function logger.init(writeToTerminal, writeToFile, clearLog, logFilePath)
    logger.initWithParams({
        logFilePath = logFilePath or "log.txt", -- Default file name
        writeToTerminal = writeToTerminal, -- Use as is
        writeToFile = writeToFile, -- Use as is
        clearLog = clearLog ~= false -- Default to false
    })
end

-- Log methods
function logger.info(message, ...)
    writeLog("INFO", message, ...)
end

function logger.warn(message, ...)
    writeLog("WARN", message, ...)
end

function logger.error(message, ...)
    writeLog("ERROR", message, ...)
end

function logger.runWithLog(func)
    logger.info("Executing: function")
    local success, err = pcall(func)
    if not success then
        logger.error("Error while executing function: {}", err)
    else
        logger.info("Execution completed successfully.")
    end
end

function logger.runFileWithLogger(filepath)
    logger.runWithLog(function()
        shell.run(filepath)
    end)
end

-- Close the log file (should be called on program exit if writing to a file)
function logger.close()
    if fileHandle then
        fileHandle.close()
        fileHandle = nil
    end
end

return logger