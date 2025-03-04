gpsUtils = require("Modules.gps.gps_utils")
traverseHelper = require("Modules.traverseHelper")
stringUtils = require("Modules.utils.stringUtils")



local args = {...}
ystart = -59 -- -59 is bedrock level + 1, lowest the turtle can safely mine

traverseHelper.traverse({x=0, y=0, z=0}, {x=5, y=1, z=3})
if false then
    return
end


if #args == 2 then
    height = tonumber(args[1]) - traverseHelper.transform.position.y
    ystart = tonumber(args[2]) - traverseHelper.transform.position.y
elseif #args == 1 then
     height = tonumber(args[1]) - traverseHelper.transform.position.y
else
    print("Invalid params! Use: minechunk <targetY>")
    return
end

print("Moving to chunk origin")

if gpsUtils.faceEast() then
    local x, y, z = gps.locate()
    local pos = {x=x, y=y, z=z}
    local chunkOrigin = gpsUtils.getChunkPos(pos)
    traverseHelper.init(chunkOrigin, 0)

    -- to stay at same height traverseHelper.traverseTo({x=0,y=chunkOrigin.y,z=0})
    traverseHelper.traverseTo({x=0,y=-59,z=0})
    traverseHelper.faceDirection(0)
end

-- print("diggin up")

traverseHelper.traverseArea(16,height,16)