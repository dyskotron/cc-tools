local logger = require("Modules.utils.logger")
local stringUtils = require("Modules.utils.stringUtils")

local InventoryWrapper = {}

local inventory = {}
local selectedSlot = 1 -- Track the currently selected slot

local function place(itemName, placeMethod, autoSelect)
    autoSelect = autoSelect ~= false
    if not autoSelect or InventoryWrapper.select(itemName, true) then
        placeMethod()
        InventoryWrapper.updateAfterPlace()
        return true
    end

    logger.warn("InventoryWrapper: Can't place block with name: " .. itemName)
    return false
end

-- Initialize the inventory table
function InventoryWrapper.init()
    inventory = {}
    selectedSlot = turtle.getSelectedSlot() -- Store the current selected slot
    for slot = 1, 16 do
        local details = turtle.getItemDetail(slot)
        if details then
            inventory[slot] = {
                name = details.name,
                count = details.count,
                shulkerContent = nil, -- Item type inside the shulker box (if applicable)
                shulkerStacks = 0, -- Number of full stacks inside the shulker box
            }
        else
            inventory[slot] = nil
        end
    end
end

function InventoryWrapper.getItemAt(slot)
    if slot < 1 or slot > 16 then
        print("Invalid slot number. Must be between 1 and 16.")
        return nil
    end

    return inventory[slot]
end

-- Get the type of block contained within the specified slot
-- If the slot contains a shulker box, return the type of block it contains
function InventoryWrapper.getContentItemName(slot)
    if slot < 1 or slot > 16 then
        logger.warn("InventoryWrapper.getContentItemName() invalid slot number: " .. slot)
        return nil
    end

    local item = InventoryWrapper.getItemAt(slot)
    if not item then
        logger.info("InventoryWrapper.getContentItemName() slot " .. slot .. " is empty")
        return nil
    end

    if not item.name:find("shulker_box") then
        return item.name
    end

    -- Handle shulker box specifically
    if item.shulkerContent then
        logger.info("InventoryWrapper.getContentItemName() shulker contains: " .. next(item.shulkerContent))
        return next(item.shulkerContent)
    else
        -- Attempt to initialize shulker data if not already done
        logger.info("InventoryWrapper.getContentItemName() shulker content not initialized, checking...")
        if InventoryWrapper.initShulkerData(slot) then
            --reload item
            logger.info("InventoryWrapper.getContentItemName() sucesfully initialized shulker content...")
            item = InventoryWrapper.getItemAt(slot)
            logger.info("InventoryWrapper.getFinalItemName() item data:" .. stringUtils.tableToString(item))
            return next(item.shulkerContent) -- so we dont return table but the value of first item, this whole method needs to go anyways
        else
            logger.warn("InventoryWrapper.getContentItemName() failed to determine shulker content")
            return nil
        end
    end
end

-- Get the first empty slot, excluding the reserved slot
function InventoryWrapper.getEmptySlot(exclude)
    -- Iterate over the inventory slots
    for slot = 1, 16 do
        -- Check if the slot is empty and not the excluded reserved slot
        if not inventory[slot] and slot ~= exclude then
            return slot
        end
    end
    return nil -- Return nil if no empty slot is found
end

function InventoryWrapper.getAnyBlockSlot()
    -- Iterate over the inventory slots
    for slot = 1, 16 do
        -- Check if the slot is empty and not the excluded reserved slot
        if inventory[slot] then
            logger.info("InventoryWrapper:found slot with block: " .. inventory[slot].name)
            return slot
        end
    end
    return nil -- Return nil if no slot with blc
end

-- Aggregate counts of all items across the entire inventory, including shulkers
function InventoryWrapper.GetAllItemCounts()
    logger.info("InventoryWrapper.GetAllItemCounts() aggregating item counts across inventory")

    local itemCounts = {}

    for slot, item in pairs(inventory) do
        -- Initialize any uninitialized shulkers
        if item.name:find("shulker_box") and not item.shulkerContent then
            InventoryWrapper.initShulkerData(slot)
        end

        -- Count items directly in the inventory
        if item.count and item.count > 0 then
            itemCounts[item.name] = (itemCounts[item.name] or 0) + item.count
        end

        -- Count items inside shulkers
        if item.shulkerContent then
            for shulkerItem, count in pairs(item.shulkerContent) do
                itemCounts[shulkerItem] = (itemCounts[shulkerItem] or 0) + count
            end
        end
    end

    return itemCounts -- Return a table of item names and their total counts
end

-- Get the total count of a specific item across the inventory, including shulkers
function InventoryWrapper.GetTotalItemCount(targetItem)
    logger.info("InventoryWrapper.GetTotalItemCount() calculating total count for item: " .. targetItem)

    local totalCount = 0

    InventoryWrapper.InitAllUnknownShulkers()

    for slot, item in pairs(inventory) do
        -- Count items directly in the inventory
        if item.name == targetItem and item.count and item.count > 0 then
            totalCount = totalCount + item.count
        end

        -- Count items inside shulkers
        if item.shulkerContent and item.shulkerContent[targetItem] then
            totalCount = totalCount + item.shulkerContent[targetItem]
        end
    end

    return totalCount -- Return the total count for the specified item
