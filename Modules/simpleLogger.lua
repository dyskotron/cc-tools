local LOG_FILE = "sync_log.log"             -- Log file for syncing attempts

local logger = {}

-- Function to log messages to the log file
function logger.logMessage(message)
    local logFile = fs.open(LOG_FILE, "a")
    if logFile then
        logFile.write(message .. "\n")
        logFile.close()
    else
        error("Error: Unable to open log file.")
    end

    --print(message)
end

-- Function to explicitly clear the contents of the log file
function logger.clearLogFile()
    --local logFile = fs.open(LOG_FILE, "w")
    --if logFile then
    --    logFile.close()
    --else
    --    error("Error: Unable to open log file.")
    --end
end

return logger