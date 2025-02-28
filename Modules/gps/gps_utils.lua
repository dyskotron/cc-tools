local gpsUtils = {}

function gpsUtils.globalToLocal(globalPos, origin)
    return {
        x = globalPos.x - origin.x,
        y = globalPos.y - origin.y,
        z = globalPos.z - origin.z
    }
end

function gpsUtils.localToGlobal(localPos, origin)
    return {
        x = localPos.x + origin.x,
        y = localPos.y + origin.y,
        z = localPos.z + origin.z
    }
end

function gpsUtils.nearestChunkOrigin(pos, chunkSize)
    chunkSize = chunkSize or 16 -- Default chunk size

    return {
        x = math.floor(pos.x / chunkSize) * chunkSize,
        y = pos.y, -- Y remains unchanged
        z = math.floor(pos.z / chunkSize) * chunkSize
    }
end

function gpsUtils.getChunkPos(pos, chunkSize)
    chunkSize = chunkSize or 16 -- Default chunk size

    return {
        x = pos.x % chunkSize,
        y = pos.y, -- Y remains unchanged
        z = pos.z % chunkSize
    }
end

function gpsUtils.getTurtleFacing()
    -- Get initial GPS position
    local x1, y1, z1 = gps.locate()
    if not x1 then
        print("GPS signal not found! Ensure GPS providers are active.")
        return nil
    end

    -- Move forward to determine direction
    if not turtle.forward() then
        print("Turtle cannot move forward! Check for obstacles.")
        return nil
    end

    -- Get new GPS position
    local x2, y2, z2 = gps.locate()
    if not x2 then
        print("GPS signal lost after moving!")
        return nil
    end

    -- Determine numeric direction
    local facing
    if x2 > x1 then
        facing = 2 -- East (+X)
    elseif x2 < x1 then
        facing = 4 -- West (-X)
    elseif z2 > z1 then
        facing = 3 -- South (+Z)
    elseif z2 < z1 then
        facing = 1 -- North (-Z)
    else
        facing = nil
    end

    -- Move back to original position
    turtle.back()

    return facing
end

function gpsUtils.turnToFacing(current, target)
    if current == target then
        return
    end

    -- Calculate the shortest turn
    local turns = (target - current) % 4
    if turns == 3 then
        turtle.turnLeft()
    else
        for _ = 1, turns do
            turtle.turnRight()
        end
    end
end

function gpsUtils.faceEast()
    local facing = gpsUtils.getTurtleFacing()
    gpsUtils.turnToFacing(facing, 2)
    return true
end

return gpsUtils

