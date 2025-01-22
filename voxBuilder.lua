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


    local planes = {}
    local all_voxels = {}

    -- Collect all voxels for sorting
    for _ = 1, voxel_count do
        local x, y, z, color = string.unpack("<BBBB", file.read(4))
        table.insert(all_voxels, { x = x, y = y, z = z, color = color })
    end

    -- Sort voxels by Z, then X, then Y
    table.sort(all_voxels, function(a, b)
        if a.z ~= b.z then
            return a.z < b.z
        elseif a.x ~= b.x then
            return a.x < b.x
        else
            return a.y < b.y
        end
    end)

    -- Store voxels in a nested table structure for efficient access
    for _, voxel in ipairs(all_voxels) do
        local x, y, z, color = voxel.x + 1, voxel.y + 1, voxel.z + 1, voxel.color
        planes[z] = planes[z] or {}
        planes[z][y] = planes[z][y] or {}
        planes[z][y][x] = { color = color }
    end

    -- Log sorted voxels
    for _, voxel in ipairs(all_voxels) do
        logger.info("voxel x: " .. voxel.x .. " y: " .. voxel.y .. " z: " .. voxel.z)
    end

    file.close()
    return {
        length = length,
        width = width,
        height = height,
        planes = planes
    }
end

-- Function to retrieve a voxel from the planes structure
local function getVoxel(planes, x, y, z)
    local plane = planes[z]
    if not plane then
        logger.warn("No plane at Z=" .. z)
        return nil
    end

    local row = plane[y]
    if not row then
        logger.warn("No row at Y=" .. y .. " in plane Z=" .. z)
        return nil
    end

    local voxel = row[x]
    if not voxel then
        logger.warn("No voxel at X=" .. x .. ", Y=" .. y .. ", Z=" .. z)
        return nil
    end

    return voxel
end

-- Update callback
local function myPosUpdate(position, area, context)
    logger.info("New position: X={}, Y={}, Z={}", position.x, position.y, position.z)
    turtle.digDown()

    -- Get the plane and row
    local voxel = getVoxel(context.model.planes, position.x, position.y, position.z)
    if(voxel == nil) then
        return
    end

    if inventoryWrapper.placeDown("advancednetherite:netherite_diamond_block") then
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

    traverseHelper.moveUpDestructive()
    traverseHelper.moveForwardDestructive()

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
local datFile = "vox_data/Building04.dat"
--local datFile = "vox_data/tst44.dat"

logger.init(true, true, true, "/voxBuilder.log")
logger.runWithLog(function() buildStructure(datFile) end)
logger.close()
