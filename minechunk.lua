gpsUtils = require("Modules.gps.gps_utils")
vecUtils = require("Modules.utils.vectorUtils")
traverseHelper = require("Modules.traverseHelper")
stringUtils = require("Modules.utils.stringUtils")

local function posUpdate(transform)
    local x = transform.position.x
    local z = transform.position.z
    if(x == -1 or x == 16 or z == -1 or z == 16) then
        turtle.digDown()
        turtle.placeDown()
    end
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
    local globalPos = gpsUtils.locate()
    local chunkPos = gpsUtils.getChunkPos(globalPos)
    local startY = chunkPos.y
    local transform = { position = {x=chunkPos.x, y=chunkPos.y, z=chunkPos.z}, rotation = 0 }

    print("Init rotation: " .. transform.rotation)

    traverseHelper.traverseTo(transform, {x=-1, y=startY-1, z=-1})
    --traverseHelper.traverseTo(transform, {x=2, y=startY + 8, z=2})
    --traverseHelper.traverseTo(transform, {x=3, y=startY - 1, z=1})
    --traverseHelper.traverseTo(transform, {x=7, y=startY + 5, z=1})
    --traverseHelper.traverseTo(transform, {x=0, y=startY, z=0})
    --traverseHelper.faceDirection(transform, 90)

    traverseHelper.traverseArea(transform, {x=16,y=startY + 5, z=16}, posUpdate)
    traverseHelper.traverseTo(transform, {x=0, y=startY, z=0})
    traverseHelper.faceDirection(transform, 90)
end

-- print("diggin up")
-- traverseHelper.traverseArea(16,height,16)