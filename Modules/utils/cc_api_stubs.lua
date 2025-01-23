-- cc_api_stubs.lua: Stubs for ComputerCraft APIs
-- Import this file to suppress IDE errors for built-in ComputerCraft APIs and get code completion

-- Skip defining anything if the `term` API (or any other APIs you add later) already exists.
if _G.term then
    return
end

-- ░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
-- ░▒▓        Turtle API      ▓
-- ░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

turtle = {}

--- Craft a recipe based on the turtle's inventory.
--- @param limit number? Maximum number of items to craft (default 64)
--- @return boolean
function turtle.craft(limit) return false end

--- Move the turtle forward one block.
--- @return boolean
function turtle.forward() return false end

--- Move the turtle backward one block.
--- @return boolean
function turtle.back() return false end

--- Move the turtle up one block.
--- @return boolean
function turtle.up() return false end

--- Move the turtle down one block.
--- @return boolean
function turtle.down() return false end

--- Rotate the turtle 90 degrees to the left.
--- @return boolean
function turtle.turnLeft() return false end

--- Rotate the turtle 90 degrees to the right.
--- @return boolean
function turtle.turnRight() return false end

--- Attempt to break the block in front of the turtle.
--- @param side string? Optional side to dig
--- @return boolean
function turtle.dig(side) return false end

--- Attempt to break the block above the turtle.
--- @param side string? Optional side to dig
--- @return boolean
function turtle.digUp(side) return false end

--- Attempt to break the block below the turtle.
--- @param side string? Optional side to dig
--- @return boolean
function turtle.digDown(side) return false end

--- Place a block or item into the world in front of the turtle.
--- @param text string? Optional sign text
--- @return boolean
function turtle.place(text) return false end

--- Place a block or item into the world above the turtle.
--- @param text string? Optional sign text
--- @return boolean
function turtle.placeUp(text) return false end

--- Place a block or item into the world below the turtle.
--- @param text string? Optional sign text
--- @return boolean
function turtle.placeDown(text) return false end

--- Drop the currently selected stack into the inventory in front of the turtle, or as an item into the world.
--- @param count number? Optional number of items to drop
--- @return boolean
function turtle.drop(count) return false end

--- Drop the currently selected stack into the inventory above the turtle.
--- @param count number? Optional number of items to drop
--- @return boolean
function turtle.dropUp(count) return false end

--- Drop the currently selected stack into the inventory below the turtle.
--- @param count number? Optional number of items to drop
--- @return boolean
function turtle.dropDown(count) return false end

--- Change the currently selected slot.
--- @param slot number Slot index
--- @return boolean
function turtle.select(slot) return false end

--- Get the number of items in the given slot.
--- @param slot number? Optional slot index (default current slot)
--- @return number
function turtle.getItemCount(slot) return 0 end

--- Get the remaining number of items which may be stored in this stack.
--- @param slot number? Optional slot index (default current slot)
--- @return number
function turtle.getItemSpace(slot) return 0 end

--- Check if there is a solid block in front of the turtle.
--- @return boolean
function turtle.detect() return false end

--- Check if there is a solid block above the turtle.
--- @return boolean
function turtle.detectUp() return false end

--- Check if there is a solid block below the turtle.
--- @return boolean
function turtle.detectDown() return false end

--- Check if the block in front of the turtle matches the item in the selected slot.
--- @return boolean
function turtle.compare() return false end

--- Check if the block above the turtle matches the item in the selected slot.
--- @return boolean
function turtle.compareUp() return false end

--- Check if the block below the turtle matches the item in the selected slot.
--- @return boolean
function turtle.compareDown() return false end

--- Attack the entity in front of the turtle.
--- @param side string? Optional side to attack
--- @return boolean
function turtle.attack(side) return false end

--- Attack the entity above the turtle.
--- @param side string? Optional side to attack
--- @return boolean
function turtle.attackUp(side) return false end

--- Attack the entity below the turtle.
--- @param side string? Optional side to attack
--- @return boolean
function turtle.attackDown(side) return false end

--- Suck an item from the inventory in front of the turtle, or from an item floating in the world.
--- @param count number? Optional number of items to suck
--- @return boolean
function turtle.suck(count) return false end

--- Suck an item from the inventory above the turtle.
--- @param count number? Optional number of items to suck
--- @return boolean
function turtle.suckUp(count) return false end

--- Suck an item from the inventory below the turtle.
--- @param count number? Optional number of items to suck
--- @return boolean
function turtle.suckDown(count) return false end

--- Get the maximum amount of fuel this turtle currently holds.
--- @return number|string Fuel level or "unlimited"
function turtle.getFuelLevel() return "unlimited" end

--- Refuel this turtle.
--- @param count number? Optional number of items to consume
--- @return boolean
function turtle.refuel(count) return false end

