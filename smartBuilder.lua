local inventoryWrapper = require("Modules.InventoryWrapper")
local logger = require("Modules.utils.logger")
local traverseHelper = require("Modules.traverseHelper")
local ColorMapper = require("Modules.colorMapper")

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

    -- Read and group voxels by Z-plane
    for _ = 1, voxel_count do
        local x, y, z, color = string.unpack("<BBBB", file.read(4))
        x = x + 1 --convert to lua coords
        y = y + 1 --convert to lua coords
        z = z + 1 --convert to lua coords
        planes[z] = planes[z] or {}
        table.insert(planes[z], { x = x, y = y, z = z, color = color })
    end

    -- Define the starting position
    local current_position = { x = 1, y = 0 } -- Start position

    -- Sort each plane based on Manhattan distance
    for z, plane_voxels in pairs(planes) do
        local sorted_plane = {}

        while #plane_voxels > 0 do
            -- Find the closest voxel
            local closest_index = 1
            local closest_distance = math.huge
            for i, voxel in ipairs(plane_voxels) do
                local distance = math.abs(current_position.x - voxel.x) + math.abs(current_position.y - voxel.y)
                if distance < closest_distance then
                    closest_distance = distance
                    closest_index = i
                end
            end

            -- Add the closest voxel to the sorted list
            local closest_voxel = table.remove(plane_voxels, closest_index)
            table.insert(sorted_plane, closest_voxel)

            -- Update the current position
            current_position.x, current_position.y = closest_voxel.x, closest_voxel.y
        end

        -- Replace the original plane with the sorted list
        planes[z] = sorted_plane
    end

    file.close()

    return {
        length = length,
        width = width,
        height = height,
        planes = planes, -- Sorted list of voxels for each plane
    }
end

-- Function to build one plane
local function buildPlane(planes, z, colorMapping)
    local plane = planes[z]
    if not plane then
        logger.warn("No plane at Z=" .. z)
        return
    end

    for _, voxel in pairs(plane) do
        local x = voxel.x
        local y = voxel.y
        local z = voxel.z
        local color = voxel.color

        -- Get material for the voxel's color
        local material = colorMapping[color]
        if not material then
            logger.warn("No material mapped for color ID=" .. color)
            material = "minecraft:stone" -- Fallback material
        end

        -- Move directly to the voxel's position
        logger.info("Moving to X=" .. x .. ", Y=" .. y .. ", Z=" .. z)
        traverseHelper.traverseY(y) -- Absolute Y position
        traverseHelper.traverseX(x) -- Absolute X position

        -- Place the block
        if inventoryWrapper.placeDown(material) then
            logger.info("Placed " .. material .. " at X=" .. x .. ", Y=" .. y .. ", Z=" .. z)
        else
            logger.warn("Failed to place " .. material .. " at X=" .. x .. ", Y=" .. y .. ", Z=" .. z)
        end
    end
end

-- Build the structure plane by plane
local function buildStructure(datFile)
    logger.info("Starting build from file: " .. datFile)

    -- Parse .dat file
    local model = parseDatFile(datFile)

    -- Map colors to materials using ColorMapper
    local colorMapping, _ = ColorMapper.getDisplayedColors(datFile)

    inventoryWrapper.init()
    logger.info("Inventory wrapper initialized.")

    -- Start at a safe position
    traverseHelper.moveUpDestructive()
    traverseHelper.moveForwardDestructive()

    -- Build plane by plane
    for z = 1, model.height do
        logger.info("Moving to plane Z=" .. z)
        traverseHelper.traverseZ(z) -- Move to the Z position of the plane
        buildPlane(model.planes, z, colorMapping) -- Pass the color-to-material mapping
    end

    logger.info("Build completed for file: " .. datFile)

    -- Reset turtle's position
    traverseHelper.traverseY(1, nil, nil)
    traverseHelper.traverseX(0, nil, nil)
    traverseHelper.traverseZ(0, nil, nil)
end

local datFile = "vox_data/Building_only04.dat"

logger.init(true, false, true, "/voxBuilder.log")
logger.runWithLog(function() buildStructure(datFile) end)
logger.close()