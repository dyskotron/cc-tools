local terminalHelper = {}

function terminalHelper.pressAnyKeyToContinue()
    print("Press any key to continue...")
    os.pullEvent("key") -- Waits for any key press
end

return terminalHelper