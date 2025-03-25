if isClient() then return end

-- Handle enchantment requests
local function onClientCommand(module, command, player, data)
    -- Extensive debugging for tracking
    -- print("[ZM_EnchantWeaponServer] Received command: " .. tostring(module) .. " / " .. tostring(command))

    -- Handle sound broadcast request
    if module == "ZM_Mungkinkah" and command == "PlayWorldSound" then
        print("[ZM_EnchantWeaponServer] Broadcasting sound: " .. tostring(data.sound))

        -- Validate required fields
        if not data.x or not data.y or not data.z or not data.sound then
            print("[ZM_EnchantWeaponServer] ERROR: Missing required sound data!")
            return
        end

        -- Extract sound data
        local x = data.x
        local y = data.y
        local z = data.z
        local radius = data.radius or 20
        local volume = data.volume or 1.0
        local sound = data.sound

        -- Get all online players
        local players = getOnlinePlayers()
        if players then
            -- For each player, check distance and send sound command if they're nearby
            for i = 0, players:size() - 1 do
                local playerObj = players:get(i)

                -- Calculate distance to sound source
                local px = playerObj:getX()
                local py = playerObj:getY()
                local distance = math.sqrt((px - x)^2 + (py - y)^2)

                -- Only send to players within radius
                if distance <= radius then
                    -- Send command to this specific player
                    local sound = getSoundManager():PlaySound("rganvil", false, 0);
                    getSoundManager():PlayAsMusic("rganvil", sound, false, 0);
                    sound:setVolume(0.1);

                    sendServerCommand(playerObj, "ZM_Mungkinkah", "PlayWorldSound", {
                        x = x,
                        y = y,
                        z = z,
                        sound = sound,
                        distance = distance,
                        radius = radius,
                        volume = volume
                    })

                    print("[ZM_EnchantWeaponServer] Sound sent to player: " .. playerObj:getUsername())
                end
            end
        else
            -- Single player mode
            sendServerCommand("ZM_Mungkinkah", "PlayWorldSound", {
                x = x,
                y = y,
                z = z,
                sound = sound,
                radius = radius,
                volume = volume
            })
        end

        print("[ZM_EnchantWeaponServer] Sound broadcast completed")
        return
    end

    if module == "EnchantWeapon" and command == "applyEnchantment" then
        print("[ZM_EnchantWeaponServer] Processing enchantment request")

        -- Get the weapon
        local weaponID = data.weaponID
        local playerID = data.playerID

        print("[ZM_EnchantWeaponServer] Weapon ID: " .. tostring(weaponID) .. ", Player ID: " .. tostring(playerID))

        -- Get player from ID
        local playerObj = getPlayerByOnlineID(playerID)
        if not playerObj then
            print("[ZM_EnchantWeaponServer] ERROR: Player not found!")
            return
        end

        print("[ZM_EnchantWeaponServer] Found player: " .. tostring(playerObj:getUsername()))

        -- Get weapon from inventory
        local inventory = playerObj:getInventory()
        local weapon = inventory:getItemById(weaponID)

        if not weapon then
            print("[ZM_EnchantWeaponServer] ERROR: Weapon not found!")
            return
        end

        print("[ZM_EnchantWeaponServer] Found weapon: " .. tostring(weapon:getName()))

        -- Step 1: Roll for damage type (1-2)
        local damageTypeRoll = ZombRand(2) + 1 -- 1 or 2
        local damageType = damageTypeRoll == 1 and "minDamage" or "maxDamage"

        -- Step 2: Roll for damage amount (1-10)
        local damageRoll = ZombRand(10) + 1 -- 1 to 10

        print("[ZM_EnchantWeaponServer] Rolls: Type=" .. damageTypeRoll .. ", Damage=" .. damageRoll)

        -- Step 3: Calculate damage modifier based on roll
        local damageModifier = damageRoll / 20 -- 0.05 to 0.5

        -- Step 4: Apply positive or negative effect based on roll
        local isPositive = damageRoll > 5
        local currentDamage = 0
        local newDamage = 0

        if damageType == "minDamage" then
            currentDamage = weapon:getMinDamage()
            if isPositive then
                newDamage = currentDamage + damageModifier
            else
                newDamage = math.max(0.1, currentDamage - damageModifier) -- Prevent negative damage
            end
            weapon:setMinDamage(newDamage)
        else -- maxDamage
            currentDamage = weapon:getMaxDamage()
            if isPositive then
                newDamage = currentDamage + damageModifier
            else
                newDamage = math.max(0.1, currentDamage - damageModifier) -- Prevent negative damage
            end
            weapon:setMaxDamage(newDamage)
        end

        print("[ZM_EnchantWeaponServer] Result: Type=" .. damageType .. ", Positive=" .. tostring(isPositive) ..
              ", Old=" .. currentDamage .. ", New=" .. newDamage)

        -- Mark as enchanted with the specific type
        if not weapon:getModData().enchantments then
            weapon:getModData().enchantments = {}
        end

        weapon:getModData().enchantments[damageType] = isPositive
        weapon:getModData().enchanted = true

        print("[ZM_EnchantWeaponServer] Sending response to client")

        -- Check if player is still connected
        if not playerObj:isConnected() then
            print("[ZM_EnchantWeaponServer] ERROR: Player is not connected!")
            return
        end

        -- Use pcall to catch any errors during sending
        local success, error = pcall(function()
            -- CRITICAL: Send the results back to client
            sendServerCommand(playerObj, "EnchantWeapon", "enchantResult", {
                weaponID = weaponID,
                damageType = damageType,
                isPositive = isPositive,
                damageRoll = damageRoll,
                newDamage = newDamage,
                currentDamage = currentDamage
            })
        end)

        if success then
            print("[ZM_EnchantWeaponServer] Response sent successfully!")
        else
            print("[ZM_EnchantWeaponServer] ERROR sending response: " .. tostring(error))
        end
    end

    if module == "EnchantWeapon" and command == "syncEnchantment" then
        print("[ZM_EnchantWeaponServer] Processing enchantment sync from client")

        -- Get the weapon
        local weaponID = data.weaponID
        local damageType = data.damageType
        local isPositive = data.isPositive
        local damageRoll = data.damageRoll
        local newDamage = data.newDamage

        print("[ZM_EnchantWeaponServer] Weapon ID: " .. tostring(weaponID) .. ", Damage Type: " .. tostring(damageType) ..
              ", Positive: " .. tostring(isPositive) .. ", Roll: " .. tostring(damageRoll) .. ", New Damage: " .. tostring(newDamage))

        -- Get player object
        local playerObj = getPlayerByOnlineID(player:getOnlineID())
        if not playerObj then
            print("[ZM_EnchantWeaponServer] ERROR: Player not found!")
            return
        end

        -- Get weapon from inventory
        local inventory = playerObj:getInventory()
        local weapon = inventory:getItemById(weaponID)
        if not weapon then
            print("[ZM_EnchantWeaponServer] ERROR: Weapon not found!")
            return
        end

        -- Validate and apply the changes
        local currentDamage = damageType == "minDamage" and weapon:getMinDamage() or weapon:getMaxDamage()
        if math.abs(newDamage - currentDamage) <= (damageRoll / 20) then
            if damageType == "minDamage" then
                weapon:setMinDamage(newDamage)
            else
                weapon:setMaxDamage(newDamage)
            end

            -- Mark as enchanted
            if not weapon:getModData().enchantments then
                weapon:getModData().enchantments = {}
            end
            weapon:getModData().enchantments[damageType] = isPositive
            weapon:getModData().enchanted = true

            print("[ZM_EnchantWeaponServer] Enchantment applied successfully")
        else
            print("[ZM_EnchantWeaponServer] ERROR: Invalid enchantment data from client!")
        end

        -- Acknowledge the sync
        sendServerCommand(playerObj, "EnchantWeapon", "syncAcknowledged", {
            weaponID = weaponID,
            damageType = damageType,
            isPositive = isPositive,
            newDamage = newDamage
        })
    end
end

-- IMPORTANT: Make sure we remove any existing handler and add our new one
Events.OnClientCommand.Remove(onClientCommand)
Events.OnClientCommand.Add(onClientCommand)
print("[ZM_EnchantWeaponServer] Registered client command handler")