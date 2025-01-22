local VoxTrace = {}

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
        paintutils.drawFilledBox(1, y, 3, y, color.slot)

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
    local file = fs.open(filename, "rb")
    if not file then
        error("Failed to open .dat file: " .. filename)
    end

    -- Read dimensions and voxel count
    local length = string.unpack("<I4", file.read(4))
    local width = string.unpack("<I4", file.read(4))
    local height = string.unpack("<I4", file.read(4))
    local voxel_count = string.unpack("<I4", file.read(4))

    logger.info("Model dimensions: Length=" .. length .. ", Width=" .. width .. ", Height=" .. height)
    logger.info("Total voxels: " .. voxel_count)

    -- Read color information
    local color_count = string.unpack("<I4", file.read(4))
    if not color_count or color_count > 16 then
        error("Invalid color count: " .. tostring(color_count) .. " (must be 16 or fewer)")
    end

    logger.info("Number of colors: " .. color_count)

    -- Initialize color table with counts
    local usedColors = {}
    for i = 1, color_count do
        local index, r, g, b = string.unpack("<BBBB", file.read(4))
        usedColors[index] = { r = r, g = g, b = b, count = 0, slot = 2 ^ (i - 1) }
    end

    -- Read voxel data and increment counts for each color
    for _ = 1, voxel_count do
        local x, y, z, color_index = string.unpack("<BBBB", file.read(4))
        if usedColors[color_index] then
            usedColors[color_index].count = usedColors[color_index].count + 1
        end
    end

    -- Filter out unused colors
    local displayedColors = {}
    for index, color in pairs(usedColors) do
        if color.count > 0 then
            setPaletteColor(color.slot, color.r, color.g, color.b)
            table.insert(displayedColors, { count = color.count, slot = color.slot, r = color.r, g = color.g, b = color.b })
        end
    end

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

    -- Reset palette to default
    term.setPaletteColour(colors.white, 0xFFFFFF)
    term.setPaletteColour(colors.black, 0x000000)
    term.setPaletteColour(colors.orange, 0xFFA500)
    term.setPaletteColour(colors.magenta, 0xFF00FF)
    term.setPaletteColour(colors.lightBlue, 0xADD8E6)
    term.setPaletteColour(colors.yellow, 0xFFFF00)
    term.setPaletteColour(colors.lime, 0x00FF00)
    term.setPaletteColour(colors.pink, 0xFFC0CB)
    term.setPaletteColour(colors.gray, 0x808080)
    term.setPaletteColour(colors.lightGray, 0xD3D3D3)
    term.setPaletteColour(colors.cyan, 0x00FFFF)
    term.setPaletteColour(colors.purple, 0x800080)
    term.setPaletteColour(colors.blue, 0x0000FF)
    term.setPaletteColour(colors.brown, 0xA52A2A)
    term.setPaletteColour(colors.green, 0x008000)
    term.setPaletteColour(colors.red, 0xFF0000)
end

local datFile = "vox_data/Building_only04.dat"
logger.init(true, true, true, "/voxTrace.log")
logger.runWithLog(function() VoxTrace.parseAndShow(datFile) end)

return VoxTrace