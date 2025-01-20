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

local traverseHelper = {}

function traverseHelper.normalizeDirection(dir)
    return (dir + 360) % 360
end

function traverseHelper.turnLeft(transform)
    turtle.turnLeft()
    transform.direction = traverseHelper.normalizeDirection(transform.direction - 90)
end

function traverseHelper.turnRight(transform)
    turtle.turnRight()
    transform.direction = traverseHelper.normalizeDirection(transform.direction + 90)
end

function traverseHelper.faceDirection(targetDirection, transform)
    local diff = traverseHelper.normalizeDirection(targetDirection - transform.direction)
    if diff == 90 then
        traverseHelper.turnRight(transform)
    elseif diff == 180 then
        traverseHelper.turnRight(transform)
        traverseHelper.turnRight(transform)
    elseif diff == 270 then
        traverseHelper.turnLeft(transform)
    end
end

function traverseHelper.moveForwardDestructive()
    while turtle.detect() do
        turtle.dig()
    end
    turtle.forward()
end

function traverseHelper.moveUpDestructive()
    while turtle.detectUp() do
        turtle.digUp()
    end
    turtle.up()
end

function traverseHelper.moveDownDestructive()
    while turtle.detectDown() do
        turtle.digDown()
    end
    turtle.down()
end

-- Traverse X-axis
function traverseHelper.traverseX(transform, targetX, area, posUpdate, context)
    local deltaX = targetX - transform.position.x
    if deltaX ~= 0 then
        traverseHelper.faceDirection(deltaX > 0 and 0 or 180, transform) -- Face east or west
        for i = 1, math.abs(deltaX) do
            traverseHelper.moveForwardDestructive()
            transform.position.x = transform.position.x + (deltaX > 0 and 1 or -1)
            if posUpdate then
                posUpdate(transform.position, area, context)
            end
        end
    end
    return transform
end

-- Traverse Y-axis
function traverseHelper.traverseY(transform, targetY, area, posUpdate, context)
    local deltaY = targetY - transform.position.y
    if deltaY ~= 0 then
        traverseHelper.faceDirection(deltaY > 0 and 90 or 270, transform) -- Face north or south
        for i = 1, math.abs(deltaY) do
            traverseHelper.moveForwardDestructive()
            transform.position.y = transform.position.y + (deltaY > 0 and 1 or -1)
            posUpdate(transform.position, area, context)
        end
    end
    return transform
end

-- Traverse Z-axis
function traverseHelper.traverseZ(transform, targetZ, area, posUpdate, context)
    local deltaZ = targetZ - transform.position.z
    if deltaZ ~= 0 then
        for i = 1, math.abs(deltaZ) do
            if deltaZ > 0 then
                traverseHelper.moveUpDestructive()
                transform.position.z = transform.position.z + 1
            else
                traverseHelper.moveDownDestructive()
                transform.position.z = transform.position.z - 1
            end
            posUpdate(transform.position, area, context)
        end
    end
    return transform
end

-- Traverse to destination
function traverseHelper.traverseTo(destination, transform)
    -- Traverse Z-axis
    traverseHelper.traverseZ(transform, destination.z, nil, nil)

    -- Traverse X-axis
    traverseHelper.traverseX(transform, destination.x, nil, nil)

    -- Traverse Y-axis
    traverseHelper.traverseY(transform, destination.y, nil, nil)

    print("Arrived at destination: (" .. destination.x .. ", " .. destination.y .. ", " .. destination.z .. ")")
end

-- Traverse an area
function traverseHelper.traverseArea(maxX, maxY, maxZ, posUpdate, context)
    local area = { x = maxX, y = maxY, z = maxZ }
    local position = { x = 1, y = 1, z = 1 }
    local xReversed = false
    local yReversed = false
    local transform = { position = position, direction = 0 }  -- The transformation table

    posUpdate(position, area, context)

    for z = 1, maxZ do
        for y = 1, maxY do
            transform = traverseHelper.traverseX(transform, xReversed and 1 or maxX, area, posUpdate, context)
            if not (y == maxY) then
                local targetY = transform.position.y + (yReversed and -1 or 1);
                transform = traverseHelper.traverseY(transform, targetY, area, posUpdate, context)
                xReversed = not xReversed
            end
        end

        if z < maxZ then
            transform = traverseHelper.traverseZ(transform, transform.position.z + 1, area, posUpdate, context)
            traverseHelper.faceDirection(xReversed and 180 or 0, transform)
            yReversed = not yReversed
            xReversed = not xReversed
        end
    end

    print("Traversal complete!")
    transform = traverseHelper.traverseX(transform, -1, nil, nil)
    transform = traverseHelper.traverseY(transform, 0, nil, nil)
    transform = traverseHelper.traverseZ(transform, 0, nil, nil)
end

return traverseHelper
