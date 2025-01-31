local inventoryWrapper = require("Modules.InventoryWrapper")
local traverseHelper = require("Modules.traverseHelper")
local ColorMapper = require("Modules.colorMapper")
local datParser = require("datParser") -- New parser module
local logger = require("Modules.utils.logger")

-- Function to build one plane
local function buildPlane(planes, z, colorMapping)
    local plane = planes[z]
    if not plane then
        logger.warn("No plane at Z=" .. z)
        return false
    end

    for _, voxel in ipairs(plane) do
        local x, y, z, color = voxel.x, voxel.y, voxel.z, voxel.color
        local material = colorMapping[color]
        if not material then
            logger.error("No material mapped for color ID=" .. color)
            return false
        end

        logger.info("Moving to X=" .. x .. ", Y=" .. y .. ", Z=" .. z)
        traverseHelper.traverseY(y)
        traverseHelper.traverseX(x)

        if inventoryWrapper.placeDown(material) then
            logger.info("Placed " .. material .. " at X=" .. x .. ", Y=" .. y .. ", Z=" .. z)
        else
            logger.warn("Failed to place " .. material .. " at X=" .. x .. ", Y=" .. y .. ", Z=" .. z)
        end
    end

    return true
end

-- Build the structure plane by plane
local function buildStructure(parsedModel, colorMapping)
    traverseHelper.moveUpDestructive()
    traverseHelper.moveForwardDestructive()

    for z = 1, parsedModel.height do
        logger.info("Moving to plane Z=" .. z)
        traverseHelper.traverseZ(z)
        if not buildPlane(parsedModel.planes, z, colorMapping) then
            logger.error("Aborting build due to missing materials or failure")
            return
        end
    end

    traverseHelper.traverseY(1)
    traverseHelper.traverseX(0)
    traverseHelper.traverseZ(0)
end

-- Main execution
local datFile = "vox_data/Building_only04.dat"
logger.init(true, true, true, "/smartBuilder.log")

logger.runWithLog(function()
    local parsedModel = datParser.parseDatFile(datFile)
    local displayedColors = ColorMapper.getDisplayedColors(datFile)
    local colorMapping = ColorMapper.getColorToMaterialMap(displayedColors)
    buildStructure(parsedModel, colorMapping)
end)

logger.close()