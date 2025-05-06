-- Simple test script to diagnose weapon damage boost issues
local DAMAGE_BOOST = 3

function ZM_TestWeaponDamage()
    local player = getSpecificPlayer(0)
    if not player then return "No player found" end

    local weapon = player:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        return "No weapon equipped"
    end

    local minBefore = weapon:getMinDamage()
    local maxBefore = weapon:getMaxDamage()

    weapon:getModData().origMinDamage = minBefore
    weapon:getModData().origMaxDamage = maxBefore

    weapon:setMinDamage(minBefore + DAMAGE_BOOST)
    weapon:setMaxDamage(maxBefore + DAMAGE_BOOST)

    weapon:getModData().hasDamageBoost = true

    local minAfter = weapon:getMinDamage()
    local maxAfter = weapon:getMaxDamage()

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

_G.TestWeaponDamage = ZM_TestWeaponDamage

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
        return ZM_TestWeaponDamage()
    end
end

_G.ToggleWeaponDamage = ZM_ToggleWeaponDamage

print("DEBUG: Damage testing tools loaded! Use TestWeaponDamage() or ToggleWeaponDamage() in console")