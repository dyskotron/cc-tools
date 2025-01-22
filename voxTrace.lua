local VoxTrace = {}

local colorMapper = require("Modules.colorMapper")
local colorUtils = require("Modules.utils.colorUtils")
local logger = require("Modules.utils.logger")
local term = term

-- Assign RGB values to a palette slot
local function setPaletteColor(slot, r, g, b)
    if slot ~= colors.white and slot ~= colors.black then -- Keep black and white untouched
        term.setPaletteColour(slot, colors.packRGB(r / 255, g / 255, b / 255))
    end
end

-- Round up a number
local function roundUp(value, divisor)
    return math.ceil(value / divisor)
end

-- Extract the item name after the colon (e.g., "minecraft:stone" -> "stone")
local function getSimplifiedName(fullName)
    local _, _, simpleName = string.find(fullName, ":(.+)")
    return simpleName or fullName
end

-- Get the name of the item in a specific turtle slot
local function getItemName(slot)
    local details = turtle.getItemDetail(slot)
    return details and getSimplifiedName(details.name) or "Empty"
end

-- Redraw the inventory mapping
local function redraw(displayedColors)
    term.clear()
    term.setCursorPos(1, 1)
    print("Required Colors and Items:")

    local y = 2 -- Start drawing after the title

    for i, color in ipairs(displayedColors) do
        local count = color.count
        local stacks = roundUp(count, 64)
        local itemName = getItemName(i) -- Get the name of the item in the corresponding turtle slot

        -- Draw color square
        paintutils.drawFilledBox(1, y, 3, y, colorUtils.colorIdToTerminalId(color.slot))

        -- Reset background to black
        term.setBackgroundColor(colors.black)

        -- Write usage and item name
        term.setCursorPos(5, y)
        term.write(string.format("%d stack%s - %s", stacks, stacks > 1 and "s" or "", itemName))

        y = y + 1 -- Move to the next line
    end

    return y
end

-- Final grouped log of materials
local function logFinalMaterials(displayedColors)
    term.clear()
    term.setCursorPos(1, 1)
    print("Final Material Requirements:")

    local materialCounts = {}
    for i, color in ipairs(displayedColors) do
        local itemName = getItemName(i)
        if not materialCounts[itemName] then
            materialCounts[itemName] = 0
        end
        materialCounts[itemName] = materialCounts[itemName] + color.count
    end

    local y = 2 -- Start below the title
    for itemName, totalCount in pairs(materialCounts) do
        local stacks = roundUp(totalCount, 64)
        term.setCursorPos(1, y)
        term.write(string.format("%d stack%s - %s", stacks, stacks > 1 and "s" or "", itemName))
        y = y + 1
    end
end

function VoxTrace.parseAndShow(filename)

    local result = colorMapper.mapColorsToMaterials(filename)

    displayedColors = result.displayedColors

    -- Draw initial inventory mapping
    local lastY = redraw(displayedColors)

    while true do
        -- Wait for user input
        term.setCursorPos(1, lastY + 2)
        print("Press R to refresh, Enter to finalize...")

        local event, key = os.pullEvent("key")
        if key == keys.r then
            -- Redraw inventory mapping
            lastY = redraw(displayedColors)
        elseif key == keys.enter then
            break -- Finalize and log the results
        end
    end

    -- Log final materials
    logFinalMaterials(displayedColors)

    -- Wait for user input before resetting the palette
    term.setCursorPos(1, lastY + 2)
    print("Press any key to reset the palette and exit...")
    os.pullEvent("key") -- Wait for a key press
end

logger.init(true, true, true, "/voxTrace.log")

    logger.info("{} {} ", colors.white, 0xFFFFFF)
    logger.info("{} {} ", colors.black, 0x000000)
    logger.info("{} {} ", colors.orange, 0xFFA500)
    logger.info("{} {} ", colors.magenta, 0xFF00FF)
    logger.info("{} {} ", colors.lightBlue, 0xADD8E6)
    logger.info("{} {} ", colors.yellow, 0xFFFF00)
    logger.info("{} {} ", colors.lime, 0x00FF00)
    logger.info("{} {} ", colors.pink, 0xFFC0CB)
    logger.info("{} {} ", colors.gray, 0x808080)
    logger.info("{} {} ", colors.lightGray, 0xD3D3D3)
    logger.info("{} {} ", colors.cyan, 0x00FFFF)
    logger.info("{} {} ", colors.purple, 0x800080)
    logger.info("{} {} ", colors.blue, 0x0000FF)
    logger.info("{} {} ", colors.brown, 0xA52A2A)
    logger.info("{} {} ", colors.green, 0x008000)
    logger.info("{} {} ", colors.red, 0xFF0000)


local datFile = "vox_data/Building_only04.dat"

logger.runWithLog(function() VoxTrace.parseAndShow(datFile) end)

return VoxTrace