local inventorywrapper = require("Modules.InventoryWrapper")
local logger = require("Modules.utils.logger")
local traverseHelper = require("Modules.traverseHelper")

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
        planes[z + 1] = planes[z + 1] or {} -- Lua indices start at 1
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

-- Position update callback for traverseHelper
local function myPosUpdate(position, area, context)
    logger.info("New position: X={}, Y={}, Z={}", position.x, position.y, position.z)
    turtle.digDown()

    -- Only place a block if there is a voxel at this position
    local plane = context.model.planes[position.z + 1] -- Lua indices start at 1
    if plane and plane[position.y + 1] then
        for _, voxel in ipairs(plane[position.y + 1]) do
            if voxel.x == position.x then
                turtle.select(context.blockSlot)
                if turtle.placeDown() then
                    logger.info("Placed block at X={}, Y={}, Z={}", position.x, position.y, position.z)
                else
                    logger.warn("Failed to place block at X={}, Y={}, Z={}", position.x, position.y, position.z)
                end
                break
            end
        end
    end
end

-- Build the structure
local function buildStructure(datFile)
    logger.info("Starting build from file: {}", datFile)
    local model = parseDatFile(datFile)

    inventorywrapper.init()
    logger.info("Inventory wrapper initialized.")

    -- Context for traverseHelper
    local context = {
        blockSlot = inventorywrapper.getItemAt(1), -- Use any block from slot 1
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

local datFile = "vox_data/8x8x8.dat"

logger.init(true, true, true, "/voxBuilder.log")
logger.runWithLog(function() buildStructure(datFile) end)
logger.close()
