local logger = require("Modules.utils.logger")
local stringUtils = require("Modules.utils.stringUtils")
local keyReceiver = {}

-- Initialize the key receiver
function keyReceiver.start(channel)
    local modem = peripheral.find("modem") -- Automatically find an attached modem
    if not modem then
        logger.error("No modem found!")
    end

    logger.info(stringUtils.tableToString(keys))

    modem.open(channel or 1) -- Open the specified channel, default to 1

    logger.info("KeyReceiver started. Listening on channel:", channel or 1)

    while true do
        local event, side, receivedChannel, replyChannel, message, distance = os.pullEvent("modem_message")

        -- Ensure the message is from the correct channel
        if receivedChannel == (channel or 1) and message.type == "keydown"  then
            if keys[message.key] then
                logger.info("Simulating key press:", message.key)
                os.queueEvent("key", keys[message.key]) -- Simulate the key press event
            else
                logger.error("Invalid or unknown key received:", message.key)
            end
        end
    end
end

return keyReceiver