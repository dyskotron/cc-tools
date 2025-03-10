vecUtil = require("Modules.utils.vectorUtils")

-- Mock definitions for IDE purposes (only for syntax highlighting)
if not turtle then
    turtle = {
        turnLeft = function() end,
        turnRight = function() end,
        forward = function() end,
        dig = function() end,
        digUp = function() end,
        digDown = function() end,
        place = function() end,
        placeUp = function() end,
        placeDown = function() end,
        detect = function() return false end,
        detectUp = function() return false end,
        detectDown = function() return false end,
    }
end

-- transform = { position = { x = 1, y = 1, z = 1 }, direction = 0 }

local traverseHelper = {}

function traverseHelper.normalizeDirection(dir)
    return (dir + 360) % 360
end

function traverseHelper.faceDirection(transform, targetDirection)

    local diff = traverseHelper.normalizeDirection(targetDirection - transform.rotation)
    if diff == 90 then
        turtle.turnRight()
    elseif diff == 180 then
        turtle.turnRight()
        turtle.turnRight()
    elseif diff == 270 then
        turtle.turnLeft()
    end
    transform.rotation = targetDirection;
end

function traverseHelper.moveBackDestructive()
    if(turtle.back()) then
        return true
    end
    turtle.turnLeft()
    turtle.turnLeft()
    while turtle.detect() do
        turtle.dig()
    end
    turtle.turnRight()
    turtle.turnRight()
    return turtle.back()
end

function traverseHelper.moveForwardDestructive()
    while turtle.detect() do
        turtle.dig()
    end
    return turtle.forward()
end

function traverseHelper.moveUpDestructive()
    while turtle.detectUp() do
        turtle.digUp()
    end
    return turtle.up()
end

function traverseHelper.moveDownDestructive()
    while turtle.detectDown() do
        turtle.digDown()
    end
    return turtle.down()
end

function traverseHelper.traverseX(transform, targetX, posUpdate, context)
    local deltaX = targetX - transform.position.x
    if deltaX ~= 0 then
        traverseHelper.faceDirection(transform, deltaX > 0 and 0 or 180) -- Face east or west
        for i = 1, math.abs(deltaX) do
            traverseHelper.moveForwardDestructive()
            transform.position.x = transform.position.x + (deltaX > 0 and 1 or -1)
            if posUpdate then
                posUpdate(transform, context)
            end
        end
    end
end

function traverseHelper.traverseY(transform, targetY, posUpdate)
    local deltaY = targetY - transform.position.y
    if deltaY ~= 0 then
        for i = 1, math.abs(deltaY) do
            if deltaY > 0 then
                traverseHelper.moveUpDestructive()
                transform.position.y = transform.position.y + 1
            else
                traverseHelper.moveDownDestructive()
                transform.position.y = transform.position.y - 1
            end
            if posUpdate then
                posUpdate(transform)
            end
        end
    end
end

function traverseHelper.traverseZ(transform, targetZ, posUpdate)
    local deltaZ = targetZ - transform.position.z
    if deltaZ ~= 0 then
        traverseHelper.faceDirection(transform, deltaZ > 0 and 90 or 270) -- Face north or south
        for i = 1, math.abs(deltaZ) do
            traverseHelper.moveForwardDestructive()
            transform.position.z = transform.position.z + (deltaZ > 0 and 1 or -1)
            if posUpdate then
                posUpdate(transform)
            end
        end
    end
end

function traverseHelper.traverseTo(transform, destination)
    traverseHelper.traverseZ(transform, destination.z, nil, nil)
    traverseHelper.traverseX(transform, destination.x, nil, nil)
    traverseHelper.traverseY(transform, destination.y, nil, nil)
end

-- todo give it start, end and current so it can continue wherever it ended
function traverseHelper.traverseArea(transform, destination, posUpdate)
    local start = { x = transform.position.x, y = transform.position.y, z = transform.position.z }
    local xReversed = false
    local zReversed = false

    traverseHelper.faceDirection(transform, 0)

    -- initial update callback
    if posUpdate then
        posUpdate(transform)
    end

    -- Loop over Y and Z dimensions.
    for y = start.y, destination.y do
        for z = start.z, destination.z do
            -- Determine target x coordinate based on direction
            local targetX = xReversed and start.x or destination.x
            traverseHelper.traverseX(transform, targetX, posUpdate)

            if z < destination.z then
                -- Calculate next z using the current position.
                local nextZ = transform.position.z + (zReversed and -1 or 1)
                traverseHelper.traverseZ(transform, nextZ, posUpdate)
                xReversed = not xReversed
            end
        end

        if y < destination.y then
            local nextY = transform.position.y + 1
            traverseHelper.traverseY(transform, nextY, posUpdate)
            -- Reorient based on current direction
            traverseHelper.faceDirection(transform, xReversed and 180 or 0)
            zReversed = not zReversed
            xReversed = not xReversed
        end
    end

    print("Traversal complete!")

    -- Optionally reset to the starting coordinates.
    traverseHelper.traverseY(transform, start.y, nil, nil)
    traverseHelper.traverseX(transform, start.x, nil, nil)
    traverseHelper.traverseZ(transform, start.z, nil, nil)
end


return traverseHelper