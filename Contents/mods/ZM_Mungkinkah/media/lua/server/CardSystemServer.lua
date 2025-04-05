if isClient() then return end

-- Handle card slot requests
local function onClientCommand(module, command, player, data)
    if module ~= "CardSystem" then return end

    if command == "addSlot" then
        print("[ZM_CardSystem Server] Processing add slot request")

        -- Validate we have the required functions
        if not ZM_CardSystem or not ZM_CardSystem.getWeaponSlots or not ZM_CardSystem.addSlot then
            print("[ZM_CardSystem Server] ERROR: ZM_CardSystem functions not found!")
            -- Try to send response anyway
            if player and player:isConnected() then
                sendServerCommand(player, "CardSystem", "slotResult", {
                    success = false,
                    reason = "serverError"
                })
            end
            return
        end

        local weaponID = data.weaponID
        print("[ZM_CardSystem Server] Weapon ID: " .. tostring(weaponID))

        -- Get player object
        local playerObj = getPlayerByOnlineID(player:getOnlineID())
        if not playerObj then
            print("[ZM_CardSystem Server] ERROR: Player not found!")
            return
        end

        -- Get weapon
        local inventory = playerObj:getInventory()
        local weapon = inventory:getItemById(weaponID)
        if not weapon then
            local primaryItem = playerObj:getPrimaryHandItem()
            if primaryItem and primaryItem:getID() == weaponID then
                weapon = primaryItem
            else
                print("[ZM_CardSystem Server] ERROR: Weapon not found!")
                sendServerCommand(playerObj, "CardSystem", "slotResult", {
                    success = false,
                    reason = "weaponNotFound"
                })
                return
            end
        end

        -- Check current slots
        local slots = ZM_CardSystem.getWeaponSlots(weapon)
        if slots >= ZM_CardSystem.MAX_SLOTS then
            print("[ZM_CardSystem Server] ERROR: Weapon already has maximum slots!")
            sendServerCommand(playerObj, "CardSystem", "slotResult", {
                success = false,
                reason = "maxSlots"
            })
            return
        end

        -- Roll for success (1% chance)
        local roll = ZombRand(100)
        local success = (roll == 0) -- 1% chance (0 out of 0-99)

        print("[ZM_CardSystem Server] Roll: " .. roll .. " (success: " .. tostring(success) .. ")")

        -- If successful, add the slot
        if success then
            ZM_CardSystem.addSlot(weapon)
            print("[ZM_CardSystem Server] Successfully added a slot")
        else
            print("[ZM_CardSystem Server] Failed to add a slot")
        end

        -- Send result to client - use pcall to catch any errors
        local status, err = pcall(function()
            sendServerCommand(playerObj, "CardSystem", "slotResult", {
                success = success,
                slots = ZM_CardSystem.getWeaponSlots(weapon)
            })
        end)

        if not status then
            print("[ZM_CardSystem Server] ERROR sending result: " .. tostring(err))
        else
            print("[ZM_CardSystem Server] Result sent successfully")
        end

        -- Play sound effect
        sendServerCommand(playerObj, "ZM_Mungkinkah", "PlayWorldSound", {
            x = playerObj:getX(),
            y = playerObj:getY(),
            z = playerObj:getZ(),
            sound = success and "lightswitch" or "PZ_Cloth_Rip",
            radius = 10,
            volume = 0.8
        })
    end
end

-- Register command handler
Events.OnClientCommand.Remove(onClientCommand)
Events.OnClientCommand.Add(onClientCommand)
print("[ZM_CardSystem Server] Registered client command handler")