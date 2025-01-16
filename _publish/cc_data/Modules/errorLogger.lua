local function logError(message)
    -- Open the log file in append mode
    local logFile = fs.open("error_log.txt", "a")
    if logFile then
        logFile.writeLine(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message)
        logFile.close()
    else
        print("Failed to open log file for writing.")
    end
end

local function runWithLogging(mainFunction, ...)
    local success, err = pcall(mainFunction, ...)
    if not success then
        logError(err)  -- Log the error to the file
        error(err, 0)  -- Re-throw the error to the terminal
    end
end

return{
    logError = logError,
    runWithLogging = runWithLogging;
}