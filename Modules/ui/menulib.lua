local menu = {}

function menu.writeFromBottom(message, bottomOffset, xOffset)

    bottomOffset = bottomOffset or 0
    xOffset = xOffset or 1
    -- Get the screen height
    local _, screenHeight = term.getSize()

    -- Set cursor position to the bottom line
    term.setCursorPos(xOffset, screenHeight - bottomOffset)

    -- Print the message on the bottom line
    write(message)
end

function menu.createScrollableText(width, height)
    local lines = {}
    local offset = 1

    local function addLine(line)
        -- Adds a new line to the content
        table.insert(lines, line)
    end

    local function printContent()
        -- Clears the screen and prints the content based on the offset
        term.clear()
        term.setCursorPos(1, 1)

        -- Print a portion of the content based on offset
        for i = offset, math.min(offset + height - 1, #lines) do
            print(lines[i])
        end
    end

    local function changeOffset(direction)
        if direction == "up" and offset > 1 then
            offset = offset - 1
        elseif direction == "down" and offset + height - 1 <= #lines then
            offset = offset + 1
        end
    end

    return {
        addLine = addLine,
        printContent = printContent,
        changeOffset = changeOffset,
        getOffset = function() return offset end,
        getTotalLines = function() return #lines end
    }
end

function shallowCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = v
    end
    return copy
end

function menu.UpdateSelectionColours(selected)
    if selected then
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.white)
    else
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
    end
end

function menu.GetCursorString(selected)
    if selected then
        return ">"
    else
        return " "
    end
end


-- Helper function to clear the screen and print the title and options
function menu.ShowScreen(prompt, options, selection)
    term.clear()
    term.setCursorPos(1, 1)

    -- Print the prompt
    print(prompt)

    menu.UpdateSelectionColours(false)

    -- Print the options
    for i, option in ipairs(options) do
        menu.UpdateSelectionColours(i == selection)
        print(menu.GetCursorString(i == selection) .. " " .. option)
    end

    menu.UpdateSelectionColours(false)

    local upArrow = "↑"
    local downArrow = "↓"

    local screenWidth, screenHeight = term.getSize()

    menu.writeFromBottom("[B]Back", 0, 1)
    local navString = "[↑]+[↓]+Enter"
    menu.writeFromBottom(navString, 0, (screenWidth - #navString)/2)
    local exitString = "[X]Exit"
    menu.writeFromBottom(exitString, 0, screenWidth - #exitString)
end

-- Function to handle user input (arrow keys, enter, etc.)
function menu.HandleUserInput(prompt, options, showBackButton, showExitButton)
    local selection = 1
    local totalOptions = #options

    while true do
        menu.ShowScreen(prompt, options, selection)
        local event, key = os.pullEvent("key")

        if key == keys.up then
            if selection > 1 then
                selection = selection - 1
            end
        elseif key == keys.down then
            if selection < totalOptions then
                selection = selection + 1
            end
        elseif key == keys.x then
            return -1
        elseif key == keys.b then
            return 0
        elseif key == keys.enter then
            return selection
        end
    end
end

function menu.init(initialScreen)
    local screenStack = {}
    table.insert(screenStack, initialScreen)

    while #screenStack > 0 do
        local currentScreen = screenStack[#screenStack]

        if not currentScreen then
            term.clear()
            print("Error: No current screen!")
            break
        end

        local selection = menu.HandleUserInput(currentScreen.prompt, currentScreen.options, #screenStack > 1, true)

        if selection == 0 then
            -- "Back" option
            table.remove(screenStack)
        elseif selection == -1 then
            -- "Exit" option
            term.clear()
            print("Exiting program...")
            break
        else
            -- Execute callback and push new screen to the stack if valid
            local nextScreen = currentScreen.callbacks[selection]()
            if type(nextScreen) == "table" then
                table.insert(screenStack, nextScreen)
            end
        end
    end
end

function menu.printScrollableText(callback)

    local scrollableText = createScrollableText(20, 13)  -- 20 width, 5 height

    -- Adding initial content dynamically (like print())
    scrollableText.addLine("This is line 1")
    scrollableText.addLine("This is line 2")
    scrollableText.addLine("This is line 3")
    scrollableText.addLine("This is line 4")
    scrollableText.addLine("This is line 5")
    scrollableText.addLine("This is line 6")
    scrollableText.addLine("This is line 7")
    scrollableText.addLine("This is line 8")

    -- Show the initial content
    scrollableText.printContent()

    -- Handle user input for scrolling
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.up then
            scrollableText.changeOffset("up")
        elseif key == keys.down then
            scrollableText.changeOffset("down")
        elseif key == keys.enter then
            return callback()
        elseif key == keys.space then
            -- Add more content dynamically, like pressing print() multiple times
            local newContent = "New line at " .. os.time()
            scrollableText.addLine(newContent)
        end

        -- Update the screen with the new portion of content
        scrollableText.printContent()
    end
end

return menu
