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

-- Get command-line arguments
local args = {...}
local x, y, z

if #args == 3 then
    x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    if x and y and z then
        saveCoords(x, y, z)
    else
        print("Invalid coordinates! Use: gps_provider <x> <y> <z>")
        return
    end
else
    x, y, z = loadCoords()
    if not x then
        print("No saved position found! Set manually using: gps_provider <x> <y> <z>")
        return
    end
end
-- strtup: shell.run("Modules/gps/gps_provider")
print("Starting GPS host at X=" .. x .. " Y=" .. y .. " Z=" .. z)
shell.run("gps", "host", x, y, z)