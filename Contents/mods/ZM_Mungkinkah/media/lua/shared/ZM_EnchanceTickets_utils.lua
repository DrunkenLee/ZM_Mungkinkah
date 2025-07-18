-- Shared Enchantment Tickets Utilities
ZM_EnchanceTickets = {}

-- Useful constants and shared functions
ZM_EnchanceTickets.MOD_ID = "ZM_EnchanceTickets"
ZM_EnchanceTickets.ITEM_TYPES = {
    "ZM_EnchanceTicket1", "ZM_EnchanceTicket2", "ZM_EnchanceTicket3",
    "ZM_EnchanceTicket4", "ZM_EnchanceTicket5", "ZM_EnchanceTicket6",
    "ZM_EnchanceTicket7", "ZM_EnchanceTicket8", "ZM_EnchanceTicket9",
    "ZM_EnchanceTicket10"
}

-- Function to check if an item is an enchantment ticket
function ZM_EnchanceTickets.IsEnchantmentTicket(item)
    if not item then return false end
    local itemType = item:getType()
    for _, ticketType in ipairs(ZM_EnchanceTickets.ITEM_TYPES) do
        if itemType == ticketType then
            return true
        end
    end
    return false
end

-- Function to get ticket tier from ticket item
function ZM_EnchanceTickets.GetTicketTier(item)
    if not item then return 0 end
    local itemType = item:getType()
    for i, ticketType in ipairs(ZM_EnchanceTickets.ITEM_TYPES) do
        if itemType == ticketType then
            return i
        end
    end
    return 0
end

-- Function to check if a weapon has a ticket enhancement (local check)
function ZM_EnchanceTickets.IsWeaponEnchanted(weapon)
    if not weapon then return false end
    return weapon:getModData().enchantmentTier ~= nil
end

-- Function to get the enchantment tier for a weapon (local check)
function ZM_EnchanceTickets.GetWeaponEnchantmentTier(weapon)
    if not weapon then return 0 end
    return weapon:getModData().enchantmentTier or 0
end

-- Function to check enhancement status for equipped weapon (sends request to server)
function ZM_EnchanceTickets.CheckEquippedWeaponEnchantment()
    local player = getSpecificPlayer(0)
    if not player then return false end

    local weapon = player:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        player:Say("You need to hold a weapon to check its enchantment status.")
        return false
    end

    -- If we have local data, use that for a quick check
    if weapon:getModData().enchantmentTier then
        local tier = weapon:getModData().enchantmentTier
        player:Say("This weapon has a Tier " .. tier .. " enchantment.")
        return true
    end

    sendClientCommand(player, "ZM_EnchanceTickets", "CheckWeaponEnchantment", {
        weaponID = tostring(weapon:getID())
    })

    return true
end

return ZM_EnchanceTickets