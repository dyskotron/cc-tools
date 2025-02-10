local logger = require("Modules.utils.logger")

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
        x, y, z = x + 1, y + 1, z + 1
        planes[z] = planes[z] or {}
        if color ~= 0 then
            table.insert(planes[z], { x = x, y = y, z = z, color = color })
        end
    end

    -- Sort each plane based on Manhattan distance
    local current_position = { x = 1, y = 0 }
    for z, plane_voxels in pairs(planes) do
        local sorted_plane = {}

        while #plane_voxels > 0 do
            local closest_index = 1
            local closest_distance = math.huge
            for i, voxel in ipairs(plane_voxels) do
                local distance = math.abs(current_position.x - voxel.x) + math.abs(current_position.y - voxel.y)
                if distance < closest_distance then
                    closest_distance = distance
                    closest_index = i
                end
            end

            table.insert(sorted_plane, table.remove(plane_voxels, closest_index))
            current_position.x, current_position.y = sorted_plane[#sorted_plane].x, sorted_plane[#sorted_plane].y
        end

        planes[z] = sorted_plane
    end

    file.close()
    return { length = length, width = width, height = height, planes = planes }
end

return { parseDatFile = parseDatFile }
