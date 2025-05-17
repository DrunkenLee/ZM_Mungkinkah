-- Shared Mystic Orb Utilities
ZM_MysticOrb = {}

-- Useful constants and shared functions
ZM_MysticOrb.MOD_ID = "ZM_MysticOrb"
ZM_MysticOrb.ITEM_TYPE = "ZM_MysticOrb"

-- Function to check if a weapon has an orb bound to it (local check)
function ZM_MysticOrb.IsWeaponBound(weapon)
    if not weapon then return false end
    return weapon:getModData().weaponID ~= nil
end

-- Function to get the bound weapon ID for a specific orb (local check)
function ZM_MysticOrb.GetOrbBinding(orb)
    if not orb then return nil end
    return orb:getModData().orbID
end

-- Function to check binding status for equipped weapon (sends request to server)
function ZM_MysticOrb.CheckEquippedWeaponBinding()
    local player = getSpecificPlayer(0)
    if not player then return false end

    local weapon = player:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        player:Say("You need to hold a weapon to check its binding status.")
        return false
    end

    -- If we have local data, use that for a quick check
    if weapon:getModData().weaponID then
        player:Say("This weapon appears to be bound to a mystic orb.")
        return true
    end

    sendClientCommand(player, "ZM_MysticOrb", "CheckWeaponBinding", {
        weaponID = tostring(weapon:getID())
    })

    return true
end

return ZM_MysticOrb