end

function InventoryWrapper.InitAllUnknownShulkers()
    for slot, item in pairs(inventory) do
        if item.name:find("shulker_box") and not item.shulkerContent then
            InventoryWrapper.initShulkerData(slot)
        end
    end
end

function InventoryWrapper.getShulkerContentName(slot)
    -- Check if the slot exists in the inventory and contains a shulker
    local item = inventory[slot]
    if item and item.shulkerContent then
        return item.shulkerContent -- Return the name of the item inside the shulker
    else
        return nil -- No shulker item in the slot
    end
end

-- Select a slot containing the specified item, optionally loading from shulker boxes
function InventoryWrapper.select(itemName, tryLoadFromShulker)
    tryLoadFromShulker = tryLoadFromShulker ~= false
    if inventory[selectedSlot] ~= nil and inventory[selectedSlot].name == itemName and inventory[selectedSlot].count > 0 then
        return true
    end

    -- First, check the inventory for the item
    for slot, item in pairs(inventory) do
        if item.name == itemName then
            if slot ~= selectedSlot then
                turtle.select(slot)
                selectedSlot = slot
            end
            logger.info("InventoryWrapper.select() found item " .. itemName .. " directly in inventory")
            return true
        end
    end

    -- If the item is not found and tryLoadFromShulker is true, load from shulker
    if tryLoadFromShulker then
        logger.info("InventoryWrapper.select() trying to load " .. itemName .. " from shulker")
        if InventoryWrapper.tryLoadFromShulker(itemName) then
            -- Retry selecting the item after loading
            logger.info("InventoryWrapper.select() Retry selecting  " .. itemName .. " after sucesfull loading")
            return InventoryWrapper.select(itemName, false)
        end
    end

    -- Item not found in inventory or shulker boxes
    return false
end

-- Load items of a specific type from a shulker box
function InventoryWrapper.tryLoadFromShulker(itemName)
    -- First, check confirmed shulkers
    for slot, item in pairs(inventory) do
        if item.name:find("shulker_box") and item.shulkerContent == itemName and item.shulkerStacks > 0 then
            -- Shulker confirmed, place it, suck the item, and dig it back
            logger.info("InventoryWrapper.select() found item " .. itemName .. " in shulker box")
            return InventoryWrapper.placeAndProcessShulker(slot, {InventoryWrapper.suckUp})
        end
    end

    -- If item not found, lazily check unconfirmed shulkers
    for slot, item in pairs(inventory) do
        if item.name:find("shulker_box") and not item.shulkerContent then
            logger.info("InventoryWrapper.select() checking shulker box")
            if InventoryWrapper.placeAndProcessShulker(slot, {InventoryWrapper.initPlacedShulkerData, InventoryWrapper.checkForItem, InventoryWrapper.suckUp}, itemName) then -- need to add the extra param here
                return true
            end
        end
    end

    return false -- No matching shulker box found
end

function InventoryWrapper.placeAndProcessShulker(shulkerSlot, methods, metaData)

    logger.info("InventoryWrapper.placeAndProcessShulker")
    InventoryWrapper.selectSlot(shulkerSlot)

    if not turtle.detectUp() or turtle.digUp() then
        if not turtle.placeUp() then
            logger.info("Unable to place shulker box")
            return false
        end
    end

    logger.info("shulker placed")

    local success = true

    for _, method in ipairs(methods) do
        local success = method(shulkerSlot, metaData)
        if not success then
            logger.info("Method failed, skipping further methods.")
            success = false
            break
        end
    end

    InventoryWrapper.selectSlot(shulkerSlot)
    turtle.digUp()
    return success
end

function InventoryWrapper.checkForItem(shulkerSlot, targetItem)
    local shulkerContentName = InventoryWrapper.getShulkerContentName(shulkerSlot);
    local shulkerContent = shulkerContentName or "empty"
    logger.info("InventoryWrapper.checkForItem() checking shulker content:" .. stringUtils.tableToString(shulkerContent) .. "target Item is " .. targetItem)
    return InventoryWrapper.getShulkerContentName(shulkerSlot) == targetItem
end

