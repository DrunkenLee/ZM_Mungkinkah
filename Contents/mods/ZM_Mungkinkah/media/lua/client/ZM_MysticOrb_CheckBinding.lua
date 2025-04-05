-- Context menu for checking binding status
-- Fix: Capture the returned module when requiring
local ZM_MysticOrb = require "ZM_MysticOrb_utils"

local function addCheckBindingContextMenu(player, context, items)
    -- Get the local player
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return end

    -- Add the context menu option for weapons
    local weapon = playerObj:getPrimaryHandItem()
    if weapon and weapon:IsWeapon() then
        context:addOption("Check Orb Binding", playerObj, function()
            ZM_MysticOrb.CheckEquippedWeaponBinding()
        end)
    end
end

-- Add to both inventory and world context menus
Events.OnFillInventoryObjectContextMenu.Add(addCheckBindingContextMenu)
Events.OnFillWorldObjectContextMenu.Add(addCheckBindingContextMenu)