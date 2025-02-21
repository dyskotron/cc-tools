-- GPS Setup Script
-- This script assumes the turtle holds 4 GPS computers in its first slot.
-- It climbs 10 blocks, then places computers at the following relative positions:
--   1. (0,0,0)  -- current position
--   2. (0,4,0)  -- 4 blocks forward (north)
--   3. (4,0,0)  -- 4 blocks to the right (east)
--   4. (0,0,4)  -- 4 blocks backward (south)  -- change to (0,-4,0) if you want them all on one horizontal plane

local function moveUp(n)
  for i = 1, n do
    turtle.up()
  end
end

local function moveDown(n)
  for i = 1, n do
    turtle.down()
  end
end

local function moveForward(n)
  for i = 1, n do
    turtle.forward()
  end
end

local function moveBack(n)
  for i = 1, n do
    turtle.back()
  end
end

local function moveLeft(n)
  turtle.turnLeft()
  for i = 1, n do
    turtle.back()
  end
  turtle.turnRight()
end

local function moveRight(n)
  turtle.turnRight()
  for i = 1, n do
    turtle.back()
  end
  turtle.turnLeft()
end

local function placeComputer(relativePos, globalPosRoot)
  print("Placing computer at relative position (" .. table.concat(relativePos, ",") .. ")")
  turtle.place()
end

local dp = {x=0,y=0,z=0} -- default position lets provide this via argument when running the script
local gpsHostDistance = 4
local moveUpBy = 3
local globalPosRoot = {dp.x, dp.y + moveUpBy, dp.z}
-- Step 1: Climb 10 blocks upward.
moveUp(moveUpBy)

-- Save the starting orientation (assumed north) for later reorientation.
-- We now consider this position as the “origin” for our relative coordinates.

-- Placement 1: (0,0,0)
moveForward(3)
placeComputer({gpsHostDistance,0,0}, globalPosRoot)

-- Placement 2: (0,4,0)
moveBack(gpsHostDistance)
placeComputer({0,0,0}, globalPosRoot)

-- Placement 3: (4,0,0)
moveLeft(gpsHostDistance)
placeComputer({0,0,gpsHostDistance}, globalPosRoot)

moveRight(gpsHostDistance)
moveUp(gpsHostDistance)
placeComputer({0,gpsHostDistance,0}, globalPosRoot)

moveDown(moveUpBy+gpsHostDistance)
moveForward(1)

print("GPS provider setup complete!")

