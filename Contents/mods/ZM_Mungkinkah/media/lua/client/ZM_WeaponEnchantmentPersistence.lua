-- Weapon Enchantment Persistence System
-- Fixes the issue with ranged weapons losing enchantment data when changing magazine types

local WeaponEnchantPersistence = {}
WeaponEnchantPersistence.trackedWeapons = {}
WeaponEnchantPersistence.lastCheckTime = 0
WeaponEnchantPersistence.checkInterval = 2 -- in game minutes
WeaponEnchantPersistence.lastCheckedWeaponID = nil

-- Get a unique identifier for a weapon that persists across magazine changes
local function getWeaponIdentifier(weapon)
    if not weapon then return nil end

    -- Use properties that should remain consistent
    local fullType = weapon:getFullType()
    local condition = weapon:getCondition()
    local baseName = "unknown"

    -- Get original name if available in enchantment data
    if weapon:getModData() and weapon:getModData().enchantmentStats and
       weapon:getModData().enchantmentStats.originalName then
        baseName = weapon:getModData().enchantmentStats.originalName
    else
        baseName = weapon:getName() or "unknown"
    end

    return fullType .. "_" .. baseName .. "_" .. condition
end

-- Save enchantment data from a weapon
local function saveWeaponEnchantmentData(weapon)
    if not weapon or not weapon:IsWeapon() then return end

    -- Only track weapons with enchantment data
    if not weapon:getModData() or
       (not weapon:getModData().enchantmentStats and not weapon:getModData().savedDamageValues) then
        return
    end

    local identifier = getWeaponIdentifier(weapon)
    if not identifier then return end

    print("[ZM_WeaponEnchantPersistence] Saving enchantment data for: " .. (weapon:getName() or "Unknown"))

    -- Store all relevant data
    WeaponEnchantPersistence.trackedWeapons[identifier] = {
        enchantmentStats = weapon:getModData().enchantmentStats,
        savedDamageValues = weapon:getModData().savedDamageValues,
        lastSeen = getGameTime():getWorldAgeHours(),
        weaponID = weapon:getID(),
        fullType = weapon:getFullType(),
        name = weapon:getName(),
        minDamage = weapon:getMinDamage(),
        maxDamage = weapon:getMaxDamage()
    }
end

-- Restore enchantment data to a weapon
local function restoreWeaponEnchantmentData(weapon)
    if not weapon or not weapon:IsWeapon() then return false end

    local identifier = getWeaponIdentifier(weapon)
    if not identifier then return false end

    local savedData = WeaponEnchantPersistence.trackedWeapons[identifier]
    if not savedData then return false end

    -- Update last seen time
    savedData.lastSeen = getGameTime():getWorldAgeHours()

    -- Check if this is the same weapon instance (no restoration needed)
    if weapon:getID() == savedData.weaponID and
       weapon:getModData() and weapon:getModData().enchantmentStats then
        return false
    end

    print("[ZM_WeaponEnchantPersistence] Restoring enchantment data to: " .. (weapon:getName() or "Unknown"))

    -- Restore enchantment stats
    if savedData.enchantmentStats then
        weapon:getModData().enchantmentStats = savedData.enchantmentStats

        -- Update weapon name if needed
        if savedData.name and savedData.name ~= weapon:getName() then
            weapon:setName(savedData.name)
        end
    end

    -- Restore damage values
    if savedData.savedDamageValues then
        weapon:getModData().savedDamageValues = savedData.savedDamageValues

        if savedData.savedDamageValues.minDamage then
            weapon:setMinDamage(savedData.savedDamageValues.minDamage)
        end

        if savedData.savedDamageValues.maxDamage then
            weapon:setMaxDamage(savedData.savedDamageValues.maxDamage)
        end
    elseif savedData.minDamage and savedData.maxDamage then
        -- Use stored values if no savedDamageValues
        weapon:setMinDamage(savedData.minDamage)
        weapon:setMaxDamage(savedData.maxDamage)

        -- Create savedDamageValues if missing
        if not weapon:getModData().savedDamageValues then
            weapon:getModData().savedDamageValues = {
                minDamage = savedData.minDamage,
                maxDamage = savedData.maxDamage
            }
        end
    end

    -- Update tracking entry with new weapon ID
    savedData.weaponID = weapon:getID()

    return true
end

-- Check all weapons in player's inventory
local function checkAllPlayerWeapons(player)
    if not player then return end

    local inventory = player:getInventory()
    local items = inventory:getItems()

    for i = 0, items:size()-1 do
        local item = items:get(i)
        if item and item:IsWeapon() then
            -- Save if enchanted
            if item:getModData() and (item:getModData().enchantmentStats or item:getModData().savedDamageValues) then
                saveWeaponEnchantmentData(item)
            end

            -- Try to restore
            restoreWeaponEnchantmentData(item)
        end
    end

    -- Also check equipped weapon
    local primaryItem = player:getPrimaryHandItem()
    if primaryItem and primaryItem:IsWeapon() then
        if primaryItem:getModData() and (primaryItem:getModData().enchantmentStats or primaryItem:getModData().savedDamageValues) then
            saveWeaponEnchantmentData(primaryItem)
        end

        restoreWeaponEnchantmentData(primaryItem)
    end
