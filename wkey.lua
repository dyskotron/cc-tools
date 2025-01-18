local modem = peripheral.find("modem") -- Automatically find an attached modem
if not modem then
    error("No modem found!")
end

local configFile = "key_config.txt" -- File to store the assigned key
modem.open(1) -- Open channel 1

-- Function to load the key name from the config file
local function loadKeyName()
    if fs.exists(configFile) then
        local file = fs.open(configFile, "r")
        local keyName = file.readAll()
        file.close()
        return keyName
    else
        return nil -- No key name assigned
    end
end

-- Function to save the key name to the config file
local function saveKeyName(keyName)
    local file = fs.open(configFile, "w")
    file.write(keyName)
    file.close()
end

-- Setup mode to assign the key name
local function setupKey()
    print("Press the key you want to assign for this input device...")
    local event, key = os.pullEvent("key") -- Wait for a key press event
    for name, code in pairs(keys) do
        if code == key then
            saveKeyName(name) -- Save the key name
            print("Key name saved as:", name)
            return
        end
    end
    print("Key not recognized. Try again.")
end

-- Function to check all redstone sides
local function isRedstoneActive()
    local sides = { "top", "bottom", "left", "right", "front", "back" }
    for _, side in ipairs(sides) do
        if redstone.getInput(side) then
            return true
        end
    end
    return false
end

-- Main loop
local function mainLoop()
    local keyName = loadKeyName()
    if not keyName then
        print("No key name assigned. Run 'wkey s' to configure.")
        return
    end

    print("Listening for redstone activity...")
    print("Assigned key name:", keyName)

    local lastState = false -- Tracks the last redstone state

    while true do
        local currentState = isRedstoneActive()

        if currentState and not lastState then
            -- Key down event (transition from inactive to active)
            modem.transmit(1, 1, { type = "keydown", key = keyName })
            print("Sent key down:", keyName)
        elseif not currentState and lastState then
            -- Key up event (transition from active to inactive)
            modem.transmit(1, 1, { type = "keyup", key = keyName })
            print("Sent key up:", keyName)
        end

        lastState = currentState
        sleep(0.05) -- Short delay for responsiveness
    end
end

-- Handle arguments for setup or running
local args = { ... }
if args[1] == "s" then
    setupKey()
end

mainLoop()