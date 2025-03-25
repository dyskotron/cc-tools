local textFileUtil = {}

function textFileUtil.writeToFile(filePath, content)
    fileHandle = fs.open(filePath, "w")

    if not fileHandle then
        error("Failed to open file: " .. filePath)
    end

    fileHandle.write(content)
    fileHandle.flush()
end

function textFileUtil.readFile(filePath)
    fileHandle = fs.open(filePath, "r")

    if not fileHandle then
        error("Failed to open log file: " .. filePath)
        return nil
    end

    return fileHandle.readAll()
end

return textFileUtil