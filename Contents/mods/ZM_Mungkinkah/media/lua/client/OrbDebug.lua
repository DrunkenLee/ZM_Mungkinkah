-- Simple test script to diagnose weapon damage boost issues
local DAMAGE_BOOST = 3

-- Force apply and test damage boost for debugging
function ZM_TestWeaponDamage()
    local player = getSpecificPlayer(0)
    if not player then return "No player found" end

    local weapon = player:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        return "No weapon equipped"
    end

    -- Show current damage values
    local minBefore = weapon:getMinDamage()
    local maxBefore = weapon:getMaxDamage()

    -- Store for reference
    weapon:getModData().origMinDamage = minBefore
    weapon:getModData().origMaxDamage = maxBefore

    -- Apply the boost directly
    weapon:setMinDamage(minBefore + DAMAGE_BOOST)
    weapon:setMaxDamage(maxBefore + DAMAGE_BOOST)

    -- Mark as boosted
    weapon:getModData().hasDamageBoost = true

    -- Check if the change took effect
    local minAfter = weapon:getMinDamage()
    local maxAfter = weapon:getMaxDamage()

    -- Add visual indicator to name
    local displayName = weapon:getDisplayName() or weapon:getName()
    if not string.find(displayName, " %(Enhanced%)") then
        weapon:setName(displayName .. " (Enhanced)")
    end

    -- Return detailed info
    return "Weapon: " .. weapon:getName() ..
           "\nDamage before: " .. minBefore .. "-" .. maxBefore ..
           "\nDamage after: " .. minAfter .. "-" .. maxAfter ..
           "\nDifference: +" .. (minAfter - minBefore) .. "/+" .. (maxAfter - maxBefore)
end

-- Register global function for console testing
_G.TestWeaponDamage = ZM_TestWeaponDamage

-- Create a toggle function to turn damage on/off
function ZM_ToggleWeaponDamage()
    local player = getSpecificPlayer(0)
    if not player then return "No player found" end

    local weapon = player:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        return "No weapon equipped"
    end

    if weapon:getModData().hasDamageBoost then
        -- Restore original values
        if weapon:getModData().origMinDamage and weapon:getModData().origMaxDamage then
            weapon:setMinDamage(weapon:getModData().origMinDamage)
            weapon:setMaxDamage(weapon:getModData().origMaxDamage)
        end
        weapon:getModData().hasDamageBoost = nil

        -- Remove enhanced tag from name
        local displayName = weapon:getDisplayName() or weapon:getName()
        displayName = displayName:gsub(" %(Enhanced%)", "")
        weapon:setName(displayName)

        return "Removed damage boost from " .. weapon:getName()
    else
        -- Apply boost if not already applied
        return ZM_TestWeaponDamage()
    end
end

-- Register toggle function
_G.ToggleWeaponDamage = ZM_ToggleWeaponDamage

print("DEBUG: Damage testing tools loaded! Use TestWeaponDamage() or ToggleWeaponDamage() in console")