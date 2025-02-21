local WIRELESS_CHANNEL = 65535 -- Shared wireless channel for file requests

local modem = peripheral.find("modem", function(_, m) return m.isWireless() end)
if not modem then
    print("No wireless modem found! This computer cannot act as a provider.")
    return
end

print("📡 Universal File Provider Running on Channel " .. WIRELESS_CHANNEL)
modem.open(WIRELESS_CHANNEL)

while true do
    local event, side, channel, replyChannel, message = os.pullEvent("modem_message")

    if channel == WIRELESS_CHANNEL and type(message) == "table" and message.request == "FILE_REQUEST" then
        local requestedFile = message.filename
        print("📥 Received request for: " .. requestedFile)

        -- Run sync to ensure the file is up-to-date
        shell.run("sync", requestedFile)

        -- Check if file exists after sync
        if fs.exists(requestedFile) then
            local file = fs.open(requestedFile, "r")
            local content = file.readAll()
            file.close()

            -- Send the file back
            modem.transmit(WIRELESS_CHANNEL, WIRELESS_CHANNEL, {
                filename = requestedFile,
                content = content
            })
            print("📤 Sent updated file: " .. requestedFile)
        else
            print("❌ Error: Requested file not found after sync: " .. requestedFile)
        end
    end
end