gpsUtils = require("Modules.gps.gps_utils")

-- Function to make sure the turtle faces east (2)
function faceEast()
    local facing = gpsUtils.getTurtleFacing()
    if not facing then
        print("Error determining direction.")
        return false
    end

    print("Current facing:", facing)
    turnToFacing(facing, 2) -- Turn to East (2)
    print("Turtle is now facing east!")
    return true
end

-- Ensure the turtle is facing east before moving
if faceEast() then
    print("Moving forward...")
    turtle.forward()

    -- Verify movement
    local newX, newY, newZ = gps.locate()
    if newX then
        print("New position: X=" .. newX .. " Y=" .. newY .. " Z=" .. newZ)
    else
        print("GPS error after moving!")
    end
end