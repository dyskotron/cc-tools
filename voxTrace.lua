local VoxTrace = {}

local inventoryWrapper = require("Modules.InventoryWrapper")
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

local function listMissingMaterials(displayedColors, colorToMaterialMap)
    term.clear()
    term.setCursorPos(1, 1)

    print("Missing Materials:")

    local materialCounts = {}
    for colorId, color in ipairs(displayedColors) do
        local itemName = colorToMaterialMap[colorId]
        if not materialCounts[itemName] then
            materialCounts[itemName] = 0
        end
        materialCounts[itemName] = materialCounts[itemName] + color.count
    end

    local y = 2 -- Start below the title
    local missingMaterials = {} -- Store missing materials

    for itemName, totalCount in pairs(materialCounts) do
        -- Check total inventory for the item
        local availableCount = inventoryWrapper.GetTotalItemCount(itemName)
        if availableCount < totalCount then
            -- Calculate the missing amount
            local missingCount = totalCount - availableCount
            local missingStacks = mathUtils.roundUp(missingCount, 64)
            missingMaterials[itemName] = missingStacks
        end
    end

    -- Display missing materials below the list
    if missingMaterials then
        --y = y + 1
        y = 1
        term.setCursorPos(1, y)
        print("Missing Materials:")
        y = y + 1

        for missingItem, missingCount in pairs(missingMaterials) do
            logger.warn("missing material: {}  count needed {}", missingItem, missingCount)
            term.setCursorPos(1, y)
            term.setBackgroundColor(colors.red) -- Set red background
            term.setTextColor(colors.white) -- Set white text color
            term.clearLine() -- Clear the line with the red background
            term.write(string.format("Missing %d of %s", missingCount, stringUtils.getSimplifiedName(missingItem)))
            term.setBackgroundColor(colors.black) -- Reset to default background color
            y = y + 1
        end
    end

    -- Reset colors
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end


function VoxTrace.parseAndShow(filename)

    local displayedColors = colorMapper.getDisplayedColors(filename)
    local colorToMaterialMap

    while true do

        local lastY, map = redraw(displayedColors)
        colorToMaterialMap = map

        -- Wait for user input
        print("Press R to refresh, Enter to finalize...")
        local event, key = os.pullEvent("key")
        if not (key == keys.r) then
            break
        end
    end

    while true do
        -- Draw initial missing materials
        listMissingMaterials(displayedColors, colorToMaterialMap)

        -- Wait for user input
        print("Press R to refresh, Enter to finalize...")
        local event, key = os.pullEvent("key")
        if not (key == keys.r) then
            break
        end

        inventoryWrapper.init()
    end

    term.clear()
end

local datFile = "vox_data/Building_only04.dat"
logger.init(false, true, true, "/voxTrace.log")
logger.runWithLog(function() VoxTrace.parseAndShow(datFile) end)

return VoxTrace