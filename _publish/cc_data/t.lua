local t = {}

-- Mapping commands to turtle API functions
local turtleCommands = {
    craft = turtle.craft,
    forward = turtle.forward,
    back = turtle.back,
    up = turtle.up,
    down = turtle.down,
    turnLeft = turtle.turnLeft,
    turnRight = turtle.turnRight,
    dig = turtle.dig,
    digUp = turtle.digUp,
    digDown = turtle.digDown,
    place = turtle.place,
    placeUp = turtle.placeUp,
    placeDown = turtle.placeDown,
    drop = turtle.drop,
    dropUp = turtle.dropUp,
    dropDown = turtle.dropDown,
    select = turtle.select,
    getItemCount = turtle.getItemCount,
    getItemSpace = turtle.getItemSpace,
    detect = turtle.detect,
    detectUp = turtle.detectUp,
    detectDown = turtle.detectDown,
    compare = turtle.compare,
    compareUp = turtle.compareUp,
    compareDown = turtle.compareDown,
    attack = turtle.attack,
    attackUp = turtle.attackUp,
    attackDown = turtle.attackDown,
    suck = turtle.suck,
    suckUp = turtle.suckUp,
    suckDown = turtle.suckDown,
    getFuelLevel = turtle.getFuelLevel,
    refuel = turtle.refuel,
    compareTo = turtle.compareTo,
    transferTo = turtle.transferTo,
    getSelectedSlot = turtle.getSelectedSlot,
    getFuelLimit = turtle.getFuelLimit,
    equipLeft = turtle.equipLeft,
    equipRight = turtle.equipRight,
    inspect = turtle.inspect,
    inspectUp = turtle.inspectUp,
    inspectDown = turtle.inspectDown,
    getItemDetail = turtle.getItemDetail,
}

-- Execute a command
function t.runCommand(args)
    if #args < 1 then
        print("Usage: t <command> [parameters]")
        return
    end

    local command = args[1]
    local func = turtleCommands[command]
    if not func then
        print("Unknown command: " .. command)
        return
    end

    -- Convert remaining arguments to numbers if possible
    local parameters = {}
    for i = 2, #args do
        local num = tonumber(args[i])
        table.insert(parameters, num or args[i])
    end

    -- Call the turtle function with unpacked parameters
    local success, result = pcall(func, table.unpack(parameters))
    if success then
        if result ~= nil then
            print("Result:", result)
        else
            print("Command executed successfully.")
        end
    else
        print("Error:", result)
    end
end

-- Main program entry point
local args = { ... }
t.runCommand(args)