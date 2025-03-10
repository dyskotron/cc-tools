gpsUtils = require("Modules.gps.gps_utils")
vecUtils = require("Modules.utils.vectorUtils")
traverseHelper = require("Modules.traverseHelper")
stringUtils = require("Modules.utils.stringUtils")

local function posUpdate(transform)
    local x = transform.position.x
    local z = transform.position.z
    if(x == -1 or x == 16 or z == -1 or z == 16) then
        --turtle.digDown()
        --turtle.placeDown()
    end
end

local args = {...}
ystart = -59 -- -59 is bedrock level + 1, lowest the turtle can safely mine

if #args == 2 then
    yStart = tonumber(args[1])
    yTarget = tonumber(args[2])
else
    print("Invalid params! Use: minechunk <Y start> <Y end>")

    return
end

print("Moving to chunk origin")

if gpsUtils.faceEast() then
    local globalPos = gpsUtils.locate()
    local chunkPos = gpsUtils.getChunkPos(globalPos)
    local startY = chunkPos.y
    local transform = { position = {x=chunkPos.x, y=chunkPos.y, z=chunkPos.z}, rotation = 0 }

    print("Init rotation: " .. transform.rotation)

    -- wall around
    -- traverseHelper.traverseTo(transform, {x=-1, y=ystart, z=-1})
    -- traverseHelper.traverseArea(transform, {x=16,y=startY + 5, z=16}, posUpdate)

    traverseHelper.traverseTo(transform, {x=0, y=yStart, z=0})
    traverseHelper.traverseArea(transform, {x=15,y=yTarget, z=15}, posUpdate)

    --traverseHelper.traverseTo(transform, {x=0, y=startY, z=0})
    -- traverseHelper.faceDirection(transform, 0)
end

-- print("diggin up")
-- traverseHelper.traverseArea(16,height,16)