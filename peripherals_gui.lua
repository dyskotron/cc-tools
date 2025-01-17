local menu = require("Modules.ui.menulib")

local function logError(message)
    local logFile = fs.open("error_log.txt", "a") -- Open the file in append mode
    if logFile then
        logFile.writeLine(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. tostring(message))
        logFile.close()
    else
        print("Failed to open log file!")
    end
end

local function logInfo(message)
    local file = fs.open("debug_log.txt", "a")
    file.writeLine(os.date() .. " - " .. message)
    file.close()
    print(message)  -- Also print it to the terminal for real-time feedback
end

--==================================================================================================================================

local peripheralGui = {}

-- Get a list of all connected peripherals
function peripheralGui.getDevices()
    return peripheral.getNames()
end

-- Get the methods of a specific peripheral
function peripheralGui.getMethods(deviceName)
    if peripheral.isPresent(deviceName) then
        return peripheral.getMethods(deviceName)
    else
        return nil
    end
end

-- Call a method on a peripheral
function peripheralGui.callMethod(deviceName, methodName, ...)
    if peripheral.isPresent(deviceName) then
        -- Capture the arguments into a table
        local args = { ... }

        local ok, result = pcall(function()
            return peripheral.call(deviceName, methodName, table.unpack(args))
        end)

        if ok then
            return true, result
        else
            return false, result
        end
    else
        return false, "Device not present"
    end
end

local function getInputAsInt(prompt)
    -- Display prompt
    write(prompt)
    
    -- Get user input as a string
    local input = read()
    
    -- Try to convert the input to an integer
    local number = tonumber(input)
    
    -- Check if the conversion succeeded
    if number then
        return number
    else
        print("Invalid input, please enter a valid number.")
        return getInputAsInt(prompt)  -- Recursive call to ask again
    end
end

-- handle all inventory methods
local function handleCustomMethod(deviceName, methodName, params)
    
    local device = peripheral.wrap(deviceName)
    
    -- Define custom handlers for specific methods here
    if methodName == "list" then
        
        local device = peripheral.wrap(deviceName)
        local content = device.list()
        
        local itemsPrompt = "Inventory is empty"
        if not (#content == 0) then
            itemsPrompt = menu.tableToString(content)
        end
        
        return {
            prompt = itemsPrompt,
            options = {},
            callbacks = {}  -- Use dynamically created callbacks
        }
    elseif methodName == "getItemDetail" then
        local slot = getInputAsInt("Enter Slot Number:")
        local itemDetail = device.getItemDetail(slot)
        
        local itemsPrompt = "No Item in slot " .. slot
        if not (itemDetail == nil) then
            itemsPrompt = menu.tableToString(itemDetail)
        end
        
        return {
            prompt = itemsPrompt,
            options = {},
            callbacks = {}  -- Use dynamically created callbacks
        }
    elseif methodName == "push" or methodName == "pull" then
        -- Generic handler for "push" and "pull" methods
        return "Please provide parameters (e.g., slot number, item count, etc.)"
    end

    -- If no custom handler, return nil (use the generic handler)
    return nil
end

-- Dynamically generate the screens
local function getScreen(index, data)
    logInfo("getScreen - index:" .. tostring(index) .. "data:" .. tostring(data))
    
    if index == 1 then
        
            logError("Unhandled error: " .. tostring(err))
            -- Main screen: List all devices
            local devices = peripheralGui.getDevices()
            local options = {}
            local callbacks = {}
    
            -- Create options and callbacks dynamically based on the devices
            for i, device in ipairs(devices) do
                -- Get the device type using peripheral.getType
                local deviceType = peripheral.getType(device)
                local deviceName = peripheral.getName(peripheral.wrap(device))
                -- Combine device name and type into one string
                local deviceDescription = deviceName .. " (" .. deviceType .. ")"
                table.insert(options, deviceDescription)  -- Add device with type to the options list
                callbacks[i] = function()      -- Create a callback for each device
                    return getScreen(2, { deviceName = device })
                end
            end
    
            return {
                prompt = "Select a Device:",
                options = options,
                callbacks = callbacks  -- Use dynamically created callbacks
            }
--========================================================================

    elseif index == 2 then
        -- Device methods screen
        local deviceName = data.deviceName
        local methods = peripheralGui.getMethods(deviceName)
        
        if not methods or #methods == 0 then
            return {
                prompt = "No methods found for " .. deviceName,
                options = {},  -- Back is handled automatically by the menu system
                callbacks = {}  -- No need to define callbacks for the "Back" option
            }
        end
    
        local options = {}
        local callbacks = {}
        
        -- Dynamically generate options and callbacks for each method
            for i, method in ipairs(methods) do
                table.insert(options, method)
                callbacks[i] = function()
                    -- Check for custom method handling
                    local customResponse = handleCustomMethod(deviceName, method)
                    if customResponse then
                        -- Display the custom response if a custom handler exists
                        return customResponse;
                    else
                        -- Proceed to the standard parameter input screen for generic methods
                        return getScreen(3, { deviceName = deviceName, methodName = method })
                    end
                end
            end
    
        return {
            prompt = "Methods for " .. deviceName .. ":",
            options = options,
            callbacks = callbacks  -- Use dynamically created callbacks
        }
--========================================================================

    elseif index == 3 then
        -- Parameter input and execution screen
        local deviceName = data.deviceName
        local methodName = data.methodName
        logInfo("getScreen - Parameter input and execution screen - deviceName:" .. tostring(deviceName) .. "methodName:" .. tostring(methodName))

        return {
            prompt = "Execute " .. methodName .. " on " .. deviceName .. ":\nProvide parameters (comma-separated):",
            options = { "Execute"},
            callbacks = {
                [1] = function()
                    term.setCursorPos(1, 3)
                    term.clearLine()
                    write("Enter parameters: ")
                    local input = read()
                    local params = {}
                    for param in string.gmatch(input, "([^,]+)") do
                        table.insert(params, param)
                    end

                    local success, result = peripheralGui.callMethod(deviceName, methodName, table.unpack(params))
                    return {
                        prompt = success and "Success:\n" .. tostring(result) or "Error:\n" .. tostring(result),
                        options = { },
                        callbacks = {
                            [1] = function() return getScreen(2, { deviceName = deviceName }) end
                        }
                    }
                end
            }
        }
    end
end

-- Main run function
function peripheralGui.run()
    menu.init(getScreen(1))
end

peripheralGui.run()