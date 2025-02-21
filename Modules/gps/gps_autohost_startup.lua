-- gps_provider.lua
local DATA_FILE = "gps_data.txt"

-- Function to save coordinates to file
local function saveCoords(x, y, z)
  local file = fs.open(DATA_FILE, "w")
  file.writeLine(x)
  file.writeLine(y)
  file.writeLine(z)
  file.close()
end

-- Function to load coordinates from file
local function loadCoords()
  if not fs.exists(DATA_FILE) then return nil end
  local file = fs.open(DATA_FILE, "r")
  local x, y, z = tonumber(file.readLine()), tonumber(file.readLine()), tonumber(file.readLine())
  file.close()
  return x, y, z
end

-- Try to load saved coordinates
local x, y, z = loadCoords()

-- If no saved coordinates, wait for a configuration message via rednet
if not x then
  print("No saved position found! Waiting for configuration...")
  if not rednet.isOpen("left") then
    rednet.open("left")
  end

  -- Wait up to 10 seconds for a configuration message on protocol "gpsConfig"
  local senderID, message, protocol = rednet.receive("gpsConfig", 10)
  if message then
    -- Expecting the message to contain three numbers separated by spaces.
    local args = {}
    for token in string.gmatch(message, "%S+") do
      table.insert(args, token)
    end

    if #args == 3 then
      x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
      if x and y and z then
        saveCoords(x, y, z)
      else
        print("Invalid coordinates received!")
        return
      end
    else
      print("Configuration message must contain three numbers.")
      return
    end
  else
    print("No configuration message received. Exiting...")
    return
  end
  rednet.close("back")
end

print("Starting GPS host at X=" .. x .. " Y=" .. y .. " Z=" .. z)
shell.run("gps", "host", x, y, z)