if isClient() then return end -- Only run on server

local ServerZM_Autoshop = {}

-- Handle client request to remove vehicles
local function onClientCommand(module, command, player, args)
    -- Check if it's our module
    if module ~= "ZM_Autoshop" then return end

    -- Handle vehicle removal command
    if command == "RemoveVehicle" then
        -- Safety check for required parameters
        if not args.vehicleID then
            print("Error: No vehicle ID provided for removal")
            return
        end

        print("Server received request to remove vehicle with ID: " .. args.vehicleID)

        -- Get the vehicle by ID
        local vehicleToRemove = getVehicleById(args.vehicleID)
        if vehicleToRemove then
            -- Store vehicle position before removing it
            local vehicleX = vehicleToRemove:getX()
            local vehicleY = vehicleToRemove:getY()
            local vehicleZ = vehicleToRemove:getZ()
            local scriptName = args.scriptName or vehicleToRemove:getScriptName()
            local condition = args.condition or 0

            -- Try multiple removal methods for reliability
            print("Removing vehicle with ID: " .. args.vehicleID)
            vehicleToRemove:setAlpha(0.0) -- Make invisible first
            vehicleToRemove:removeFromWorld() -- Standard removal
            vehicleToRemove:removeFromSquare() -- Additional removal method

            -- As a last resort, permanently remove
            vehicleToRemove:permanentlyRemove()

            -- Process any rewards or systems based on the vehicle removal
            -- This could include adding money, updating player stats, etc.

            -- Example: Add a reward based on vehicle condition
            if player and player:getModData() then
                -- Calculate reward based on condition
                -- local reward = calculateReward(scriptName, condition)
                -- You would need to implement calculateReward function

                -- Add flag or record to player data
                -- player:getModData().vehiclesSold = (player:getModData().vehiclesSold or 0) + 1
            end

            -- Notify the requesting client
            sendServerCommand(player, "ZM_Autoshop", "VehicleRemoved", {
                success = true,
                message = "The vehicle has been processed and removed.",
                vehicleID = args.vehicleID,
                scriptName = scriptName,
                condition = condition,
                x = vehicleX,
                y = vehicleY,
                z = vehicleZ
            })

            -- Notify all nearby clients about the vehicle removal
            local players = getOnlinePlayers()
            local NOTIFY_RADIUS = 20 -- tiles

            -- For each player in the game
            for i = 0, players:size() - 1 do
                local nearbyPlayer = players:get(i)

                -- Skip the player who initiated the request (already notified)
                if nearbyPlayer ~= player then
                    -- Calculate distance to vehicle
                    local px = nearbyPlayer:getX()
                    local py = nearbyPlayer:getY()
                    local dx = px - vehicleX
                    local dy = py - vehicleY
                    local distanceSquared = dx*dx + dy*dy

                    -- If player is within notification radius
                    if distanceSquared <= (NOTIFY_RADIUS * NOTIFY_RADIUS) then
                        -- Send notification to this nearby player
                        sendServerCommand(nearbyPlayer, "ZM_Autoshop", "VehicleRemoved", {
                            success = true,
                            message = "A vehicle has been processed at the auto shop.",
                            vehicleID = args.vehicleID,
                            x = vehicleX,
                            y = vehicleY,
                            z = vehicleZ
                        })
                    end
                end
            end
        else
            print("Could not find vehicle with ID: " .. args.vehicleID)
            sendServerCommand(player, "ZM_Autoshop", "VehicleRemoved", {
                success = false,
                message = "Failed to remove vehicle."
            })
        end
    end
end

Events.OnClientCommand.Add(onClientCommand)

print("Server ZM_Autoshop initialized")