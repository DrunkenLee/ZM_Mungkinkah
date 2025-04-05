-- Define our card system module
ZM_CardSystem = ZM_CardSystem or {}

-- Get number of slots for a weapon
function ZM_CardSystem.getWeaponSlots(weapon)
    if not weapon or not weapon:IsWeapon() then return 0 end

    local modData = weapon:getModData()
    if not modData.cardSlots then
        modData.cardSlots = 0
    end

    return modData.cardSlots
end

-- Add a slot to a weapon
function ZM_CardSystem.addSlot(weapon)
    if not weapon or not weapon:IsWeapon() then return false end

    local modData = weapon:getModData()
    if not modData.cardSlots then
        modData.cardSlots = 0
    end

    modData.cardSlots = modData.cardSlots + 1

    -- Update weapon name to show slots
    ZM_CardSystem.updateWeaponName(weapon)

    return true
end

-- Update weapon name to show card slots
function ZM_CardSystem.updateWeaponName(weapon)
    if not weapon then return end

    local slots = ZM_CardSystem.getWeaponSlots(weapon)
    if slots <= 0 then return end

    local modData = weapon:getModData()
    if not modData.originalCardName then
        modData.originalCardName = weapon:getName()
    end

    -- Add slot indicator to name (e.g. "Baseball Bat [1]")
    local newName = modData.originalCardName .. " [" .. slots .. "]"
    weapon:setName(newName)
end

-- Maximum slots allowed per weapon
ZM_CardSystem.MAX_SLOTS = 4