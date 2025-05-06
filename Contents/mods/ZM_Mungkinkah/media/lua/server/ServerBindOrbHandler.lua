-- Global mod data key
local MOD_ID = "ZM_MysticOrb"

-- Import the server-side data manager (with error handling)
local ServerOrbData
local success, result = pcall(function() return require("ServerOrbData") end)
if success then
    ServerOrbData = result
    print("DEBUG: Successfully loaded ServerOrbData module")
else
    print("ERROR: Failed to load ServerOrbData module: " .. tostring(result))
    -- Create a fallback basic data storage
    ServerOrbData = {
        bindings = {},
        loaded = true,
        addBinding = function(orbID, weaponID)
            ServerOrbData.bindings[orbID] = weaponID
            return true
        end,
        isWeaponBound = function(weaponFullType)
            for orbID, weaponID in pairs(ServerOrbData.bindings) do
                if string.find(weaponID, weaponFullType) then
                    return true, orbID
                end
            end
            return false, nil
        end,
        removeBinding = function(orbID)
            if ServerOrbData.bindings[orbID] then
                ServerOrbData.bindings[orbID] = nil
                return true
            end
            return false
        end
    }
end

local function onRegisterOrbBinding(player, args)
    if not player or not args then
        return
    end

    local orbID = args.orbID
    local weaponID = args.weaponID

    if not orbID or not weaponID then
        return
    end
    -- Check if ServerOrbData is properly initialized
    if not ServerOrbData or not ServerOrbData.bindings then
        sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {message = "Error: Could not access binding data."})
        return
    end

    -- Check if this EXACT orb is already registered
    if ServerOrbData.bindings and ServerOrbData.bindings[orbID] then
        sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {message = "This orb is already bound to another weapon."})
        return
    end

    -- Register the orb and weapon IDs - JUST the IDs, nothing else
    if ServerOrbData.addBinding then
        ServerOrbData.addBinding(orbID, weaponID)
    else
        ServerOrbData.bindings[orbID] = weaponID
    end

    -- Notify the player - include orbWasBound flag for client to handle orb removal
    sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {
        message = "The orb has been successfully bound to your weapon, increasing its damage by 3.",
        orbWasBound = true,
        orbID = orbID,
        weaponFullType = weaponID  -- Pass the weapon ID so client can identify it
    })
end

local function onCheckWeaponBinding(player, args)
    if not player or not args then return end

    local weaponID = args.weaponID

    if not weaponID then
        return
    end

    -- Check all bindings for this exact weapon ID
    local isBound = false
    local orbID = nil

    -- Search for the weapon in all bindings (by value)
    for oID, wID in pairs(ServerOrbData.bindings) do
        if wID == weaponID then
            isBound = true
            orbID = oID
            break
        end
    end

    -- Send message to player
    if isBound then
        sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {
            message = "This weapon is bound to a mystic orb.",
            weaponBindingStatus = true,
            isBound = true,
            weaponID = weaponID,
            orbID = orbID
        })
    else
        sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {
            message = "This weapon is not bound to any mystic orb.",
            weaponBindingStatus = true,
            isBound = false,
            weaponID = weaponID
        })
    end
end

-- Hook into the OnClientCommand event for server-side handling
Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "ZM_MysticOrb" then
        if command == "RegisterOrbBinding" then
            pcall(function() onRegisterOrbBinding(player, args) end)
        elseif command == "BindOrbToWeapon" then
            print("DEBUG: Server forwarding BindOrbToWeapon to RegisterOrbBinding handler...")
            -- Get the weapon from the player's hands
            local weapon = player:getPrimaryHandItem()
            if not weapon then
                sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {message = "You need to hold a weapon to bind the orb."})
                return
            end

            -- Use ONLY the weapon's unique ID
            local weaponID = tostring(weapon:getID())

            print("DEBUG: Server using weapon ID: " .. weaponID)

            -- Use ONLY the essential IDs
            pcall(function() onRegisterOrbBinding(player, {
                orbID = args.orbID,
                weaponID = weaponID
            }) end)
        elseif command == "CheckWeaponBinding" then
            pcall(function() onCheckWeaponBinding(player, args) end)
        end
    end
end)

-- Clean up duplicate bindings periodically
Events.EveryHours.Add(function()
    -- Check if the data manager is loaded with error handling
    if not ServerOrbData or not ServerOrbData.loaded then return end
    if not ServerOrbData.bindings then return end

    local weaponToOrb = {}
    local toRemove = {}

    -- Find duplicates (multiple orbs bound to same weapon)
    for orbID, weaponID in pairs(ServerOrbData.bindings) do
        if weaponToOrb[weaponID] then
            table.insert(toRemove, orbID)
        else
            weaponToOrb[weaponID] = orbID
        end
    end

    -- Remove duplicates with error handling
    for _, orbID in ipairs(toRemove) do
        if ServerOrbData.removeBinding then
            pcall(function() ServerOrbData.removeBinding(orbID) end)
        else
            ServerOrbData.bindings[orbID] = nil
        end
    end
end)