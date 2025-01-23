local VoxTrace = {}

local colorMapper = require("Modules.colorMapper")
local colorUtils = require("Modules.utils.colorUtils")
local mathUtils = require("Modules.utils.mathUtils")
local stringUtils = require("Modules.utils.stringUtils")
local logger = require("Modules.utils.logger")

-- Redraw the inventory mapping
local function redraw(displayedColors)
    term.clear()
    term.setCursorPos(1, 1)
    print("Required Colors and Items:")

    local colorToMaterialMap = colorMapper.getColorToMaterialMap(displayedColors)

    local y = 2 -- Start drawing after the title

    for colorId, color in ipairs(displayedColors) do
        local count = color.count
        local stacks = mathUtils.roundUp(count, 64)
        local itemName = colorToMaterialMap[colorId] -- Get the name of the item in the corresponding turtle slot

        -- Draw color square
        paintutils.drawFilledBox(1, y, 3, y, colorUtils.colorIdToTerminalId(color.slot))

        -- Reset background to black
        term.setBackgroundColor(colors.black)

        -- Write usage and item name
        term.setCursorPos(5, y)
        term.write(string.format("%d stack%s - %s", stacks, stacks > 1 and "s" or "", stringUtils.getSimplifiedName(itemName)))

        y = y + 1 -- Move to the next line
    end

    return y, colorToMaterialMap
end

-- Final grouped log of materials
local function listFinalMaterials(displayedColors, colorToMaterialMap)
    term.clear()
    term.setCursorPos(1, 1)
    print("Final Material Requirements:")

    local materialCounts = {}
    for colorId, color in ipairs(displayedColors) do
        local itemName = colorToMaterialMap[colorId]
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

    local displayedColors = colorMapper.getDisplayedColors(filename)

    -- Draw initial inventory mapping
    local lastY, colorToMaterialMap = redraw(displayedColors)

    while true do
        -- Wait for user input
        term.setCursorPos(1, lastY + 2)
        print("Press R to refresh, Enter to finalize...")

        local event, key = os.pullEvent("key")
        if key == keys.r then
            -- Redraw inventory mapping
            lastY, colorToMaterialMap = redraw(displayedColors)
        elseif key == keys.enter then
            break -- Finalize and log the results
        end
    end

    -- Log final materials
    listFinalMaterials(displayedColors, colorToMaterialMap)

    -- Wait for user input before resetting the palette
    term.setCursorPos(1, lastY + 2)
    print("Press any key to reset the palette and exit...")
    os.pullEvent("key") -- Wait for a key press
end

local datFile = "vox_data/Building_only04.dat"
logger.init(false, true, true, "/voxTrace.log")
logger.runWithLog(function() VoxTrace.parseAndShow(datFile) end)

return VoxTrace