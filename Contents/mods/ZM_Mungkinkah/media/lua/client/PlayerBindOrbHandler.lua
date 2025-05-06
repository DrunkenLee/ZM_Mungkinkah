-- Import the shared utilities - fix the path
local ZM_MysticOrb = require("ZM_MysticOrb_utils")

-- Helper function to get a timestamp
local function getTimestamp()
    return tostring(os.time())
end

local function onBindOrbToWeapon(args)
    local player = getSpecificPlayer(0)
    if not player then return end

    local weapon = player:getPrimaryHandItem()
    if not weapon then
        player:Say("You need to hold a weapon in your primary hand to bind the orb.")
        return
    end

    -- Make sure it's actually a weapon
    if not weapon:IsWeapon() then
        player:Say("This item cannot be bound with an orb. Please hold a weapon.")
        return
    end

    local weaponID = tostring(weapon:getID())

    -- Store ID in weapon's modData
    weapon:getModData().weaponID = weaponID


    if isClient() and weapon.transmitModData then
        local success = pcall(function() weapon:transmitModData() end)
        if not success then print("DEBUG: transmitModData failed but continuing") end
    end

    -- Send only the essential IDs to the server
    sendClientCommand(player, "ZM_MysticOrb", "RegisterOrbBinding", {
        orbID = args.orbID,
        weaponID = weaponID
    })
end

-- Handle player notifications from server
local function onNotifyPlayer(args)
    if args and args.message then
        local player = getSpecificPlayer(0)
        if player then
            player:Say(args.message)
            if args.orbWasBound and args.orbWasBound == true then
                if args.orbID then
                    local inventory = player:getInventory()
                    local items = inventory:getItems()
                    local foundItem = false

                    for i=0, items:size()-1 do
                        local item = items:get(i)
                        if item:getType() == "ZM_MysticOrb" and item:getModData().orbUniqueID then
                            local generatedOrbID = "ZM_MysticOrb_" .. item:getModData().orbUniqueID
                            if generatedOrbID == args.orbID then
                                foundItem = true
                                inventory:Remove(item)
                                break
                            end
                        end
                    end

                    if not foundItem then
                        print("ERROR: Could not find orb to remove with ID: " .. args.orbID)
                    end
                end
            end
        end
    end
end

-- Register for server commands
Events.OnServerCommand.Add(function(module, command, args)
    if module == "ZM_MysticOrb" then
        if command == "NotifyPlayer" then
            onNotifyPlayer(args)
        end
    end
end)

-- Handle client commands
Events.OnClientCommand.Add(function(module, command, args)
    if module == "ZM_MysticOrb" and command == "BindOrbToWeapon" then
        onBindOrbToWeapon(args)
    end
end)