-- Global mod data key
local MOD_ID = "ZM_EnchanceTickets"

-- Create a server-side data storage for enchantment tickets
local ServerTicketData = {}
ServerTicketData.enchantments = {}
ServerTicketData.loaded = true

    -- Add a new weapon enchantment
addEnchantment = function(ticketID, weaponID, tier)
    ServerTicketData.enchantments[ticketID] = {
        weaponID = weaponID,
        tier = tier
    }
    return true
end,

-- Check if a weapon is already enchanted
isWeaponEnchanted = function(weaponID)
    for ticketID, data in pairs(ServerTicketData.enchantments) do
        if data.weaponID == weaponID then
            return true, data.tier, ticketID
        end
    end
    return false, 0, nil
end,

-- Remove an enchantment
removeEnchantment = function(ticketID)
    if ServerTicketData.enchantments[ticketID] then
        ServerTicketData.enchantments[ticketID] = nil
        return true
    end
    return false
end


local function onUseTicketOnWeapon(player, args)
    if not player or not args then
        return
    end
    print("DEBUG: onUseTicketOnWeapon called with args:", args)
    local ticketID = args.ticketID
    local ticketTier = args.ticketTier
    local weaponID = args.weaponID

    if not ticketID or not weaponID or not ticketTier then
        return
    end

    -- Check if ServerTicketData is properly initialized
    if not ServerTicketData or not ServerTicketData.enchantments then
        sendServerCommand(player, "ZM_EnchanceTickets", "NotifyPlayer", {message = "Error: Could not access enchantment data."})
        return
    end

    -- Check if this EXACT ticket is already used
    if ServerTicketData.enchantments and ServerTicketData.enchantments[ticketID] then
        sendServerCommand(player, "ZM_EnchanceTickets", "NotifyPlayer", {message = "This ticket has already been used."})
        return
    end

    print("SAMPE TENGAAAAAAAAAAAAAAAAAH")

    -- Register the ticket and weapon IDs
    addEnchantment(ticketID, weaponID, ticketTier)
    -- Notify the player - include ticketWasUsed flag for client to handle ticket removal
    sendServerCommand(player, "ZM_EnchanceTickets", "NotifyPlayer", {
        message = "The ticket has been successfully used to enchant your weapon with tier " .. ticketTier .. ".",
        ticketWasUsed = true,
        ticketID = ticketID,
        itemID = args.itemID,  -- Pass the actual item ID for removal
        weaponID = weaponID,
        enchantmentTier = ticketTier
    })

    print("DEBUG: SAMPE SINI GAAAAAAAAAAAAAAN")
    -- SHOULD CHECK THE EXISTING ENCHANTMENT




end

local function onCheckWeaponEnchantment(player, args)
    if not player or not args then return end

    local weaponID = args.weaponID

    if not weaponID then
        return
    end

    -- Check if weapon is enchanted
    local isEnchanted, tier, ticketID = ServerTicketData.isWeaponEnchanted(weaponID)

    -- Send message to player
    if isEnchanted then
        sendServerCommand(player, "ZM_EnchanceTickets", "NotifyPlayer", {
            message = "This weapon has a tier " .. tier .. " enchantment.",
            weaponEnchantmentStatus = true,
            isEnchanted = true,
            weaponID = weaponID,
            enchantmentTier = tier,
            ticketID = ticketID
        })
    else
        sendServerCommand(player, "ZM_EnchanceTickets", "NotifyPlayer", {
            message = "This weapon is not enchanted.",
            weaponEnchantmentStatus = true,
            isEnchanted = false,
            weaponID = weaponID
        })
    end
end

-- Hook into the OnClientCommand event for server-side handling
Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "ZM_EnchanceTickets" then
        if command == "UseTicketOnWeapon" then
            pcall(function() onUseTicketOnWeapon(player, args) end)
        elseif command == "CheckWeaponEnchantment" then
            pcall(function() onCheckWeaponEnchantment(player, args) end)
        end
    end
end)

-- Clean up any invalid enchantments periodically
Events.EveryHours.Add(function()
    -- Nothing to do if not initialized
    if not ServerTicketData or not ServerTicketData.loaded then return end
    if not ServerTicketData.enchantments then return end

    -- Future cleanup logic can be added here if needed
end)

print("DEBUG: ServerEnchanceTicketsHandler loaded")