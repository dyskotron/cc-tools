local inventoryWrapper = require("Modules.InventoryWrapper")
local logger = require("Modules.utils.logger")
local traverseHelper = require("Modules.traverseHelper")
local stringUtils = require("Modules.utils.stringUtils")

-- Function to parse the binary .dat file
local function parseDatFile(filename)
    local file = fs.open(filename, "rb")
    if not file then
        error("Failed to open .dat file: " .. filename)
    end

    -- Read dimensions and voxel count
    local length = string.unpack("<I4", file.read(4))
    local width = string.unpack("<I4", file.read(4))
    local height = string.unpack("<I4", file.read(4))
    local voxel_count = string.unpack("<I4", file.read(4))

    -- Read voxel data
    local planes = {}
    for _ = 1, voxel_count do
        local x, y, z, color = string.unpack("<BBBB", file.read(4))
        planes[z + 1] = planes[z + 1] or {}
        planes[z + 1][y + 1] = planes[z + 1][y + 1] or {}
        table.insert(planes[z + 1][y + 1], { x = x, color = color })
    end

    file.close()
    return {
        length = length,
        width = width,
        height = height,
        planes = planes
    }
end

-- Update callback
local function myPosUpdate(position, area, context)
    logger.info("New position: X={}, Y={}, Z={}", position.x, position.y, position.z)
    turtle.digDown()

    -- Get the plane and row
    local plane = context.model.planes[position.z]
    if not plane then
        return
    end

    local row = plane[position.y]
    if not row then
        return
    end

    local voxel = row[position.x]
    if not voxel then
        return
    end

    local slot = inventoryWrapper.getAnyBlockSlot();
    if not slot then
        logger.warn("no block available in inventory")
        return
    end

    inventoryWrapper.select(slot)
    if turtle.placeDown() then
        logger.info("Placed block at X={}, Y={}, Z={}", position.x, position.y, position.z)
    else
        logger.warn("Failed to place block at X={}, Y={}, Z={}", position.x, position.y, position.z)
    end
end

-- Build the structure
local function buildStructure(datFile)
    logger.info("Starting build from file: {}", datFile)
    local model = parseDatFile(datFile)

    inventoryWrapper.init()
    logger.info("Inventory wrapper initialized.")

    -- Context for traverseHelper
    local context = {
        model = model
    }

    -- Traverse the area and build plane by plane
    traverseHelper.traverseArea(
        model.length,
        model.width,
        model.height,
        myPosUpdate,
        context
    )

    logger.info("Build completed for file: {}", datFile)
end

--local datFile = "vox_data/8x8x8.dat"
--local datFile = "vox_data/test_shape_33.dat"
local datFile = "vox_data/tst44.dat"

logger.init(true, true, true, "/voxBuilder.log")
logger.runWithLog(function() buildStructure(datFile) end)
logger.close()
