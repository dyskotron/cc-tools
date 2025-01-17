View = require("Modules.ui.view")
ListView = require("Modules.ui.listView")
tableUtils = require("Modules.utils.tableUtils")
logger = require("Modules.utils.logger")
dirUtils = require("Modules.utils.dirUtils")

-- Initialize the two lists
local w, h = term.getSize()
term.clear()

local leftList = ListView:Init(1, 1, w / 2, h, " ")
local rightList = ListView:Init(w / 2 + 1, 1, w / 2, h, " ")

local leftDirectory = "/"
local rightDirectory = "/"

-- Start with the left list as active
local activeList = leftList
local inactiveList = rightList
local activeDirectory = leftDirectory
local lastSelection = { left = 1, right = 1 } -- Store last selected index for each list

local function runLuaFile(filepath)
    local success, err = pcall(function()
        shell.run(filepath) -- Run the .lua file
    end)
    if not success then
        print("Error running file: " .. err)
        os.pullEvent("key") -- Wait for a key press to return to the file manager
    end
end

local function main()

    leftList:setData(dirUtils.listDirectoryContents(leftDirectory))
    rightList:setData(dirUtils.listDirectoryContents(rightDirectory))
    activeList:select(1) -- Ensure the active list starts with a selection

    -- Main loop to listen for key presses
    while true do
        local event, key = os.pullEvent("key") -- Wait for a key event

        if key == keys.tab then
            -- Store the last selected index for the current active list
            if activeList == leftList then
                lastSelection.left = activeList.selectedIndex or 1
            else
                lastSelection.right = activeList.selectedIndex or 1
            end

            -- Toggle active list
            if activeList == leftList then
                activeList = rightList
                inactiveList = leftList
                activeDirectory = rightDirectory
                inactiveDirectory = leftDirectory
            else
                activeList = leftList
                inactiveList = rightList
                activeDirectory = leftDirectory
                inactiveDirectory = rightDirectory
            end

            -- Deselect all items in the inactive list
            inactiveList:select(nil)

            -- Restore the last selected index for the new active list
            local restoredSelection = (activeList == leftList) and lastSelection.left or lastSelection.right
            activeList:select(restoredSelection)
        elseif key == keys.up then
            activeList:selectRelative(-1) -- Move selection up in the active list
        elseif key == keys.down then
            activeList:selectRelative(1) -- Move selection down in the active list
        elseif key == keys.enter then
            local selectedItem = activeList.data[activeList.selectedIndex]
            if selectedItem == ".." then
                -- Navigate up one directory
                activeDirectory = fs.getDir(activeDirectory)
                logger.info("fs.getDir({}) returns |{}|)", activeDirectory, fs.getDir(activeDirectory))
                activeList:setData(dirUtils.listDirectoryContents(activeDirectory))
            else
                local fullPath = fs.combine(activeDirectory, selectedItem)
                if fs.isDir(fullPath) then
                    -- Navigate into the directory
                    activeDirectory = fullPath
                    activeList:setData(dirUtils.listDirectoryContents(activeDirectory))
                elseif selectedItem:match("%.lua$") and fs.exists(fullPath) then
                    -- Run the .lua file
                    runLuaFile(fullPath)
                end
            end

            -- Update directory references
            if activeList == leftList then
                leftDirectory = activeDirectory
            else
                rightDirectory = activeDirectory
            end
        elseif key == keys.q then
            break -- Exit the loop when "q" is pressed
        end
    end

    -- Reset terminal
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

logger.init(false, true, true)
logger.info("info test")
logger.warn("warn test")
logger.error("error test {error}", "heyy i am error test")
logger.runWithLog(main())