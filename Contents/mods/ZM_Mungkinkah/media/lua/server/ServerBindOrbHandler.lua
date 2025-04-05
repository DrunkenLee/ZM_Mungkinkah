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
    print("DEBUG: Server received RegisterOrbBinding command")
    if not player or not args then
        print("ERROR: Missing player or args in RegisterOrbBinding")
        return
    end

    local orbID = args.orbID
    local weaponID = args.weaponID

    if not orbID or not weaponID then
        print("ERROR: Missing orbID or weaponID in RegisterOrbBinding")
        return
    end

    print("DEBUG: Processing orbID: " .. tostring(orbID) .. " and weaponID: " .. tostring(weaponID))

    -- Extract the base part of the orbID to check for duplicates (extract prefix before any timestamps)
    local baseOrbID = orbID
    -- Strip off any timestamp or unique parts - keep just the core ID
    if string.find(orbID, "_") then
        -- Get the first two parts of the ID (ZM_MysticOrb_10) for better matching
        baseOrbID = string.match(orbID, "(.-)_[^_]+$")
    end

    print("DEBUG: Base orbID for duplicate checking: " .. baseOrbID)

    -- Check if ServerOrbData is properly initialized
    if not ServerOrbData or not ServerOrbData.bindings then
        print("ERROR: ServerOrbData not properly initialized")
        sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {message = "Error: Could not access binding data."})
        return
    end

    -- Check if this EXACT orb is already registered
    if ServerOrbData.bindings and ServerOrbData.bindings[orbID] then
        print("DEBUG: Orb already bound to: " .. tostring(ServerOrbData.bindings[orbID]))
        sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {message = "This orb is already bound to another weapon."})
        return
    end

    -- Check if a similar orb (with same base ID) is already registered - ONLY match exact orbID, not substring
    local foundExistingBinding = false
    for existingOrbID, existingWeaponID in pairs(ServerOrbData.bindings) do
        -- Only consider orbs with the EXACT same ID a match - not substring!
        if existingOrbID == orbID then
            print("DEBUG: Found exact orb already bound: " .. existingOrbID .. " -> " .. existingWeaponID)
            foundExistingBinding = true
            -- Prevent binding if it's trying to bind to a different weapon
            if existingWeaponID ~= weaponID then
                print("WARN: Blocking attempt to bind duplicate orb to different weapon")
                sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {
                    message = "This orb is already bound to another weapon. Cannot bind to a different weapon."
                })
                return
            end
        end
    end

    -- If no binding found, it's safe to proceed
    if not foundExistingBinding then
        print("DEBUG: No existing binding found for orb, proceeding with binding")
    end

    -- Register the orb and weapon IDs
    if ServerOrbData.addBinding then
        ServerOrbData.addBinding(orbID, weaponID)
        print("DEBUG: Successfully bound orb " .. orbID .. " to weapon " .. weaponID)
    else
        -- Fallback method if addBinding isn't available
        ServerOrbData.bindings[orbID] = weaponID
        print("DEBUG: Used fallback method to bind orb " .. orbID .. " to weapon " .. weaponID)
    end

    -- Notify the player - include orbWasBound flag for client to handle orb removal
    sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {
        message = "The orb has been successfully bound to your weapon.",
        orbWasBound = true,
        orbID = orbID
    })
end

local function onCheckWeaponBinding(player, args)
    if not player or not args then return end

    local weaponType = args.weaponType
    local weaponFullType = args.weaponFullType

    if not weaponType or not weaponFullType then
        print("ERROR: Missing weapon information in CheckWeaponBinding")
        return
    end

    -- Check if ServerOrbData is properly initialized
    if not ServerOrbData or not ServerOrbData.bindings then
        print("ERROR: ServerOrbData not properly initialized")
        sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {message = "Error: Could not access binding data."})
        return
    end

    -- Check all bindings to see if any match this weapon
    local isBound, orbID

    -- Use the proper method with error handling
    if ServerOrbData.isWeaponBound then
        local success, result1, result2 = pcall(function()
            return ServerOrbData.isWeaponBound(weaponFullType)
        end)

        if success then
            isBound, orbID = result1, result2
        else
            print("ERROR: Failed to call isWeaponBound: " .. tostring(result1))
            isBound = false
        end
    else
        -- Fallback manual check
        print("WARNING: Using fallback binding check")
        isBound = false
        for oID, weaponID in pairs(ServerOrbData.bindings) do
            if string.find(weaponID, weaponFullType) then
                isBound = true
                orbID = oID
                break
            end
        end
    end

    print("DEBUG: Checking weapon binding for " .. weaponFullType .. ": " .. tostring(isBound))

    if isBound then
        sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {message = "This weapon is bound to a mystic orb."})
    else
        sendServerCommand(player, "ZM_MysticOrb", "NotifyPlayer", {message = "This weapon is not bound to any mystic orb."})
    end
end

-- Hook into the OnClientCommand event for server-side handling
Events.OnClientCommand.Add(function(module, command, player, args)
    print("DEBUG: Server received client command: " .. module .. " - " .. command)

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

            -- Use the actual weapon data instead of a placeholder
            local weaponID = weapon:getFullType()
            pcall(function() onRegisterOrbBinding(player, {
                orbID = args.orbID,
                weaponID = weaponID,
                weaponType = weapon:getType(),
                weaponFullType = weapon:getFullType()
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
            -- Fallback method
            ServerOrbData.bindings[orbID] = nil
        end
    end
end)