-- Context Menu for Enchantment Tickets
local ZM_EnchanceTickets = require "ZM_EnchanceTickets_utils"

-- Function to handle the "Use Ticket To Weapon" action
function ZM_EnchanceTickets.UseTicketOnWeapon(playerObj, item)
    local player = playerObj
    if type(playerObj) == "number" then
        player = getSpecificPlayer(playerObj)
    end

    if not player then
        print("ERROR: Player is nil in UseTicketOnWeapon.")
        return
    end

    if not item then
        print("ERROR: Item is nil in UseTicketOnWeapon.")
        return
    end

    print("DEBUG: Starting ticket enchantment process...")

    local weapon = player:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        player:Say("You need to hold a weapon to use the enchantment ticket.")
        return
    end

    player:Say("Attempting to enchant weapon...")

    -- Generate a unique ticket ID to prevent duplication
    local ticketID = item:getType()

    -- If the item has a unique ID already, use it
    if item:getModData().ticketUniqueID then
        ticketID = ticketID .. "_" .. item:getModData().ticketUniqueID
    else
        -- If no unique ID exists, create one based on item properties and add it to the ticket
        -- Use condition and other properties to create a unique fingerprint
        local uniquePart = tostring(item:getCondition() or 0) .. "_" .. tostring(item:getID() or "0")
        item:getModData().ticketUniqueID = uniquePart
        ticketID = ticketID .. "_" .. uniquePart
    end

    local ticketTier = ZM_EnchanceTickets.GetTicketTier(item)

    print("DEBUG: Generated ticketID: " .. tostring(ticketID) .. ", Tier: " .. ticketTier)

    -- Send command to handle enchantment process
    print("DEBUG: Sending client command: UseTicketOnWeapon")
    sendClientCommand(player, "ZM_EnchanceTickets", "UseTicketOnWeapon", {
        ticketID = ticketID,
        ticketTier = ticketTier,
        itemID = item:getID(),  -- Send the actual item ID so server can verify
        inventoryIndex = item:getContainer():getItems():indexOf(item), -- For later removal
        weaponID = tostring(weapon:getID())
    })
    player:Say("Executed completely")
end

-- Function to add the custom context menu option
local function addEnchanceTicketContextMenu(player, context, items)
    if not context or not items then return end

    -- Get the local player for the context menu
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return end

    -- Check if player has a weapon equipped
    local weapon = playerObj:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        return
    end

    for _, v in ipairs(items) do
        local item = v
        if not instanceof(v, "InventoryItem") and v.items and v.items[1] then
            item = v.items[1]
        end

        -- Check if the item is an Enchantment Ticket
        if item and instanceof(item, "InventoryItem") and ZM_EnchanceTickets.IsEnchantmentTicket(item) then
            -- Check if this ticket is already used (server will double-check)
            if not item:getModData().isUsed then
                -- Pass the player index (0) - our function will convert it to an object
                context:addOption("Use Ticket To Weapon", 0, ZM_EnchanceTickets.UseTicketOnWeapon, item)
            else
                local option = context:addOption("Already Used", nil)
                option.notAvailable = true
            end
        end
    end
end

-- Add context menu option to check weapon enchantment
local function addCheckEnchantmentContextMenu(player, context, items)
    -- Get the local player
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return end

    -- Add the context menu option for weapons
    local weapon = playerObj:getPrimaryHandItem()
    if weapon and weapon:IsWeapon() then
        context:addOption("Check Enchantment", playerObj, function()
            ZM_EnchanceTickets.CheckEquippedWeaponEnchantment()
        end)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addEnchanceTicketContextMenu)
Events.OnFillInventoryObjectContextMenu.Add(addCheckEnchantmentContextMenu)
Events.OnFillWorldObjectContextMenu.Add(addCheckEnchantmentContextMenu)

return ZM_EnchanceTickets