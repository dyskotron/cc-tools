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

local traverseHelper = {
    transform = { position = { x = 1, y = 1, z = 1 }, direction = 0 } -- Default transform
}

function traverseHelper.init(chunkOrigin, direction)
    traverseHelper.transform.position = chunkOrigin
    traverseHelper.transform.direction = direction
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

function traverseHelper.moveBackDestructive()
    turtle.turnLeft(2)
    while turtle.detect() do
        turtle.dig()
    end
    turtle.turnRight(2)
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

function traverseHelper.traverseX(currentX, targetX, area, posUpdate, context)
    local deltaX = targetX - currentX
    if deltaX ~= 0 then
        traverseHelper.faceDirection(deltaX > 0 and 0 or 180) -- Face east or west
        for i = 1, math.abs(deltaX) do
            traverseHelper.moveForwardDestructive()
            -- traverseHelper.transform.position.x = traverseHelper.transform.position.x + (deltaX > 0 and 1 or -1)
            if posUpdate then
                -- posUpdate(traverseHelper.transform.position, area, context)
            end
        end
    end
end

function traverseHelper.traverseY(currentY, targetY, area, posUpdate, context)
    local deltaY = targetY - currentY
    if deltaY ~= 0 then
        for i = 1, math.abs(deltaY) do
            if deltaY > 0 then
                traverseHelper.moveUpDestructive()
                print("targetY: " .. targetY .. " dest Y: " .. traverseHelper.transform.position.y .. " deltaY: " .. deltaY)
                --traverseHelper.transform.position.y = traverseHelper.transform.position.y + 1
            else
                traverseHelper.moveDownDestructive()
                --traverseHelper.transform.position.y = traverseHelper.transform.position.y - 1
            end
            if posUpdate then
                -- posUpdate(traverseHelper.transform.position, area, context)
            end
        end
    end
end

function traverseHelper.traverseZ(currentZ, targetZ, area, posUpdate, context)
    local deltaZ = targetZ - currentZ
    if deltaZ ~= 0 then
        traverseHelper.faceDirection(deltaZ > 0 and 90 or 270) -- Face north or south
        for i = 1, math.abs(deltaZ) do
            traverseHelper.moveForwardDestructive()
            --traverseHelper.transform.position.z = traverseHelper.transform.position.z + (deltaZ > 0 and 1 or -1)
            if posUpdate then
                --posUpdate(traverseHelper.transform.position, area, context)
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
    local zReversed = false

    if posUpdate then
        posUpdate(traverseHelper.transform.position, area, context)
    end
    -- z -> y, y-> z

    for y = 1, maxY do
        for z = 1, maxZ do
            traverseHelper.traverseX(xReversed and 1 or maxX, area, posUpdate, context)
            if not (z == maxZ) then
                traverseHelper.traverseZ(traverseHelper.transform.position.Z + (zReversed and -1 or 1), area, posUpdate, context)
                xReversed = not xReversed
            end
        end

        if y < maxY then
            traverseHelper.traverseY(traverseHelper.transform.position.y + 1, area, posUpdate, context)
            traverseHelper.faceDirection(xReversed and 180 or 0)
            zReversed = not zReversed
            xReversed = not xReversed
        end
    end

    print("Traversal complete!")

    traverseHelper.traverseY(1, nil, nil)
    traverseHelper.traverseX(0, nil, nil)
    traverseHelper.traverseZ(0, nil, nil)
end

-- A stateless version of traverseArea.
-- start and dest are objects with {x, y, z}
function traverseHelper.traverse(start, dest, posUpdate, context)
    local area = { x = dest.x, y = dest.y, z = dest.z }
    local current = { x = start.x, y = start.y, z = start.z }
    local xReversed = false
    local zReversed = false

    -- initial update callback
    if posUpdate then
        posUpdate(current, area, context)
    end

    -- Loop over Y and Z dimensions.
    for y = start.y, area.y do
        for z = start.z, area.z do
            -- Determine target x coordinate based on direction
            local targetX = xReversed and start.x or area.x
            traverseHelper.traverseX(current.x, targetX, area, posUpdate, context)
            current.x = targetX;

            if z < area.z then
                -- Calculate next z using the current position.
                local nextZ = current.z + (zReversed and -1 or 1)
                traverseHelper.traverseZ(current.z, nextZ, area, posUpdate, context)
                current.z = nextZ
                xReversed = not xReversed
            end
        end

        if y < area.y then
            local nextY = current.y + 1
            traverseHelper.traverseY(current.y, nextY, area, posUpdate, context)
            current.y = nextY
            -- Reorient based on current direction
            traverseHelper.faceDirection(xReversed and 180 or 0)
            zReversed = not zReversed
            xReversed = not xReversed
        end
    end

    print("Traversal complete!")

    -- Optionally reset to the starting coordinates.
    current = traverseY(current, start.y, nil, nil)
    current = traverseX(current, start.x, nil, nil)
    current = traverseZ(current, start.z, nil, nil)

    return current
end


return traverseHelper