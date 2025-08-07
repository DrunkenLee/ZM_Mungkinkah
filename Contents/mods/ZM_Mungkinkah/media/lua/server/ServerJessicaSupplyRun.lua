if isClient() then return end -- Only run on server

local ServerJessicaSupplyRun = {}

-- Handle client request to spawn or remove ambulance
local function onClientCommand(module, command, player, args)
    -- Check if it's our module
    if module ~= "JessicaSupplyRun" then return end

    -- Handle different commands
    if command == "SpawnAmbulance" then
        -- Handle spawning ambulance
        if not args.x or not args.y or not player then return end

        print("Server received request to spawn ambulance at " .. args.x .. ", " .. args.y)

        -- Get square for spawn location
        local cell = getCell()
        local square = cell:getGridSquare(math.floor(args.x), math.floor(args.y), 0)
        local spawnSuccess = false

        if square then
            -- Check if square is valid for vehicle
            if square:isVehicleIntersecting() then
                print("Cannot spawn ambulance - location blocked by another vehicle")
                sendServerCommand(player, "JessicaSupplyRun", "AmbulanceSpawned", {
                    success = false,
                    message = "Cannot spawn ambulance - location is blocked"
                })
                return
            end

            -- Spawn the ambulance using addVehicleDebug (important!)
            local ambulance = addVehicleDebug("Base.90fordF350ambulanceADMIN", IsoDirections.S, nil, square)

            if ambulance then
                -- Verify vehicle was truly created
                local vehicleID = ambulance:getId()
                local retrievedVehicle = getVehicleById(vehicleID)

                if retrievedVehicle then
                    -- Vehicle truly spawned successfully
                    spawnSuccess = true

                    -- Clear any containers in the vehicle
                    for i = 0, ambulance:getPartCount() - 1 do
                        local container = ambulance:getPartByIndex(i):getItemContainer()
                        if container then
                            container:removeAllItems()
                        end
                    end

                    -- Make sure ambulance is in good condition
                    ambulance:repair()

                    -- Set as unlocked
                    -- ambulance:setLocked(false)

                    -- Hotwire the ambulance
                    ambulance:setHotwired(true)

                    -- Make sure engine is in good condition
                    local enginePart = ambulance:getPartById("Engine")
                    if enginePart then
                        enginePart:setCondition(30)
                    end

                    -- Fill up gas tank
                    local gasTank = ambulance:getPartById("GasTank")
                    if gasTank then
                        gasTank:setCondition(30)
                        -- ambulance:setContainerContentAmount(gasTank:getContainerContentType(), 100)
                    end

                    -- Find the trunk container and add medical supplies
                    local trunkPart = ambulance:getPartById("TruckBed")
                    if trunkPart and trunkPart:getItemContainer() then

                    else
                        print("Could not find trunk container for ambulance")
                    end

                    print("Server spawned ambulance successfully with ID: " .. vehicleID)
                    print("[JessicaSupplyRunStarted] Ambulance spawned at: " .. args.x .. ", " .. args.y .. " by player: " .. player:getUsername())
                    -- Notify the client
                    sendServerCommand(player, "JessicaSupplyRun", "AmbulanceSpawned", {
                        success = true,
                        message = "Ambulance has arrived!",
                        keyID = vehicleID
                    })
                else
                    -- Vehicle reference exists but wasn't actually created properly
                    if ambulance then
                        ambulance:permanentlyRemove()
                    end
                    spawnSuccess = false
                end
            end
        end

        -- If spawn failed for any reason
        if not spawnSuccess then
            print("Failed to spawn ambulance")
            sendServerCommand(player, "JessicaSupplyRun", "AmbulanceSpawned", {
                success = false,
                message = "Failed to spawn ambulance. Try another location."
            })
        end
    elseif command == "RemoveAmbulance" then
        -- Handle removing ambulance
        if not args.vehicleID then
            print("Error: No vehicle ID provided for removal")
            return
        end

        print("Server received request to remove ambulance with ID: " .. args.vehicleID)

        -- Get the vehicle by ID
        local vehicleToRemove = getVehicleById(args.vehicleID)
        if vehicleToRemove then
            -- Store vehicle position before removing it
            local vehicleX = vehicleToRemove:getX()
            local vehicleY = vehicleToRemove:getY()
            local vehicleZ = vehicleToRemove:getZ()

            -- Try multiple removal methods for reliability
            print("Removing ambulance with ID: " .. args.vehicleID)
            print("[JessicaSupplyRunCompleted] Removing vehicle at position: " .. vehicleX .. ", " .. vehicleY .. ", " .. vehicleZ)
            vehicleToRemove:setAlpha(0.0) -- Make invisible first
            vehicleToRemove:removeFromWorld() -- Standard removal
            vehicleToRemove:removeFromSquare() -- Additional removal method

            -- As a last resort, permanently remove
            vehicleToRemove:permanentlyRemove()

            -- Notify the requesting client
            sendServerCommand(player, "JessicaSupplyRun", "AmbulanceRemoved", {
                success = true,
                message = "The medical team has taken the ambulance and supplies.",
                vehicleID = args.vehicleID, -- Important: Include the vehicle ID
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
                        sendServerCommand(nearbyPlayer, "JessicaSupplyRun", "AmbulanceRemoved", {
                            success = true,
                            message = "An ambulance has been picked up by the medical team.",
                            vehicleID = args.vehicleID, -- Include vehicle ID for local removal
                            x = vehicleX,
                            y = vehicleY,
                            z = vehicleZ
                        })
                    end
                end
            end
        else
            print("Could not find ambulance with ID: " .. args.vehicleID)
            sendServerCommand(player, "JessicaSupplyRun", "AmbulanceRemoved", {
                success = false,
                message = "Failed to remove ambulance."
            })
        end
    end
end

Events.OnClientCommand.Add(onClientCommand)

print("Server Jessica Supply Run initialized")