--- Compare the item in the currently selected slot to the item in another slot.
--- @param slot number Slot index to compare
--- @return boolean
function turtle.compareTo(slot) return false end

--- Move an item from the selected slot to another one.
--- @param slot number Slot index to transfer to
--- @param count number? Optional number of items to transfer
--- @return boolean
function turtle.transferTo(slot, count) return false end

--- Get the currently selected slot.
--- @return number
function turtle.getSelectedSlot() return 1 end

--- Get the maximum amount of fuel this turtle can hold.
--- @return number|string Fuel limit or "unlimited"
function turtle.getFuelLimit() return "unlimited" end

--- Equip or unequip an item on the left side of the turtle.
--- @return boolean
function turtle.equipLeft() return false end

--- Equip or unequip an item on the right side of the turtle.
--- @return boolean
function turtle.equipRight() return false end

--- Get information about the block in front of the turtle.
--- @return boolean, table|nil
function turtle.inspect() return false, nil end

--- Get information about the block above the turtle.
--- @return boolean, table|nil
function turtle.inspectUp() return false, nil end

--- Get information about the block below the turtle.
--- @return boolean, table|nil
function turtle.inspectDown() return false, nil end

--- Get detailed information about the items in the given slot.
--- @param slot number? Optional slot index (default current slot)
--- @param detailed boolean? Whether to include NBT data
--- @return table|nil
function turtle.getItemDetail(slot, detailed) return nil end


-- ░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
-- ░▒▓      Peripheral API   ▓
-- ░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

peripheral = {}

--- Provides a list of all peripherals available.
--- @return table List of peripheral names
function peripheral.getNames() return {} end

--- Determines if a peripheral is present with the given name.
--- @param name string Name of the peripheral
--- @return boolean
function peripheral.isPresent(name) return false end

--- Get the types of a named or wrapped peripheral.
--- @param peripheral string|table Name or wrapped peripheral
--- @return string|string[] Peripheral type(s)
function peripheral.getType(peripheral) return nil end

--- Check if a peripheral is of a particular type.
--- @param peripheral string|table Name or wrapped peripheral
--- @param peripheral_type string Type to check
--- @return boolean
function peripheral.hasType(peripheral, peripheral_type) return false end

--- Get all available methods for the peripheral with the given name.
--- @param name string Name of the peripheral
--- @return string[] List of method names
function peripheral.getMethods(name) return {} end

--- Get the name of a peripheral wrapped with peripheral.wrap.
--- @param peripheral table Wrapped peripheral
--- @return string Peripheral name
function peripheral.getName(peripheral) return nil end

--- Call a method on the peripheral with the given name.
--- @param name string Name of the peripheral
--- @param method string Method to call
--- @return ...
function peripheral.call(name, method, ...) end

--- Get a table containing all functions available on a peripheral.
--- @param name string Name of the peripheral
--- @return table Wrapped peripheral
function peripheral.wrap(name) return {} end

--- Find all peripherals of a specific type, and return the wrapped peripherals.
--- @param ty string Type of peripheral
--- @param filter function? Optional filter function
--- @return table List of wrapped peripherals
function peripheral.find(ty, filter) return {} end


-- ░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
-- ░▒▓          Term API     ▓
-- ░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

term = {}

--- Get the default palette value for a colour.
--- @param colour number Colour to get
--- @return number, number, number Red, green, and blue values
function term.nativePaletteColour(colour) return 1, 1, 1 end

--- Write text at the current cursor position, moving the cursor to the end of the text.
--- @param text string Text to write
function term.write(text) end

--- Move all positions up (or down) by y pixels.
--- @param y number Number of pixels to scroll
function term.scroll(y) end

--- Get the position of the cursor.
--- @return number, number Cursor X and Y position
function term.getCursorPos() return 1, 1 end

--- Set the position of the cursor.
--- @param x number X position
--- @param y number Y position
function term.setCursorPos(x, y) end

--- Check if the cursor is currently blinking.
--- @return boolean
function term.getCursorBlink() return false end

--- Set whether the cursor should be visible and blinking.
--- @param blink boolean Whether the cursor blinks
function term.setCursorBlink(blink) end

--- Get the size of the terminal.
--- @return number, number Width and height
function term.getSize() return 51, 19 end

--- Clears the terminal, filling it with the current background colour.
function term.clear() end

--- Clears the line the cursor is currently on.
function term.clearLine() end

--- Return the colour that new text will be written as.
--- @return number
function term.getTextColour() return 1 end

--- Set the colour that new text will be written as.
--- @param colour number Colour to set
function term.setTextColour(colour) end

--- Return the current background colour.
--- @return number
function term.getBackgroundColour() return 32768 end

--- Set the current background colour.
--- @param colour number Colour to set
function term.setBackgroundColour(colour) end

--- Determine if this terminal supports colour.
--- @return boolean
function term.isColour() return true end

