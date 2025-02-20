local logger = require("Modules.utils.logger")

local function verifyDatFile(filename)
    local file = fs.open(filename, "rb")
    if not file then
        logger.error("Failed to open .dat file: " .. filename)
        return false
    end

    logger.info("Verifying file: " .. filename)

    -- Read dimensions and voxel count
    local length = string.unpack("<I4", file.read(4))
    local width = string.unpack("<I4", file.read(4))
    local height = string.unpack("<I4", file.read(4))
    local voxel_count = string.unpack("<I4", file.read(4))

    logger.info("Dimensions: " .. length .. " x " .. width .. " x " .. height)
    logger.info("Voxel count: " .. voxel_count)

    -- Read color count
    local color_count = string.unpack("<I4", file.read(4))
    if color_count > 16 then
        logger.error("Invalid color count: " .. color_count .. " (must be 16 or fewer)")
        return false
    end
    logger.info("Color count: " .. color_count)

    -- Read color definitions
    local colors = {}
    for i = 1, color_count do
        local index, r, g, b = string.unpack("<BBBB", file.read(4))
        colors[index] = { r = r, g = g, b = b }
    end
    logger.info("Read " .. color_count .. " colors.")

    -- Read voxel data
    local voxel_data = {}
    for i = 1, voxel_count do
        local data = file.read(4)
        if not data or #data < 4 then
            logger.info("❌ Error: Unexpected EOF while reading voxel data at voxel " .. i)
            logger.info("Read only " .. (#data or 0) .. " bytes instead of 4")
            return false
        end
        local x, y, z, color_index = string.unpack("<BBBB", data)
        table.insert(voxel_data, { x = x, y = y, z = z, color = color_index })
    end
    logger.info("Read " .. voxel_count .. " voxels.")

    file.close()

    logger.info("✅ File structure is valid!")
    return true
end

logger.init(true, true, true, "voxVerify")
verifyDatFile("vox_data/Building_only04.dat")

return { verifyDatFile = verifyDatFile }