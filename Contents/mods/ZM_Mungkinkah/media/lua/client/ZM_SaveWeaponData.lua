ZM_SaveWeaponData = {}

function ZM_SaveWeaponData.SaveEquippedWeaponData(saveName, forceOverwrite)
    -- Get the local player
    local player = getSpecificPlayer(0)
    if not player then return nil end

    if not saveName or saveName == "" then
        getPlayer():Say("I need to provide save name for this weapon.")
        return nil
    end

    -- Get the equipped weapon
    local weapon = player:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        print("[ZM_SaveWeaponData] No weapon equipped")
        return nil
    end

    -- Generate a unique identifier for this save
    -- Format: "saveName_weaponType_timestamp"
    local timestamp = math.floor(getGameTime():getWorldAgeHours() * 100)
    local uniqueID = saveName .. "_" .. weapon:getType() .. "_" .. timestamp

    -- Extract weapon data
    local weaponData = {
        weaponID = weapon:getID(),
        weaponName = weapon:getName(),
        minDamage = weapon:getMinDamage(),
        maxDamage = weapon:getMaxDamage(),
        boundToOrb = false, -- Default value
        weaponType = weapon:getType(),
        originalName = weapon:getModData().enchantmentStats and
                      weapon:getModData().enchantmentStats.originalName or weapon:getName(),
        enchantLevel = weapon:getModData().enchantmentStats and
                      weapon:getModData().enchantmentStats.enchantCounter or 0,
        customName = weapon:getName(),
        saveName = saveName,
        uniqueID = uniqueID,  -- Store the unique ID
        timestamp = timestamp  -- Store the timestamp for sorting
    }

    print("[ZM_SaveWeaponData] Saving weapon data with unique ID: " .. uniqueID)

    -- Check if weapon is bound to orb
    if ZM_MysticOrb and ZM_MysticOrb.CheckEquippedWeaponBinding then
        weaponData.boundToOrb = true
        print("[ZM_SaveWeaponData] Bound to orb: " .. tostring(weaponData.boundToOrb))
    else
        weaponData.boundToOrb = weapon:getModData().boundToOrb or false
    end

    -- Store in weapon's ModData for local reference
    if not weapon:getModData().savedData then
        weapon:getModData().savedData = {}
    end

    weapon:getModData().savedData = weaponData
    print("[ZM_SaveWeaponData] Saved local weapon data for: " .. weaponData.weaponName)

    -- Send to server for permanent storage
    sendClientCommand("EnchantWeapon", "saveEnchantmentData", {
        weaponID = weaponData.weaponID,
        weaponType = weaponData.weaponType,
        minDamage = weaponData.minDamage,
        maxDamage = weaponData.maxDamage,
        enchantLevel = weaponData.enchantLevel,
        isPositive = weapon:getModData().enchantments and
                    (weapon:getModData().enchantments.minDamage or false),
        originalName = weaponData.originalName,
        customName = weaponData.weaponName,
        boundToOrb = weaponData.boundToOrb,
        saveName = weaponData.saveName,
        uniqueID = uniqueID,
        timestamp = timestamp
    })

    player:Say("Weapon saved as '" .. saveName .. "'")
    print("[ZM_SaveWeaponData] Sent weapon data to server with unique ID: " .. uniqueID)
    return weaponData
end

-- Apply saved weapon data to currently equipped weapon using its save name
function ZM_SaveWeaponData.ApplyWeaponDataBySaveName(saveName, callback)
    -- Get the local player
    local player = getSpecificPlayer(0)
    if not player then
        if callback then callback(false) end
        return false
    end

    -- Get the equipped weapon
    local weapon = player:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        print("[ZM_SaveWeaponData] No weapon equipped")
        if callback then callback(false) end
        return false
    end

    -- Get the player's username
    local username = player:getUsername()
    if not username then
        print("[ZM_SaveWeaponData] Couldn't get player username")
        if callback then callback(false) end
        return false
    end

    print("[ZM_SaveWeaponData] Applying saved data '" .. saveName .. "' to equipped weapon...")

    -- Request weapon data from server
    ZM_GetWeaponData.GetWeaponBySaveName(username, saveName, function(weaponData)
        if not weaponData then
            print("[ZM_SaveWeaponData] Failed to find weapon data for saveName: " .. saveName)
            if callback then callback(false) end
            return
        end

        -- Apply stats to local weapon
        if not weapon:getModData().enchantmentStats then
            weapon:getModData().enchantmentStats = {}
        end

        -- Store original name if not already stored
        if not weapon:getModData().enchantmentStats.originalName then
            weapon:getModData().enchantmentStats.originalName = weapon:getName()
        end

        -- Apply enchantment stats
        weapon:getModData().enchantmentStats.enchantCounter = weaponData.enchantLevel or 0

        -- Update weapon damage
        if weaponData.minDamage then weapon:setMinDamage(weaponData.minDamage) end
        if weaponData.maxDamage then weapon:setMaxDamage(weaponData.maxDamage) end

        -- Update weapon name if custom name exists
        if weaponData.customName and weaponData.customName ~= "" then
            weapon:setName(weaponData.customName)
        end

        -- Update binding status
        weapon:getModData().boundToOrb = weaponData.boundToOrb or false

        -- Mark as modified
        weapon:getModData().isEnchanted = true

        -- Store the applied weaponData for reference
        weapon:getModData().appliedWeaponData = weaponData

        -- Send server command to sync this change
        sendClientCommand("EnchantWeapon", "applyEnchantment", {
            targetID = weapon:getID(),
            weaponID = weaponData.weaponID,
            saveName = saveName,
            minDamage = weaponData.minDamage,
            maxDamage = weaponData.maxDamage,
            enchantLevel = weaponData.enchantLevel,
            customName = weaponData.customName,
            boundToOrb = weaponData.boundToOrb
        })

        -- Apply visual effects if needed
        if ZM_WeaponVisuals and ZM_WeaponVisuals.ApplyVisualEffects then
            ZM_WeaponVisuals.ApplyVisualEffects(weapon, weaponData.enchantLevel or 0)
        end

        print("[ZM_SaveWeaponData] Applied weapon data successfully: " .. saveName)
        player:Say("I feel the power flowing into my weapon...")

        -- Play enchantment sound
        if weaponData.enchantLevel and weaponData.enchantLevel > 0 then
            -- Send sound command to server to broadcast
            sendClientCommand("ZM_Mungkinkah", "PlayWorldSound", {
                x = player:getX(),
                y = player:getY(),
                z = player:getZ(),
                radius = 20,
                volume = 10,
                sound = "enchant_success"
            })
        end

        -- Trigger successful callback
        if callback then callback(true) end
    end)

    return true
end

-- Return the module
return ZM_SaveWeaponData