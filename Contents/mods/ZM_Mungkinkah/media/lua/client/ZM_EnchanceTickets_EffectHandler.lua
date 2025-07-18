-- Enchantment effect handler for client side
local ZM_EnchanceTickets = require "ZM_EnchanceTickets_utils"

-- Keep track of weapons confirmed as enchanted by the server
local confirmedEnchantedWeapons = {}

-- Apply enchantment effects to a weapon based on tier
local function applyEnchantmentEffects(weapon, tier)
    if not weapon or not tier then return false end

    -- Store the original values if not already stored
    if not weapon:getModData().originalMinDamage then
        weapon:getModData().originalMinDamage = weapon:getMinDamage()
        weapon:getModData().originalMaxDamage = weapon:getMaxDamage()
        weapon:getModData().originalMaxHitCount = weapon:getMaxHitCount()
        weapon:getModData().originalMaxRange = weapon:getMaxRange()
    end

    -- Get the original values
    local origMinDamage = weapon:getModData().originalMinDamage
    local origMaxDamage = weapon:getModData().originalMaxDamage
    local origMaxHitCount = weapon:getModData().originalMaxHitCount
    local origMaxRange = weapon:getModData().originalMaxRange

    -- Apply tier-based bonuses
    weapon:setMinDamage(origMinDamage + tier)
    weapon:setMaxDamage(origMaxDamage + tier)

    -- Tier 10 special bonuses
    if tier == 10 then
        weapon:setMaxHitCount(4) -- Set to 4 directly for tier 10
        weapon:setMaxRange(origMaxRange + 1.5)
    end

    -- Save the tier in the weapon's ModData
    weapon:getModData().enchantmentTier = tier

    return true
end

-- Remove ticket from inventory
local function removeTicketFromInventory(player, itemID)
    if not player or not itemID then return false end

    local inventory = player:getInventory()
    if not inventory then return false end

    -- Get all items in inventory
    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getID() == itemID then
            -- Found the ticket, remove it
            inventory:Remove(item)
            return true
        end
    end

    return false
end

-- Handle notification from the server
Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "ZM_EnchanceTickets" then return end

    if command == "NotifyPlayer" then
        -- Show the message to the player
        if args.message then
            local player = getSpecificPlayer(0)
            if player then
                player:Say(args.message)
            end
        end

        -- Handle ticket usage notifications
        if args.ticketWasUsed and args.weaponID and args.enchantmentTier and args.ticketID then
            local player = getSpecificPlayer(0)
            if player then
                -- Record this weapon as confirmed enchanted
                confirmedEnchantedWeapons[args.weaponID] = args.enchantmentTier

                -- Apply the enchantment to the weapon if it's currently equipped
                local weapon = player:getPrimaryHandItem()
                if weapon and tostring(weapon:getID()) == args.weaponID then
                    -- Apply the actual enchantment effects
                    applyEnchantmentEffects(weapon, args.enchantmentTier)

                    -- Add visual indicator
                    local displayName = weapon:getDisplayName() or weapon:getName()
                    -- Remove any existing enchantment indicator
                    displayName = string.gsub(displayName, " %(Tier [IVX]+%)", "")

                    -- Convert number to Roman numeral
                    local tierRoman = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"}
                    local romanTier = tierRoman[args.enchantmentTier] or args.enchantmentTier

                    -- Apply new name
                    weapon:setName(displayName .. " (Tier " .. romanTier .. ")")
                end

                -- Remove the used ticket from inventory
                if args.itemID then
                    removeTicketFromInventory(player, args.itemID)
                end
            end
        end

        -- Handle enchantment check responses
        if args.weaponEnchantmentStatus and args.weaponID then
            if args.isEnchanted and args.enchantmentTier then
                -- Mark this weapon as confirmed enchanted
                confirmedEnchantedWeapons[args.weaponID] = args.enchantmentTier

                -- Apply the enchantment status to the currently equipped weapon if it matches
                local player = getSpecificPlayer(0)
                if player then
                    local weapon = player:getPrimaryHandItem()
                    if weapon and tostring(weapon:getID()) == args.weaponID then
                        -- Apply the actual enchantment effects
                        applyEnchantmentEffects(weapon, args.enchantmentTier)

                        -- Add visual indicator if not already present
                        local displayName = weapon:getDisplayName() or weapon:getName()
                        -- Remove any existing enchantment indicator
                        displayName = string.gsub(displayName, " %(Tier [IVX]+%)", "")

                        -- Convert number to Roman numeral
                        local tierRoman = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"}
                        local romanTier = tierRoman[args.enchantmentTier] or args.enchantmentTier

                        -- Apply new name
                        weapon:setName(displayName .. " (Tier " .. romanTier .. ")")
                    end
                end
            end
        end
    end
end)

-- Apply enchantment effects when a player equips a weapon
Events.OnEquipPrimary.Add(function(player, item)
    if not player or not item then return end

    -- Check if this weapon is in our confirmed enchanted list
    local weaponID = tostring(item:getID())
    local tier = confirmedEnchantedWeapons[weaponID]

    if tier then
        -- Weapon is confirmed enchanted, apply effects
        applyEnchantmentEffects(item, tier)

        -- Add visual indicator if not already present
        local displayName = item:getDisplayName() or item:getName()
        if not string.find(displayName, " %(Tier") then
            -- Remove any existing enchantment indicator first
            displayName = string.gsub(displayName, " %(Tier [IVX]+%)", "")

            -- Convert number to Roman numeral
            local tierRoman = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"}
            local romanTier = tierRoman[tier] or tier

            -- Apply new name
            item:setName(displayName .. " (Tier " .. romanTier .. ")")
        end
    elseif item:getModData().enchantmentTier then
        -- Weapon has local enchantment data but isn't in our confirmed list
        -- This could happen if the server data was reset
        -- Apply the effects anyway based on local data
        applyEnchantmentEffects(item, item:getModData().enchantmentTier)
    end
end)

-- Debug function to check weapon stats
function checkCurrentWeaponEnchantment()
    local player = getSpecificPlayer(0)
    if not player then return "No player found" end

    local weapon = player:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        return "No weapon equipped"
    end

    local tier = weapon:getModData().enchantmentTier or 0
    local minDmg = weapon:getMinDamage()
    local maxDmg = weapon:getMaxDamage()
    local hitCount = weapon:getMaxHitCount()
    local range = weapon:getMaxRange()

    print("Weapon: " .. weapon:getName())
    print("Tier: " .. tier)
    print("Min Damage: " .. minDmg)
    print("Max Damage: " .. maxDmg)
    print("Max Hit Count: " .. hitCount)
    print("Max Range: " .. range)

    return "Checked weapon enchantment, see console for details"
end

-- Register global command for console debugging
_G.CheckWeaponEnchantment = checkCurrentWeaponEnchantment

print("DEBUG: ZM_EnchanceTickets_EffectHandler loaded with damage effects")