-- Import the shared utilities - fix the path
local ZM_MysticOrb = require("ZM_MysticOrb_utils")

-- Helper function to get a timestamp
local function getTimestamp()
    return tostring(os.time())
end

local function onBindOrbToWeapon(args)
    local player = getSpecificPlayer(0)
    if not player then return end

    print("DEBUG: Received BindOrbToWeapon command with orbID: " .. tostring(args.orbID))

    -- Get the weapon in the player's primary hand
    local weapon = player:getPrimaryHandItem()
    if not weapon then
        player:Say("You need to hold a weapon in your primary hand to bind the orb.")
        print("DEBUG: No weapon in primary hand")
        return
    end

    -- Make sure it's actually a weapon
    if not weapon:IsWeapon() then
        player:Say("This item cannot be bound with an orb. Please hold a weapon.")
        print("DEBUG: Item in hand is not a weapon: " .. tostring(weapon:getType()))
        return
    end

    -- Get weapon info - SIMPLIFIED to remove timestamps
    local weaponType = weapon:getType()
    local weaponFullType = weapon:getFullType()
    local weaponCondition = tostring(math.floor(weapon:getCondition() * 100))
    -- New simpler weapon ID without timestamp
    local weaponID = weaponFullType

    print("DEBUG: Using weapon ID: " .. tostring(weaponID))

    -- Store ID in weapon's modData
    if not weapon:getModData().weaponID then
        weapon:getModData().weaponID = weaponID
        weapon:transmitModData()
    end

    print("DEBUG: Sending RegisterOrbBinding to server with weaponID and orbID")
    -- Send the orb and weapon IDs to the server
    sendClientCommand(player, "ZM_MysticOrb", "RegisterOrbBinding", {
        orbID = args.orbID,
        weaponID = weaponID,
        weaponType = weaponType,
        weaponFullType = weaponFullType
    })
end

-- Handle player notifications from server
local function onNotifyPlayer(args)
    if args and args.message then
        local player = getSpecificPlayer(0)
        if player then
            print("DEBUG: Server notification: " .. args.message)
            player:Say(args.message)

            -- Check if this is a successful binding notification
            if args.orbWasBound and args.orbWasBound == true then
                -- If the orb was successfully bound, try to find and remove it
                if args.orbID then
                    print("DEBUG: Attempting to find and remove orb: " .. args.orbID)
                    -- Find the orb in the player's inventory
                    local inventory = player:getInventory()
                    local items = inventory:getItems()
                    local foundItem = false

                    for i=0, items:size()-1 do
                        local item = items:get(i)
                        -- IMPROVED MATCHING: Check for both the original ID format and the full ID
                        if item:getType() == "ZM_MysticOrb" and item:getModData().orbUniqueID then
                            local generatedOrbID = "ZM_MysticOrb_" .. item:getModData().orbUniqueID
                            print("DEBUG: Comparing orb IDs: '" .. generatedOrbID .. "' vs '" .. args.orbID .. "'")

                            if generatedOrbID == args.orbID then
                                print("DEBUG: Found matching orb to remove!")
                                foundItem = true

                                -- Option 1: REMOVE the orb completely (uncomment this line to enable)
                                inventory:Remove(item)
                                print("DEBUG: Orb removed from inventory")

                                -- Option 2: Just mark it as used
                                -- item:getModData().isUsed = true
                                -- Safely call transmitModData if available
                                -- if isClient() and item.transmitModData then
                                --    pcall(function() item:transmitModData() end)
                                -- end

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
    print("DEBUG: Received server command: " .. module .. " - " .. command)
    print("DEBUG: Args: " .. tostring(args))

    if module == "ZM_MysticOrb" then
        if command == "NotifyPlayer" then
            print("DEBUG: NotifyPlayer received with message: " .. tostring(args.message))
            onNotifyPlayer(args)
        end
    end
end)

-- Handle client commands
Events.OnClientCommand.Add(function(module, command, args)
    print("DEBUG: Received client command: " .. module .. " - " .. command)

    if module == "ZM_MysticOrb" and command == "BindOrbToWeapon" then
        onBindOrbToWeapon(args)
    end
end)