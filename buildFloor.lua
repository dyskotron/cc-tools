gpsUtils = require("Modules.gps.gps_utils")
vecUtils = require("Modules.utils.vectorUtils")
traverseHelper = require("Modules.traverseHelper")
stringUtils = require("Modules.utils.stringUtils")
materialMapper = require("Modules.materialMapper")
inventoryWrapper = require("Modules.InventoryWrapper")

local materialMapping

local function posUpdate(transform)
    local x = transform.position.x
    local z = transform.position.z

    local material = materialMapping[1]

    if(x % 8 == 0 and z % 8 == 0) then
        material = materialMapping[2]
    end

    if(x > 20 and x < 27 and z > 20 and z < 27 ) then
        return
    end

    inventoryWrapper.select(material)
    if(turtle.compareDown()) then
        return
    end
    turtle.digDown()
    inventoryWrapper.placeDown(material, false)
end

function logMaterialMapping(materialMapping)
    for slotId, materialName in pairs(materialMapping) do
        if materialName then
            print("Slot " .. slotId .. ": " .. materialName)
        else
            print("Slot " .. slotId .. ": Empty")
        end
    end
end

local args = {...}
height = -59 -- -59 is bedrock level + 1, lowest the turtle can safely mine

if #args == 1 then
    height = tonumber(args[1])
else
    print("Invalid params! Use: buildFloor <height>")

    return
end

print("Moving to chunk origin")

local slotCount = 5
materialMapping = materialMapper.getSlotToMaterialMap(slotCount)
logMaterialMapping(materialMapping)

--local slotId = 2
--local itemName = materialMapping[slotId];
--local itemCount =  inventoryWrapper.GetTotalItemCount(itemName)
--print()


if gpsUtils.faceEast() then
    local globalPos = gpsUtils.locate()
    local chunkPos = gpsUtils.getChunkPos(globalPos)
    local transform = { position = {x=chunkPos.x, y=chunkPos.y, z=chunkPos.z}, rotation = 0 }

    print("Init rotation: " .. transform.rotation)

    traverseHelper.traverseTo(transform, {x=0, y=height, z=0})
    traverseHelper.traverseArea(transform, {x=48,y=height, z=48}, posUpdate)

    --traverseHelper.traverseTo(transform, {x=0, y=height, z=0})
    --traverseHelper.traverseArea(transform, {x=47,y=yTarget, z=47}, posUpdate)

    --traverseHelper.traverseTo(transform, {x=0, y=startY, z=0})
    -- traverseHelper.faceDirection(transform, 0)
end

-- print("diggin up")
-- traverseHelper.traverseArea(16,height,16)