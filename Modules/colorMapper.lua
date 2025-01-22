local logger = require("Modules.utils.logger")
local inventoryWrapper = require("InventoryWrapper")
local ColorMapper = {}

-- Map color indices to materials in the turtle's inventory
function ColorMapper.mapColorsToMaterials(filename)
    local file = fs.open(filename, "rb")
    if not file then
        error("Failed to open .dat file: " .. filename)
    end

    -- Read dimensions and voxel count
    local length = string.unpack("<I4", file.read(4))
    local width = string.unpack("<I4", file.read(4))
    local height = string.unpack("<I4", file.read(4))
    local voxel_count = string.unpack("<I4", file.read(4))

    -- Read color information
    local color_count = string.unpack("<I4", file.read(4))
    if not color_count or color_count > 16 then
        error("Invalid color count: " .. tostring(color_count) .. " (must be 16 or fewer)")
    end

    -- Initialize color table with counts
    local usedColors = {}
    for i = 1, color_count do
        local index, r, g, b = string.unpack("<BBBB", file.read(4))
        usedColors[index] = { count = 0, slot = i }
    end

    -- Read voxel data and increment counts for each color
    for _ = 1, voxel_count do
        local x, y, z, color_index = string.unpack("<BBBB", file.read(4))
        if usedColors[color_index] then
            usedColors[color_index].count = usedColors[color_index].count + 1
        end
    end

    file.close()

    inventoryWrapper.init()

    -- Map color IDs to materials
    local materialMapping = {}
    for colorID, color in pairs(usedColors) do
        if color.count > 0 then
            local fullName = inventoryWrapper.getItemAt(color.slot).name
            if fullName then
                materialMapping[colorID] = fullName
            else
                logger.warn("No item found in slot " .. color.slot)
                materialMapping[colorID] = nil -- Or set a fallback material if desired
            end
        end
    end

    return {materialMapping = materialMapping, usedColors = usedColors}
end

return ColorMapper
