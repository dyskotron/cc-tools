local REDNET_PROTOCOL = "gpsConfig"

-- Find and open a modem before placing the GPS host
local modem = peripheral.find("modem")
if not modem then
  print("No modem found! Builder cannot communicate.")
  return
end
local modemSide = peripheral.getName(modem)

if not rednet.isOpen(modemSide) then
  rednet.open(modemSide)
  print("Rednet opened on " .. modemSide)
end

for i = 1, 3 do
  print("Waiting for GPS host to announce itself before placement...")
  local hostReady = false

    -- Start listening before placing the GPS host
    parallel.waitForAll(
      function()
        while true do
          local id, message, protocol = rednet.receive(REDNET_PROTOCOL, 10)

          if(message ~= nil) then
            print("GOT MESSAGE:" .. message)
          end

          if message == "gpsConfigReady" and protocol == REDNET_PROTOCOL then
            print("GPS host detected. Ready to receive coordinates.")
            hostReady = true
            break
          end
        end
      end,
      function()
        -- Wait 1 second before placing the GPS computer to ensure we're listening first
        sleep(1)
        print("Placing GPS computer...")
        turtle.select(i)
        print("selected slot " .. turtle.getSelectedSlot())
        turtle.place()
        turtle.turnRight()
      end
    )

    if not hostReady then
      print("No response from GPS host, exiting...")
      return
    end

    -- Now send the coordinates
    print("Sending test coordinates...")
    rednet.broadcast("1 2 3 " .. i, REDNET_PROTOCOL)-- Test coordinates
    print("Sent test coordinates: 1, 2, 3")
end