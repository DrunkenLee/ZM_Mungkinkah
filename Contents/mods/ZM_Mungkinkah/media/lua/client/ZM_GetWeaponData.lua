ZM_GetWeaponData = {}

-- Table to store cached weapon data
local cachedWeaponData = {}

-- Function to request user weapon data from the server
function ZM_GetWeaponData.RequestUserWeaponData(username, callback)
    if not username or username == "" then
        print("[ZM_GetWeaponData] ERROR: No username provided")
        if callback then callback(nil) end
        return
    end

    print("[ZM_GetWeaponData] Requesting weapon data for: " .. username)

    -- Set up a callback to handle the response
    ZM_GetWeaponData.pendingCallback = callback
    ZM_GetWeaponData.pendingUsername = username

    -- Send request to server
    sendClientCommand("EnchantWeapon", "getUserWeapons", {
        username = username
    })
end

-- Event handler for receiving server response
local function onServerCommand(module, command, args)
    if module == "EnchantWeapon" and command == "receiveUserWeapons" then
        local username = args.username
        local weapons = args.weapons

        print("[ZM_GetWeaponData] Received " .. #weapons .. " weapons for: " .. username)

        -- Format the data for easier lookup
        local formattedData = {}
        for _, weapon in ipairs(weapons) do
            -- Index by weaponID
            formattedData[weapon.weaponID] = weapon

            -- Also index by saveName for convenient access
            if weapon.saveName and weapon.saveName ~= "INVALIDDATA" then
                formattedData[weapon.saveName] = weapon
            end
        end

        -- Cache the data
        cachedWeaponData[username] = formattedData

        -- Call the pending callback if it exists
        if ZM_GetWeaponData.pendingCallback and ZM_GetWeaponData.pendingUsername == username then
            ZM_GetWeaponData.pendingCallback(formattedData)
            ZM_GetWeaponData.pendingCallback = nil
            ZM_GetWeaponData.pendingUsername = nil
        end
    end
end

-- Register event handler
Events.OnServerCommand.Add(onServerCommand)

-- Function to get a weapon by its save name (uses cached data or makes a request)
function ZM_GetWeaponData.GetWeaponBySaveName(username, saveName, callback)
    if not username or not saveName then
        print("[ZM_GetWeaponData] ERROR: Missing username or saveName")
        if callback then callback(nil) end
        return
    end

    -- Check if we have cached data
    if cachedWeaponData[username] then
        local weapon = cachedWeaponData[username][saveName]
        if callback then callback(weapon) end
        return weapon
    else
        -- Request data from server if no cache exists
        ZM_GetWeaponData.RequestUserWeaponData(username, function(data)
            if data and callback then
                callback(data[saveName])
            elseif callback then
                callback(nil)
            end
        end)
    end
end

-- Return the module
return ZM_GetWeaponData