--- Writes text to the terminal with the specific foreground and background colours.
--- @param text string Text to write
--- @param textColour string Text colour
--- @param backgroundColour string Background colour
function term.blit(text, textColour, backgroundColour) end

--- Redirects terminal output to another terminal object.
--- @param target table Target terminal object
function term.redirect(target) end

--- Returns the current terminal object of the computer.
--- @return table
function term.current() return term end

--- Get the native terminal object of the current computer.
--- @return table
function term.native() return term end


-- ░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
-- ░▒▓           OS API      ▓
-- ░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

os = {}

--- Pause execution of the current thread and waits for any events matching filter.
--- @param filter string? Optional event filter
--- @return string, ...
function os.pullEvent(filter) return "", nil end

--- Pause execution of the current thread and waits for events, including the terminate event.
--- @param filter string? Optional event filter
--- @return string, ...
function os.pullEventRaw(filter) return "", nil end

--- Pauses execution for the specified number of seconds, alias of _G.sleep.
--- @param time number Time in seconds
function os.sleep(time) end

--- Get the current CraftOS version (e.g., "CraftOS 1.9").
--- @return string
function os.version() return "CraftOS 1.9" end

--- Run the program at the given path with the specified environment and arguments.
--- @param env table Environment for the program
--- @param path string Program path
--- @return boolean, string
function os.run(env, path, ...) return false, "Program failed" end

--- Adds an event to the event queue.
--- @param name string Event name
function os.queueEvent(name, ...) end

--- Starts a timer that will run for the specified number of seconds.
--- @param time number Time in seconds
--- @return number Timer ID
function os.startTimer(time) return 1 end

--- Cancels a timer previously started with startTimer.
--- @param token number Timer ID to cancel
function os.cancelTimer(token) end

--- Sets an alarm that will fire at the specified in-game time.
--- @param time number In-game time
--- @return number Alarm ID
function os.setAlarm(time) return 1 end

--- Cancels an alarm previously started with setAlarm.
--- @param token number Alarm ID to cancel
function os.cancelAlarm(token) end

--- Shuts down the computer immediately.
function os.shutdown() end

--- Reboots the computer immediately.
function os.reboot() end

--- Returns the ID of the computer.
--- @return number
function os.getComputerID() return 0 end

--- Returns the ID of the computer.
--- @return number
function os.computerID() return 0 end

--- Returns the label of the computer, or nil if none is set.
--- @return string|nil
function os.getComputerLabel() return nil end

--- Returns the label of the computer, or nil if none is set.
--- @return string|nil
function os.computerLabel() return nil end

--- Set the label of this computer.
--- @param label string? New computer label
function os.setComputerLabel(label) end

--- Returns the day depending on the locale specified.
--- @param args string? Optional locale
--- @return number
function os.day(args) return 0 end

--- Returns the number of milliseconds since an epoch depending on the locale.
--- @param args string? Optional locale
--- @return number
function os.epoch(args) return 0 end


-- ░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
-- ░▒▓      Paintutils API   ▓
-- ░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

-- ========================
-- Paintutils API
-- ========================
paintutils = {}

--- Parses an image from a multi-line string.
--- @param image string Multi-line string representation of an image
--- @return table Parsed image
function paintutils.parseImage(image) return {} end

--- Loads an image from a file.
--- @param path string Path to the image file
--- @return table Parsed image
function paintutils.loadImage(path) return {} end

--- Draws a single pixel at the specified position.
--- @param xPos number X-coordinate
--- @param yPos number Y-coordinate
--- @param colour number? Optional colour
function paintutils.drawPixel(xPos, yPos, colour) end

--- Draws a straight line between two points.
--- @param startX number Starting X-coordinate
--- @param startY number Starting Y-coordinate
--- @param endX number Ending X-coordinate
--- @param endY number Ending Y-coordinate
--- @param colour number? Optional colour
function paintutils.drawLine(startX, startY, endX, endY, colour) end

--- Draws the outline of a box between two points.
--- @param startX number Starting X-coordinate
--- @param startY number Starting Y-coordinate
--- @param endX number Ending X-coordinate
--- @param endY number Ending Y-coordinate
--- @param colour number? Optional colour
function paintutils.drawBox(startX, startY, endX, endY, colour) end

--- Draws a filled box between two points.
--- @param startX number Starting X-coordinate
--- @param startY number Starting Y-coordinate
--- @param endX number Ending X-coordinate
--- @param endY number Ending Y-coordinate
--- @param colour number? Optional colour
function paintutils.drawFilledBox(startX, startY, endX, endY, colour) end

--- Draws an image at the specified position.
--- @param image table Parsed image
--- @param xPos number X-coordinate
--- @param yPos number Y-coordinate
function paintutils.drawImage(image, xPos, yPos) end


-- Return the stubbed apis for use in the IDE.
return turtle, peripheral, term, os, paintutils, os