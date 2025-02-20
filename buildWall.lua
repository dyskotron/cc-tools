local inventoryWrapper = require("Modules.InventoryWrapper")
local logger = require("Modules.utils.logger")
local traverseHelper = require("Modules.traverseHelper")
local stringUtils = require("Modules.utils.stringUtils")

local function myPosUpdate(position, area, context)
    logger.info("New position: X={}, Y={}, Z={}", position.x, position.y, position.z)
    turtle.digDown()

    if inventoryWrapper.placeDown(context.wall_block) then
        logger.info("Placed {} at X={}, Y={}, Z={}", context.wall_block, position.x, position.y, position.z)
    else
        logger.warn("Failed to place block at X={}, Y={}, Z={}", position.x, position.y, position.z)
    end
end

-- Build the structure
local function buildFloor(chunkWidth, chunkLength, height)
    logger.info("Starting floor build XXX {} x {}", chunkWidth, chunkLength)

    inventoryWrapper.init()
    logger.info("Inventory wrapper initialized.")

    local wall_block = inventoryWrapper.getContentItemName(1)

    local context = {
            width = chunkWidth,
            length = chunkLength,
            wall_block = wall_block
    }

    traverseHelper.moveUpDestructive()

    local sideLength = chunkLength * 16 + 2;

    for z = 1, height do
        traverseHelper.traverseX(sideLength, nil, myPosUpdate, context)
        traverseHelper.traverseY(sideLength, nil, myPosUpdate, context)
        traverseHelper.traverseX(0, nil, myPosUpdate, context)
        traverseHelper.traverseY(0, nil, myPosUpdate, context)
        traverseHelper.traverseZ(1)
    end

    logger.info("Build completed for dimensions: {} x {}", chunkWidth * 16, chunkLength * 16)
end

local args = { ... }

if #args < 2 then
    print("Usage: buildFloor [width] [length] [height] - length / width is in chunks")
    return
end

logger.init(true, true, true, "/buildWall.log")
logger.runWithLog(function() buildFloor(tonumber(args[1]), tonumber(args[2]), tonumber(args[3])) end)
logger.close()