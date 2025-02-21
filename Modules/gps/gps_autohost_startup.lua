local DATA_FILE = "gps_data.txt"

-- Function to save coordinates
local function saveCoords(x, y, z)
  local file = fs.open(DATA_FILE, "w")
  file.writeLine(x)
  file.writeLine(y)
  file.writeLine(z)
  file.close()
end

-- Function to load coordinates
local function loadCoords()
  if not fs.exists(DATA_FILE) then return nil end
  local file = fs.open(DATA_FILE, "r")
  local x, y, z = tonumber(file.readLine()), tonumber(file.readLine()), tonumber(file.readLine())
  file.close()
  return x, y, z
end

-- Try to load saved coordinates
local x, y, z = loadCoords()

-- If no saved coordinates, announce readiness
if not x then
  print("🔄 No saved position found! Announcing ready state...")

  -- Find and open a modem
  local modem = peripheral.find("modem")
  if not modem then
    print("❌ No modem found! GPS host cannot be configured.")
    return
  end
  local modemSide = peripheral.getName(modem)
  if not rednet.isOpen(modemSide) then
    rednet.open(modemSide)
    print("✅ Rednet opened on " .. modemSide)
  end

  -- Broadcast "ready" signal
  rednet.broadcast("gpsConfigReady", "gpsConfig")
  print("📡 Sent 'gpsConfigReady' broadcast, waiting for coordinates...")

  -- Wait for a response
  local _, message, protocol = rednet.receive("gpsConfig", 10)
  if message and protocol == "gpsConfig" then
    -- Expecting coordinates as "x y z"
    local args = {}
    for token in string.gmatch(message, "%S+") do
      table.insert(args, token)
    end

    if #args == 4 then
      local newX, newY, newZ = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
      local id = tonumber(args[4])
      shell.run("label set gps_host_" .. id)
      if newX and newY and newZ then
        -- ✅ Save coordinates
        x, y, z = newX, newY, newZ
        saveCoords(x, y, z)
        print("✅ GPS host configured at: " .. x .. ", " .. y .. ", " .. z)
      else
        print("❌ Invalid coordinates received! Exiting...")
        return
      end
    else
      print("❌ Configuration message must contain three numbers. Exiting...")
      return
    end
  else
    print("❌ No configuration message received. Exiting...")
    return
  end
end

print("📡 Starting GPS host at X=" .. x .. " Y=" .. y .. " Z=" .. z)
shell.run("gps", "host", x, y, z)