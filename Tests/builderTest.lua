local menu = require("Modules.ui.menulib")
local traverseHelper = require("Modules.traverseHelper")
local inventorywrapper = require("Modules.InventoryWrapper")
local logger = require("Modules.utils.logger")

local lightDistance = 3

function moveNext(x,y)
    turtle.dig()
    turtle.forward()
    turtle.digDown()
    turtle.placeDown()
end

function place(item)
    if inventorywrapper.select(item.name, true) then
        inventorywrapper.placeDown()
    else
        logger.log("we are out of" .. item.name)
    end
end

local function myPosUpdate(position, area, context)

    logger.log("New position: X=" .. position.x .. ", Y=" .. position.y .. ", Z=" .. position.z)
    turtle.digDown()
    
    if(position.z == 1 or position.z == area.z) then
        if(position.x % lightDistance == 0 and position.y % lightDistance == 0) then
            place(context.lightItem)
        else
            place(context.wallItem)
        end
    elseif (position.x == 1 or position.x == area.x) or (position.y == 1 or position.y == area.y) then
        place(context.wallItem)
    end
end

inventorywrapper.init()
logger.init()

local context = {
    wallItem = inventorywrapper.getItemAt(1),
    lightItem = inventorywrapper.getItemAt(2),
    fuelItem = inventorywrapper.getItemAt(3)
}


traverseHelper.traverseArea(5, 8, 6, myPosUpdate, context)
