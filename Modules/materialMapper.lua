local logger = require("Modules.utils.logger")
local inventoryWrapper = require("Modules.InventoryWrapper")
local MaterialMapper = {}

function MaterialMapper.getSlotToMaterialMap(slotCount)
    inventoryWrapper.init()
    -- Map slot IDs to materials
    local materialMapping = {}
    for i = 1, slotCount do
        local fullName = inventoryWrapper.getContentItemName(i)
        if fullName then
            materialMapping[i] = fullName
        else
            logger.warn("No item found in slot " .. i)
            materialMapping[i] = nil -- Or set a fallback material if desired
        end
    end
    return materialMapping;
end

return MaterialMapper
