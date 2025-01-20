local menu = require("Modules.ui.menulib")
local logger = require("Modules.utils.logger")

local InventoryWrapper = {}

local inventory = {}
local selectedSlot = 1 -- Track the currently selected slot

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
                shulkerItem = nil, -- Item type inside the shulker box (if applicable)
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

function InventoryWrapper.printInventory()
    print("Inventory Contents:")
    for slot, item in pairs(inventory) do
        if item then
            print(item.name .. "(" .. item.count .. ")")
        end
    end
end

function InventoryWrapper.printShulkers()
    print("Inventory Contents:")
    for slot, item in pairs(inventory) do
        if item then
            if item.shulkerItem then
                print(item.name .. "(" .. item.shulkerItem .. ")")
            end
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

function InventoryWrapper.getShulkerItemName(slot)
    -- Check if the slot exists in the inventory and contains a shulker
    local item = inventory[slot]
    if item and item.shulkerItem then
        return item.shulkerItem -- Return the name of the item inside the shulker
    else
        return nil -- No shulker item in the slot
    end
end

-- Select a slot containing the specified item, optionally loading from shulker boxes
function InventoryWrapper.select(itemName, tryLoadFromShulker)
    -- First, check the inventory for the item
    for slot, item in pairs(inventory) do
        if item.name == itemName then
            if slot ~= selectedSlot then
                turtle.select(slot)
                selectedSlot = slot
            end
            logger.log("InventoryWrapper.select() found item " .. itemName .. " directly in inventory")
            return true
        end
    end

    -- If the item is not found and tryLoadFromShulker is true, load from shulker
    if tryLoadFromShulker then
        logger.log("InventoryWrapper.select() trying to load " .. itemName .. " from shulker")
        if InventoryWrapper.tryLoadFromShulker(itemName) then
            -- Retry selecting the item after loading
            logger.log("InventoryWrapper.select() Retry selecting  " .. itemName .. " after sucesfull loading")
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
        if item.name:find("shulker_box") and item.shulkerItem == itemName and item.shulkerStacks > 0 then
            -- Shulker confirmed, place it, suck the item, and dig it back
            logger.log("InventoryWrapper.select() found item " .. itemName .. " in shulker box")
            return InventoryWrapper.placeAndProcessShulker(slot, {InventoryWrapper.suckUp})
        end
    end

    -- If item not found, lazily check unconfirmed shulkers
    for slot, item in pairs(inventory) do
        if item.name:find("shulker_box") and not item.shulkerItem then
            logger.log("InventoryWrapper.select() checking shulker box")
            if InventoryWrapper.placeAndProcessShulker(slot, {InventoryWrapper.initShulkerData, InventoryWrapper.checkForItem, InventoryWrapper.suckUp}, itemName) then -- need to add the extra param here
                return true
            end
        end
    end

    return false -- No matching shulker box found
end

function InventoryWrapper.placeAndProcessShulker(shulkerSlot, methods, metaData)

    InventoryWrapper.selectSlot(shulkerSlot)

    if not turtle.detectUp() or turtle.digUp() then
        if not turtle.placeUp() then
            print("Unable to place shulker box")
            return false
        end
    end

    local allMethodsSuceeded = true

    local continueProcessing = true -- Flag to track if processing should continue
    for _, method in ipairs(methods) do
        local success = method(shulkerSlot, metaData)
        if not success then
            print("Method failed, skipping further methods.")
            allMethodsSuceeded = false
            break
        end
    end

    InventoryWrapper.selectSlot(shulkerSlot)
    turtle.digUp()
    return allMethodsSuceeded
end

function InventoryWrapper.checkForItem(shulkerSlot, targetItem)
    logger.log("InventoryWrapper.checkForItem() checking shulker content:" .. InventoryWrapper.getShulkerItemName(shulkerSlot) .. "target Item is " .. targetItem)
    return InventoryWrapper.getShulkerItemName(shulkerSlot) == targetItem
end

function InventoryWrapper.suckUp(shulkerSlot)

    local itemSlot = InventoryWrapper.getEmptySlot(shulkerSlot)
    InventoryWrapper.selectSlot(itemSlot)
    -- Suck the items from the shulker box
    if turtle.suckUp() then
        InventoryWrapper.updateSlot(itemSlot)
    else
        logger.log("cant suck from shulker")
    end

    return true
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

    logger.log("InventoryWrapper.initShulkerData() found item in shulker - updating inventory data")
    -- Wrap the shulker box as a peripheral
    --local shulker = peripheral.wrap("top")
    local shulker = InventoryWrapper.wrapShulkerWithRetry(10,0.5)
    if not shulker then
        print("Can't wrap placed shulker")
        print(tostring(peripheral.getNames()))
        print(peripheral.getType("top"))
        print(#peripheral.getNames())
        print(menu.tableToString(peripheral.getNames(), indent))
        exit()
        return false -- Failed to wrap the shulker box
    end

    -- Initialize fullStacks counter
    local fullStacks = 0
    local itemName = "empty"

    -- Iterate through the contents of the shulker box
    local contents = shulker.list()

    for _, stack in pairs(contents) do
        -- If there is any item in the stack, increment the fullStacks counter
        if stack.count > 0 then
            fullStacks = fullStacks + 1
            itemName = stack.name
        end
    end

    -- Only update if there are full stacks in the shulker
    if fullStacks > 0 then
        -- Retrieve the current item from the inventory (preserve its original name and count)
        local currentItem = inventory[shulkerSlot]

        -- Update the shulkerItem and shulkerStacks fields while leaving name and count intact
        currentItem.shulkerItem = itemName -- Name from the first stack in the shulker
        currentItem.shulkerStacks = fullStacks -- Number of full stacks

        -- Update the inventory entry for the shulkerSlot
        inventory[shulkerSlot] = currentItem
    end

    return true -- Successfully updated shulker data
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

-- Place an item and update inventory
function InventoryWrapper.place()
    if turtle.place() then
        updateAfterPlace()
        return true
    end
    return false
end

function InventoryWrapper.placeDown()
    if turtle.placeDown() then
        InventoryWrapper.updateAfterPlace()
        return true
    end
    return false
end

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
                shulkerItem = nil,
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
            inventory[selectedSlot].shulkerItem = itemType
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