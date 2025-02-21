gpsUtils = require("Modules.gps.gps_utils")
traverseHelper = require("Modules.traverseHelper")
stringUtils = require("Modules.utils.stringUtils")

-- Function to make sure the turtle faces east (2)
function faceEast()
    local facing = gpsUtils.getTurtleFacing()
    turnToFacing(facing, 2) -- Turn to East (2)
    print("Turtle is now facing east!")
    return true
end

turtle.up()
if faceEast() then
    local locRaw = gps.locate()
    print(stringUtils.tableToString(locRaw))
    local pos = {x=locRaw[1], y=locRaw[2], z=locRaw[3]}
    print("local pos x:" .. x .. " y:" .. y .. " z:" .. z)
    local chunkOrigin = gpsUtils.getChunkPos(pos)
    print("chunkOrigin x:" .. chunkOrigin.x .. " y:" .. chunkOrigin.y .. " z:" .. chunkOrigin.z)
    traverseHelper.init(chunkOrigin, 0)
    traverseHelper.traverseTo({x=0,y=chunkOrigin.y,z=0})
end
