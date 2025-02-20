local inventoryWrapper = require("Modules.InventoryWrapper")
local logger = require("Modules.utils.logger")
local traverseHelper = require("Modules.traverseHelper")
local stringUtils = require("Modules.utils.stringUtils")

-- Function to retrieve a voxel from the planes structure
local function getBlock(x, y, context)

    local chunkX = (x-1) % 16;
    local chunkY = (y-1) % 16;

    local isXBorder = chunkX == 0 or chunkX == 15
    local isYBorder = chunkY == 0 or chunkY == 15
    local isBorder = isXBorder or isYBorder
    local isLight = isXBorder and isYBorder

    local isXLightBorder = chunkX == 1 or chunkX == 14
    local isYLightBorder = chunkY == 1 or chunkY == 14
    local lightBorder = isXLightBorder and isYLightBorder

    if(isLight) then
        return context.light_block
    elseif(isBorder or lightBorder) then
        return context.border_block
    else
        return context.floor_block
    end
end

local function myPosUpdate(position, area, context)
    logger.info("New position: X={}, Y={}, Z={}", position.x, position.y, position.z)
    turtle.digDown()

    -- Get the plane and row
    local block = getBlock(position.x, position.y, context)
    if(block == nil) then
        return
    end

    if inventoryWrapper.placeDown(block) then
        logger.info("Placed {} at X={}, Y={}, Z={}", block, position.x, position.y, position.z)
    else
        logger.warn("Failed to place block at X={}, Y={}, Z={}", position.x, position.y, position.z)
    end
end

-- Build the structure
-- Build the structure
local function buildFloor(chunkWidth, chunkLength)
    logger.info("Starting floor build {} x {}", chunkWidth, chunkLength)

    inventoryWrapper.init()
    logger.info("Inventory wrapper initialized.")

    -- Context for traverseHelper
    local context = {
        width = chunkWidth,
        length = chunkLength,
        floor_block = "chipped:inlayed_cobblestone",
        border_block = "chipped:thick_inlayed_blackstone",
        light_block = "minecraft:sea_lantern",
    }

    -- Function to count materials
    local function countMaterials(chunkWidth, chunkLength)
        local materialCounts = {}

        for x = 1, chunkLength * 16 do
            for y = 1, chunkWidth * 16 do
                local position = { x = x, y = y, z = 1 }
                local block = getBlock(position.x, position.y, context) -- Simulate getting the block type

                if block then
                    materialCounts[block] = (materialCounts[block] or 0) + 1
                end
            end
        end

        logger.info("Material counts before building: {}", stringUtils.tableToString(materialCounts))

        -- Display material counts in stacks
        term.clear()
        term.setCursorPos(1, 1)
        print("Materials Needed:")
        local y = 2
        for block, count in pairs(materialCounts) do
            local stacks = math.ceil(count / 64)
            term.setCursorPos(1, y)
            print(string.format("%s: %d stack%s", block, stacks, stacks > 1 and "s" or ""))
            y = y + 1
        end

        -- Pause for user confirmation
        term.setCursorPos(1, y + 2)
        print("Press any key to start building...")
        os.pullEvent("key")
    end

    -- Run material counting phase
    countMaterials(chunkWidth, chunkLength)

    traverseHelper.moveUpDestructive()

    -- Traverse the area and build plane by plane
    traverseHelper.traverseArea(
        chunkLength * 16,
        chunkWidth * 16,
        1,
        myPosUpdate,
        context
    )

    logger.info("Build completed for dimensions: {} x {}", chunkWidth * 16, chunkLength * 16)
end

local args = { ... }

if #args < 2 then
    print("Usage: buildFloor [width] [length] - length / width is in chunks")
    return
end

logger.init(true, true, true, "/buildFloor.log")
logger.runWithLog(function() buildFloor(tonumber(args[1]), tonumber(args[2])) end)
logger.close()