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
  local globalX = globalPosRoot[1] + relativePos[1]
  local globalY = globalPosRoot[2] + relativePos[2]
  local globalZ = globalPosRoot[3] + relativePos[3]

  print("📦 Placing GPS computer at global position (" .. globalX .. ", " .. globalY .. ", " .. globalZ .. ")")
  turtle.place()
  sleep(2) -- Allow time for booting

  -- Find and open a modem
  if not rednet.isOpen("left") then
    rednet.open("left")
    print("✅ Rednet opened on left")
  end

  print("🔍 Waiting for GPS host to announce itself...")
  local timeout = os.startTimer(10)

  while true do
    local _, message, protocol = rednet.receive("gpsConfig", 10)
    if message == "gpsConfigReady" and protocol == "gpsConfig" then
      print("✅ GPS host detected. Sending coordinates...")
      rednet.broadcast(globalX .. " " .. globalY .. " " .. globalZ, "gpsConfig")
      print("✅ Sent GPS coordinates: " .. globalX .. ", " .. globalY .. ", " .. globalZ)
      sleep(1) -- Ensure message is received before placing the next computer
      break
    elseif os.clock() > timeout then
      print("❌ No response from GPS host, skipping...")
      return
    end
  end
end


-- Read input arguments for the turtle's starting position
local args = { ... }
if #args < 3 then
  print("Usage: gps_setup <start_x> <start_y> <start_z>")
  return
end
local dp = { tonumber(args[1]), tonumber(args[2]), tonumber(args[3]) }

local gpsHostDistance = 4
local moveUpBy = 3
local globalPosRoot = { dp[1], dp[2] + moveUpBy, dp[3] }

-- Step 1: Climb up
moveUp(moveUpBy)

-- Placement 1: (0,0,0)
moveForward(3)
placeComputer({ gpsHostDistance, 0, 0 }, globalPosRoot)

-- Placement 2: (0,4,0)
moveBack(gpsHostDistance)
placeComputer({ 0, 0, 0 }, globalPosRoot)

-- Placement 3: (4,0,0)
moveLeft(gpsHostDistance)
placeComputer({ 0, 0, gpsHostDistance }, globalPosRoot)

-- Placement 4: Elevated GPS
moveRight(gpsHostDistance)
moveUp(gpsHostDistance)
placeComputer({ 0, gpsHostDistance, 0 }, globalPosRoot)

-- Return to original position
moveDown(moveUpBy + gpsHostDistance)
moveForward(1)

print("GPS provider setup complete!")

