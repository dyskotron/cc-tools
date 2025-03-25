gpsUtils = require("Modules.gps.gps_utils")
vecUtils = require("Modules.utils.vectorUtils")
traverseHelper = require("Modules.traverseHelper")
stringUtils = require("Modules.utils.stringUtils")
textFileUtil = require("Modules.utils.textFileUtil")

stepCounter = 0

local function posUpdate(transform)

    stepCounter = stepCounter + 1
    if stepCounter % 1000 == 0 then
        if turtle.getFuelLevel() < 1000 then
            print("Fuel low (" .. turtle.getFuelLevel() .. "), refueling...")
            turtle.refuel()
        end
    end

    local x = transform.position.x
    local z = transform.position.z
    if(x == -1 or x == 16 or z == -1 or z == 16) then
        --turtle.digDown()
        --turtle.placeDown()
    end
end

local args = {...}

if #args == 2 then
    yStart = tonumber(args[1])
    yTarget = tonumber(args[2])
elseif #args == 1 then
    yTarget = tonumber(args[1])
else
    yTarget = -59 -- -59 is bedrock level + 1, lowest the turtle can safely mine
end

print("Moving to chunk origin")

startupSource = "startupAction"

if gpsUtils.faceEast() then
    local globalPos = gpsUtils.locate()
    local chunkPos = gpsUtils.getChunkPos(globalPos)
    if(yStart == nil) then
        yStart = chunkPos.y
    end
    local transform = { position = {x=chunkPos.x, y=chunkPos.y, z=chunkPos.z}, rotation = 0 }

    textFileUtil.writeToFile(startupSource, "minechunk " .. yTarget)

    -- wall around
    -- traverseHelper.traverseTo(transform, {x=-1, y=ystart, z=-1})
    -- traverseHelper.traverseArea(transform, {x=16,y=startY + 5, z=16}, posUpdate)

    traverseHelper.traverseTo(transform, {x=0, y=yStart, z=0})
    traverseHelper.traverseArea(transform, {x=15,y=yTarget, z=15}, posUpdate)

    --traverseHelper.traverseTo(transform, {x=0, y=startY, z=0})
    -- traverseHelper.faceDirection(transform, 0)

    print("Minechunk done")
    fs.delete(startupSource)

end