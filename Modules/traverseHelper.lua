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

local traverseHelper = {
    transform = { position = { x = 1, y = 1, z = 1 }, direction = 0 } -- Default transform
}

function traverseHelper.init(position, direction)
    traverseHelper.transform = { position, direction} -- Default transform
end

function traverseHelper.normalizeDirection(dir)
    return (dir + 360) % 360
end

function traverseHelper.turnLeft()
    turtle.turnLeft()
    traverseHelper.transform.direction = traverseHelper.normalizeDirection(traverseHelper.transform.direction - 90)
end

function traverseHelper.turnRight()
    turtle.turnRight()
    traverseHelper.transform.direction = traverseHelper.normalizeDirection(traverseHelper.transform.direction + 90)
end

function traverseHelper.faceDirection(targetDirection)
    local diff = traverseHelper.normalizeDirection(targetDirection - traverseHelper.transform.direction)
    if diff == 90 then
        traverseHelper.turnRight()
    elseif diff == 180 then
        traverseHelper.turnRight()
        traverseHelper.turnRight()
    elseif diff == 270 then
        traverseHelper.turnLeft()
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

function traverseHelper.traverseX(targetX, area, posUpdate, context)
    local deltaX = targetX - traverseHelper.transform.position.x
    if deltaX ~= 0 then
        traverseHelper.faceDirection(deltaX > 0 and 0 or 180) -- Face east or west
        for i = 1, math.abs(deltaX) do
            traverseHelper.moveForwardDestructive()
            traverseHelper.transform.position.x = traverseHelper.transform.position.x + (deltaX > 0 and 1 or -1)
            if posUpdate then
                posUpdate(traverseHelper.transform.position, area, context)
            end
        end
    end
end

function traverseHelper.traverseY(targetY, area, posUpdate, context)
    local deltaY = targetY - traverseHelper.transform.position.y
    if deltaY ~= 0 then
        traverseHelper.faceDirection(deltaY > 0 and 90 or 270) -- Face north or south
        for i = 1, math.abs(deltaY) do
            traverseHelper.moveForwardDestructive()
            traverseHelper.transform.position.y = traverseHelper.transform.position.y + (deltaY > 0 and 1 or -1)
            if posUpdate then
                posUpdate(traverseHelper.transform.position, area, context)
            end
        end
    end
end

function traverseHelper.traverseZ(targetZ, area, posUpdate, context)
    local deltaZ = targetZ - traverseHelper.transform.position.z
    if deltaZ ~= 0 then
        for i = 1, math.abs(deltaZ) do
            if deltaZ > 0 then
                traverseHelper.moveUpDestructive()
                traverseHelper.transform.position.z = traverseHelper.transform.position.z + 1
            else
                traverseHelper.moveDownDestructive()
                traverseHelper.transform.position.z = traverseHelper.transform.position.z - 1
            end
            if posUpdate then
                posUpdate(traverseHelper.transform.position, area, context)
            end
        end
    end
end

function traverseHelper.traverseTo(destination)
    print("traverseHelper.traverseTo: (" .. traverseHelper.transform.position.x .. ", " .. traverseHelper.transform.position.y .. ", " .. traverseHelper.transform.position.z .. ")")
    traverseHelper.traverseZ(destination.z, nil, nil)
    traverseHelper.traverseX(destination.x, nil, nil)
    traverseHelper.traverseY(destination.y, nil, nil)
    print("Arrived at destination: (" .. destination.x .. ", " .. destination.y .. ", " .. destination.z .. ")")
end

function traverseHelper.traverseArea(maxX, maxY, maxZ, posUpdate, context)
    local area = { x = maxX, y = maxY, z = maxZ }
    local position = { x = 1, y = 1, z = 1 }
    traverseHelper.transform = { position = position, direction = 0 } -- Initialize transform

    local xReversed = false
    local yReversed = false

    if posUpdate then
        posUpdate(traverseHelper.transform.position, area, context)
    end

    for z = 1, maxZ do
        for y = 1, maxY do
            traverseHelper.traverseX(xReversed and 1 or maxX, area, posUpdate, context)
            if not (y == maxY) then
                traverseHelper.traverseY(traverseHelper.transform.position.y + (yReversed and -1 or 1), area, posUpdate, context)
                xReversed = not xReversed
            end
        end

        if z < maxZ then
            traverseHelper.traverseZ(traverseHelper.transform.position.z + 1, area, posUpdate, context)
            traverseHelper.faceDirection(xReversed and 180 or 0)
            yReversed = not yReversed
            xReversed = not xReversed
        end
    end

    print("Traversal complete!")

    traverseHelper.traverseY(1, nil, nil)
    traverseHelper.traverseX(0, nil, nil)
    traverseHelper.traverseZ(0, nil, nil)
end

return traverseHelper