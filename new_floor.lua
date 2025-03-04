gpsUtils = require("Modules.gps.gps_utils")
vecUtils = require("Modules.utils.vectorUtils")
traverseHelper = require("Modules.traverseHelper")
stringUtils = require("Modules.utils.stringUtils")

local function posUpdate(transform)
    print("POS UPDATE ~ Arrived at destination: (" .. transform.position.x .. ", " .. transform.position.y .. ", " .. transform.position.z .. ")")
end

local args = {...}
ystart = -59 -- -59 is bedrock level + 1, lowest the turtle can safely mine

if #args == 2 then
    height = tonumber(args[1])
    ystart = tonumber(args[2])
elseif #args == 1 then
     height = tonumber(args[1])
else
    print("Invalid params! Use: minechunk <targetY>")

    return
end

print("Moving to chunk origin")

if gpsUtils.faceEast() then
    gpsUtils.locate()
    local globalPos = gpsUtils.locate()
    local chunkPos = gpsUtils.getChunkPos(globalPos)
    transform = { position = chunkPos, rotation = 0 }

    print("Init rotation: " .. transform.rotation)

    traverseHelper.traverseTo(transform, {x=0,y=chunkPos.y,z=0})
    print("after first: " .. transform.rotation)

    traverseHelper.traverseArea(transform, {x=7,y=chunkPos.y + 2,z=7}, posUpdate)
    print("after second: " .. transform.rotation)

    --traverseHelper.traverseTo(relativeTarget)
    --todo: update transform correctly
    traverseHelper.faceDirection(transform, 0)
end

-- print("diggin up")

traverseHelper.traverseArea(16,height,16)