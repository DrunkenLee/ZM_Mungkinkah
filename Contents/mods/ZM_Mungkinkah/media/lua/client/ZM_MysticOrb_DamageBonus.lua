-- Simple and efficient damage boost for weapons bound with mystic orbs
local DAMAGE_BOOST = 3 -- Amount to increase min and max damage

-- Keep track of weapons confirmed as bound by the server
local confirmedBoundWeapons = {}

-- Apply damage boost to a weapon
local function applyDamageBoost(weapon)
    if not weapon or not weapon:IsWeapon() then return false end

    local weaponID = tostring(weapon:getID())

    -- Only apply boost if:
    -- 1. The weapon has a weaponID in its ModData
    -- 2. OR the weapon's ID is in our confirmed bound weapons table
    if weapon:getModData().weaponID or confirmedBoundWeapons[weaponID] then
        -- If we have a server confirmation, store it in the weapon's ModData
        if confirmedBoundWeapons[weaponID] and not weapon:getModData().weaponID then
            weapon:getModData().weaponID = weaponID
        end

        -- Get current values as explicit numbers
        local origMin = tonumber(weapon:getMinDamage())
        local origMax = tonumber(weapon:getMaxDamage())

        -- Fallback to 0 if somehow not a number
        if not origMin then origMin = 0 end
        if not origMax then origMax = 0 end

        -- Store original values if not already stored
        if not weapon:getModData().origMinDamage then
            weapon:getModData().origMinDamage = origMin
            weapon:getModData().origMaxDamage = origMax
        else
            -- Use stored original values
            origMin = weapon:getModData().origMinDamage
            origMax = weapon:getModData().origMaxDamage
        end

        -- Check if boost needs to be applied/reapplied
        local currentMin = weapon:getMinDamage()
        local currentMax = weapon:getMaxDamage()

        -- Calculate target values
        local targetMin = origMin + DAMAGE_BOOST
        local targetMax = origMax + DAMAGE_BOOST

        -- Only apply if needed
        if currentMin ~= targetMin or currentMax ~= targetMax then
            -- Apply the boost
            weapon:setMinDamage(targetMin)
            weapon:setMaxDamage(targetMax)

            -- Add visual indicator if not already present
            local displayName = weapon:getDisplayName() or weapon:getName()
            if not string.find(displayName, " %(Enhanced%)") then
                weapon:setName(displayName .. " (Enhanced)")
            end

            -- Mark as having boost
            weapon:getModData().hasDamageBoost = true

            return true
        end
    end
    return false
end

-- Cache for weapons we've already checked (by ID) to avoid repeated checks
local checkedWeapons = {}

-- Check a weapon only if we haven't checked it before
local function checkIfNeeded(weapon)
    if not weapon or not weapon:IsWeapon() then return end
    local weaponId = weapon:getID()

    -- Skip if we've checked this recently and it's not a confirmed bound weapon
    if checkedWeapons[weaponId] and not confirmedBoundWeapons[weaponId] then return end

    -- Mark as checked
    checkedWeapons[weaponId] = true

    -- If this weapon isn't confirmed bound and doesn't have weaponID in ModData,
    -- request a check from the server
    if not confirmedBoundWeapons[weaponId] and not weapon:getModData().weaponID then
        -- Check with server if this weapon is bound
        local player = getSpecificPlayer(0)
        if player then
            sendClientCommand(player, "ZM_MysticOrb", "CheckWeaponBinding", {
                weaponID = weaponId
            })
        end
    else
        -- Try to apply damage boost immediately if we already know it's bound
        applyDamageBoost(weapon)
    end
end

-- Listen for server notifications about weapon binding
Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "ZM_MysticOrb" then return end

    if command == "NotifyPlayer" then
        -- Handle binding notifications
        if args.orbWasBound then
            local player = getSpecificPlayer(0)
            if player then
                local weapon = player:getPrimaryHandItem()
                if weapon then
                    -- Record this weapon as confirmed bound
                    local weaponId = tostring(weapon:getID())
                    confirmedBoundWeapons[weaponId] = true
                    -- Apply the damage boost
                    applyDamageBoost(weapon)
                end
            end
        end

        -- Handle binding check responses
        if args.weaponBindingStatus then
            if args.isBound and args.weaponID then
                -- Mark this weapon as confirmed bound
                confirmedBoundWeapons[args.weaponID] = true

                -- Try to apply boost if this is the currently equipped weapon
                local player = getSpecificPlayer(0)
                if player then
                    local weapon = player:getPrimaryHandItem()
                    if weapon and tostring(weapon:getID()) == args.weaponID then
                        applyDamageBoost(weapon)
                    end
                end
            end
        end
    end
end)

-- Standard event handlers
Events.OnEquipPrimary.Add(function(player, weapon)
    if weapon and player:isLocalPlayer() then
        checkIfNeeded(weapon)
    end
end)

Events.OnGameStart.Add(function()
    -- Reset caches on game start
    checkedWeapons = {}

    local player = getSpecificPlayer(0)
    if player then
        local weapon = player:getPrimaryHandItem()
        if weapon then
            checkIfNeeded(weapon)
        end
    end
end)

-- Utility function for debug/testing
function checkCurrentWeaponBonus()
    local player = getSpecificPlayer(0)
    if not player then return "No player found" end

    local weapon = player:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        return "No weapon equipped"
    end

    local weaponId = tostring(weapon:getID())
    local isConfirmedBound = confirmedBoundWeapons[weaponId] and "Yes" or "No"
    local hasLocalMark = weapon:getModData().weaponID and "Yes" or "No"

    checkIfNeeded(weapon)

    return "Weapon: " .. weapon:getName() ..
           "\nWeapon ID: " .. weaponId ..
           "\nConfirmed bound by server: " .. isConfirmedBound ..
           "\nLocal binding mark: " .. hasLocalMark
end

-- Register global command for console
_G.CheckWeaponBonus = checkCurrentWeaponBonus

-- Apply boost during combat events
Events.OnWeaponSwingHitPoint.Add(function(character, weapon)
    if character:isLocalPlayer() and weapon then
        applyDamageBoost(weapon)
    end
end)

Events.OnWeaponSwing.Add(function(character, weapon)
    if character:isLocalPlayer() and weapon then
        applyDamageBoost(weapon)
    end
end)

Events.OnWeaponHitCharacter.Add(function(wielder, target, weapon, damage)
    if wielder:isLocalPlayer() and weapon then
        applyDamageBoost(weapon)
    end
end)

-- Periodic check to ensure boosts remain applied
Events.OnPlayerUpdate.Add(function(player)
    if player:isLocalPlayer() and getTimestampMs() % 1000 < 20 then
        local weapon = player:getPrimaryHandItem()
        if weapon and weapon:IsWeapon() then
            applyDamageBoost(weapon)
        end
    end
end)

print("DEBUG: Improved Mystic Orb damage boost system loaded!")