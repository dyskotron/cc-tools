local WIRELESS_CHANNEL = 65535 -- Shared wireless channel for communication
local REQUESTED_FILE = "Modules/gps/gps_autohost_startup.lua"

-- Function to check for a wireless modem
local function hasModem()
    return peripheral.find("modem", function(_, m) return m.isWireless() end) ~= nil
end

-- Function to request a file over the modem
local function requestFile()
    local modem = peripheral.find("modem", function(_, m) return m.isWireless() end)
    if not modem then return false end

    print("📡 Requesting " .. REQUESTED_FILE .. " over modem...")
    modem.open(WIRELESS_CHANNEL)

    -- Send a request for the file
    modem.transmit(WIRELESS_CHANNEL, WIRELESS_CHANNEL, {
        request = "FILE_REQUEST",
        filename = REQUESTED_FILE
    })

    -- Wait for response (timeout after 5 seconds)
    local timeout = os.startTimer(5)
    while true do
        local event, side, channel, replyChannel, message = os.pullEvent()
        if event == "modem_message" and channel == WIRELESS_CHANNEL then
            if type(message) == "table" and message.filename == REQUESTED_FILE then
                -- Save received file
                local file = fs.open("disk/gps_autohost_startup.lua", "w")
                file.write(message.content)
                file.close()
                print("✅ Received and saved " .. REQUESTED_FILE .. "!")
                return true
            end
        elseif event == "timer" and side == timeout then
            print("⏳ No response received, using local disk copy...")
            return false
        end
    end
end

if hasModem() then
    local success = requestFile()
    if success then
        print("Sucessfully updated gps_autohost_startup.lua from file server.")
    else
        print("🚨 No response from file server. POssibly outdated gps_autohost_startup.lua.")
    end
end


if fs.exists("gps_data.txt") then
    fs.delete("gps_data.txt")
end
if fs.exists("startup.lua") then
    fs.delete("startup.lua")
end
fs.copy("disk/gps_autohost_startup.lua", "startup.lua")
print("🛠️ GPS host setup complete: startup.lua created.")