end

-- Clean up old entries
local function cleanupTrackedWeapons()
    local currentTime = getGameTime():getWorldAgeHours()
    local expiryHours = 24 -- Keep data for 24 in-game hours

    local toRemove = {}

    for identifier, data in pairs(WeaponEnchantPersistence.trackedWeapons) do
        if currentTime - data.lastSeen > expiryHours then
            table.insert(toRemove, identifier)
        end
    end

    for _, identifier in ipairs(toRemove) do
        WeaponEnchantPersistence.trackedWeapons[identifier] = nil
    end

    if #toRemove > 0 then
        print("[ZM_WeaponEnchantPersistence] Cleaned up " .. #toRemove .. " old weapon entries")
    end
end

-- EVENT HANDLERS (using only documented events)

-- Track weapons when equipped
local function onEquipPrimary(player, item)
    if not item or not item:IsWeapon() then return end

    -- Save if enchanted
    if item:getModData() and (item:getModData().enchantmentStats or item:getModData().savedDamageValues) then
        saveWeaponEnchantmentData(item)
    end

    -- Try to restore
    restoreWeaponEnchantmentData(item)
end

-- Regular checks for magazine changes
local function onPlayerUpdate(player)
    if not player:isLocalPlayer() then return end

    -- Only run checks periodically to save performance
    local currentGameMinutes = getGameTime():getWorldAgeHours() * 60
    if currentGameMinutes - WeaponEnchantPersistence.lastCheckTime < WeaponEnchantPersistence.checkInterval then
        return
    end

    WeaponEnchantPersistence.lastCheckTime = currentGameMinutes

    local weapon = player:getPrimaryHandItem()
    if weapon and weapon:isRanged() and weapon:IsWeapon() then
        -- If weapon ID changed, it might be a magazine change
        if WeaponEnchantPersistence.lastCheckedWeaponID and
           WeaponEnchantPersistence.lastCheckedWeaponID ~= weapon:getID() then

            -- Try to restore enchantment data
            restoreWeaponEnchantmentData(weapon)
        end

        -- Save current weapon if enchanted
        if weapon:getModData() and (weapon:getModData().enchantmentStats or weapon:getModData().savedDamageValues) then
            saveWeaponEnchantmentData(weapon)
        end

        -- Update last checked weapon ID
        WeaponEnchantPersistence.lastCheckedWeaponID = weapon:getID()
    end

    -- Run cleanup occasionally
    if math.floor(currentGameMinutes / 60) % 1 == 0 and
       math.floor(WeaponEnchantPersistence.lastCheckTime / 60) ~= math.floor(currentGameMinutes / 60) then
        cleanupTrackedWeapons()
    end
end

-- Check inventory when it refreshes
local function onRefreshInventoryWindowContainers(playerID)
    local player = getSpecificPlayer(playerID)
    if player and player:isLocalPlayer() then
        checkAllPlayerWeapons(player)
    end
end

-- After combat, check weapon
local function onPlayerAttackFinished(character, weapon)
    if character:isLocalPlayer() and weapon and weapon:IsWeapon() then
        -- First try to restore if needed
        if not restoreWeaponEnchantmentData(weapon) then
            -- If not restored, save current state
            if weapon:getModData() and (weapon:getModData().enchantmentStats or weapon:getModData().savedDamageValues) then
                saveWeaponEnchantmentData(weapon)
            end
        end
    end
end

-- Full scan on game start
local function onGameStart()
    print("[ZM_WeaponEnchantPersistence] Initializing weapon enchantment persistence system")

    local player = getSpecificPlayer(0)
    if player then
        checkAllPlayerWeapons(player)
    end
end

-- Register event handlers (documented events only)
Events.OnEquipPrimary.Add(onEquipPrimary)
Events.OnGameStart.Add(onGameStart)
Events.OnPlayerAttackFinished.Add(onPlayerAttackFinished)
Events.OnWeaponSwing.Add(function(character, weapon)
    if character:isLocalPlayer() and weapon and weapon:IsWeapon() then
        if weapon:getModData() and (weapon:getModData().enchantmentStats or weapon:getModData().savedDamageValues) then
            saveWeaponEnchantmentData(weapon)
        end
        restoreWeaponEnchantmentData(weapon)
    end
end)

print("[ZM_WeaponEnchantPersistence] Weapon enchantment persistence system loaded")