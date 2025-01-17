logger = require("Modules.utils.logger")
stringUtils = require("Modules.utils.stringUtils")

local dirUtils = {}

function dirUtils.listDirectoryContents(directory, showHidden)
    -- Default to hiding hidden files and folders
    showHidden = showHidden or false

    -- Ensure the directory is an absolute path
    directory = dirUtils.ensureAbsolutePath(directory)

    logger.info("dirUtils.listDirectoryContents() called for {}, showHidden = {}", directory, showHidden)

    local items = fs.list(directory)
    local folders, hiddenFolders, files, hiddenFiles = {}, {}, {}, {}

    -- Categorize items
    for _, item in ipairs(items) do
        local fullPath = fs.combine(directory, item)
        if fs.isDir(fullPath) then
            if item:sub(1, 1) == "." then
                table.insert(hiddenFolders, item) -- Add to hidden folders
            else
                table.insert(folders, item) -- Add to regular folders
            end
        else
            if item:sub(1, 1) == "." then
                table.insert(hiddenFiles, item) -- Add to hidden files
            else
                table.insert(files, item) -- Add to regular files
            end
        end
    end

    -- Sort each category alphabetically
    table.sort(folders)
    table.sort(hiddenFolders)
    table.sort(files)
    table.sort(hiddenFiles)

    -- Combine categories manually to ensure order
    local result = {}

    -- Add ".." only if not in the root directory
    if directory ~= "/" then
        table.insert(result, "..")
    end

    -- Add regular folders and files
    for _, folder in ipairs(folders) do
        table.insert(result, folder)
    end
    for _, file in ipairs(files) do
        table.insert(result, file)
    end

    -- Optionally add hidden folders and files
    if showHidden then
        for _, hiddenFolder in ipairs(hiddenFolders) do
            table.insert(result, hiddenFolder)
        end
        for _, hiddenFile in ipairs(hiddenFiles) do
            table.insert(result, hiddenFile)
        end
    end

    logger.info("Final folder content table (showHidden = {}): {}", showHidden, stringUtils.tableToString(result))
    return result
end

function dirUtils.ensureAbsolutePath(path)
    if path:sub(1, 1) ~= "/" then
        return "/" .. path
    end
    return path
end

return dirUtils