function InventoryWrapper.suckUp(shulkerSlot, targetItem)
    logger.info("InventoryWrapper.suckUp() attempting to suck up items from shulker slot: " .. shulkerSlot)

    local itemSlot = InventoryWrapper.getEmptySlot(shulkerSlot)
    if not itemSlot then
        logger.error("No empty slot available to suck items from the shulker")
        return false
    end

    InventoryWrapper.selectSlot(itemSlot)

    -- Suck the items from the shulker box
    if turtle.suckUp() then
        local suckedItem = turtle.getItemDetail(itemSlot) -- Get details of the sucked item
        if suckedItem then
            local countSucked = suckedItem.count

            -- Update the inventory slot
            InventoryWrapper.updateSlot(itemSlot)

            -- Update the shulker's content table
            local shulkerData = inventory[shulkerSlot]
            if shulkerData and shulkerData.shulkerContent and shulkerData.shulkerContent[suckedItem.name] then
                shulkerData.shulkerContent[suckedItem.name] = shulkerData.shulkerContent[suckedItem.name] - countSucked

                -- Remove the entry if the count reaches 0
                if shulkerData.shulkerContent[suckedItem.name] <= 0 then
                    shulkerData.shulkerContent[suckedItem.name] = nil
                end
            end

            logger.info("Sucked " .. countSucked .. " of " .. suckedItem.name .. " from shulker")
            return true
        end
    else
        logger.warn("Failed to suck items from shulker")
    end

    return false
end


function InventoryWrapper.wrapShulkerWithRetry(maxRetries, delay)
    local retries = 0
    local shulker = nil

    while retries < maxRetries do
        shulker = peripheral.wrap("top") -- Attempt to wrap the shulker box
        if shulker then
            return shulker -- Successfully wrapped the shulker box
        end

        retries = retries + 1
        sleep(delay) -- Wait before retrying
    end

    print("Failed to wrap the shulker box after " .. maxRetries .. " retries.")
    return nil -- Return nil if wrapping fails
end

function InventoryWrapper.initShulkerData(shulkerSlot)
    logger.info("Initializing shulker in slot " .. shulkerSlot)
    return InventoryWrapper.placeAndProcessShulker(shulkerSlot, {InventoryWrapper.initPlacedShulkerData})
end

function InventoryWrapper.initPlacedShulkerData(shulkerSlot)
    logger.info("InventoryWrapper.initPlacedShulkerData() about to wrap shulker and check contents")

    -- Wrap the shulker box as a peripheral
    local shulker = InventoryWrapper.wrapShulkerWithRetry(10, 0.5)
    if not shulker then
        logger.warn("Can't wrap placed shulker")
        return false
    end

    local shulkerContent = {} -- Table to store item counts
    local contents = shulker.list()

    for _, stack in pairs(contents) do
        if stack.count > 0 then
            shulkerContent[stack.name] = (shulkerContent[stack.name] or 0) + stack.count
        end
    end

    local currentItem = inventory[shulkerSlot]
    currentItem.shulkerContent = shulkerContent -- Full table of item counts
    inventory[shulkerSlot] = currentItem

    return true
end


-- Ensure slot selection is always tracked
function InventoryWrapper.selectSlot(slot)
    if slot >= 1 and slot <= 16 then
        if slot ~= selectedSlot then
            turtle.select(slot)
            selectedSlot = slot
        end
    else
        error("Invalid slot number: " .. slot)
    end
end

function InventoryWrapper.place(itemName, autoSelect) return place(itemName, turtle.place, autoSelect) end
function InventoryWrapper.placeDown(itemName, autoSelect) return place(itemName, turtle.placeDown, autoSelect) end
function InventoryWrapper.placeUp(itemName, autoSelect) return place(itemName, turtle.placeUp, autoSelect) end

function InventoryWrapper.updateAfterPlace()
    if inventory[selectedSlot] then
        inventory[selectedSlot].count = inventory[selectedSlot].count - 1
        if inventory[selectedSlot].count <= 0 then
            inventory[selectedSlot] = nil
        end
    end
end

-- Update inventory after sucking items
function InventoryWrapper.updateSlot(slot)
    local details = turtle.getItemDetail(slot)
    if details then
        if inventory[slot] then
            inventory[slot].count = details.count
        else
            inventory[slot] = {
                name = details.name,
                count = details.count,
                shulkerContent = nil,
                shulkerStacks = 0,
            }
        end
    else
        inventory[slot] = nil
    end
end

-- Access a shulker box and track its contents
function InventoryWrapper.accessShulker()
    if inventory[selectedSlot] and inventory[selectedSlot].name:find("shulker_box") then
        if turtle.place() then
            -- Calculate how many full stacks were inside
            local stacks = 0
            local itemType = nil

            for slot = 1, 16 do
                local details = turtle.getItemDetail(slot)
                if details then
                    stacks = stacks + 1
                    itemType = details.name
                end
            end

            -- Update the shulker box's contents
            inventory[selectedSlot].shulkerContent = itemType
            inventory[selectedSlot].shulkerStacks = stacks

            -- Dig the shulker box back up
            if turtle.dig() then
                return true
            end
        end
    end
    return false
end

-- Wrapper for suck and dig to ensure inventory stays updated
function InventoryWrapper.suck()
    if turtle.suck() then
        InventoryWrapper.updateAfterSuck()
        return true
    end
    return false
end

function InventoryWrapper.dig()
    if turtle.dig() then
        InventoryWrapper.updateAfterSuck()
        return true
    end
    return false
end

return InventoryWrapper