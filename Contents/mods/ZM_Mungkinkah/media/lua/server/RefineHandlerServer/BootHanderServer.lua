--***********************************************************
--**               BOOT REFINE SERVER HANDLER             **
--**           Server-side refinement processing          **
--***********************************************************

BootRefineServerHandler = BootRefineServerHandler or {}

-- Server command handlers
local function onClientCommand(module, command, player, args)
    if module ~= "BootRefine" then return end

    if command == "requestBootData" then
        -- Handle boot data requests from client
        BootRefineServerHandler.sendBootDataToClient(player, args)

    elseif command == "syncRefinement" then
        -- Handle refinement sync from client
        BootRefineServerHandler.syncPlayerRefinement(player, args)

    elseif command == "requestPlayerStats" then
        -- Handle player stats requests
        BootRefineServerHandler.sendPlayerStatsToClient(player, args)
    end
end

-- Send boot data to requesting client
function BootRefineServerHandler.sendBootDataToClient(player, args)
    if not player then return end

    local playerID = player:getOnlineID()

    -- Get player's equipment data (server-side verification)
    local bootData = {
        playerID = playerID,
        timestamp = getTimestamp(),
        boots = nil -- Will be populated if boots are found
    }

    -- Send response back to client
    sendServerCommand(player, "BootRefine", "bootDataResponse", bootData)

    print("[BootRefineServer] Boot data sent to player: " .. tostring(player:getUsername()))
end

-- Sync refinement results
function BootRefineServerHandler.syncPlayerRefinement(player, args)
    if not player or not args then return end

    local playerID = player:getOnlineID()
    local username = player:getUsername()

    -- Log the refinement for server records
    print(string.format("[BootRefineServer] Player %s refined equipment: success=%s",
          username, tostring(args.success)))

    -- You could add server-side validation here
    -- For now, we trust the client-side refinement system

    -- Optionally broadcast refinement success to nearby players
    if args.success then
        local nearbyPlayers = {}
        local playerX = player:getX()
        local playerY = player:getY()
        local playerZ = player:getZ()

        -- Find players within range (optional feature)
        for i = 0, getNumActivePlayers() - 1 do
            local otherPlayer = getSpecificPlayer(i)
            if otherPlayer and otherPlayer ~= player then
                local distance = math.sqrt(
                    (otherPlayer:getX() - playerX)^2 +
                    (otherPlayer:getY() - playerY)^2
                )
                if distance <= 10 then -- Within 10 tiles
                    table.insert(nearbyPlayers, otherPlayer)
                end
            end
        end

        -- Send refinement notification to nearby players
        for _, nearbyPlayer in ipairs(nearbyPlayers) do
            sendServerCommand(nearbyPlayer, "BootRefine", "nearbyRefinement", {
                playerName = username,
                success = args.success,
                stats = args.stats
            })
        end
    end

    -- Send acknowledgment back to the client
    sendServerCommand(player, "BootRefine", "syncAcknowledged", {
        playerID = playerID,
        timestamp = getTimestamp(),
        success = true
    })
end

-- Send player stats to client (for future currency/point systems)
function BootRefineServerHandler.sendPlayerStatsToClient(player, args)
    if not player then return end

    local playerID = player:getOnlineID()
    local username = player:getUsername()

    -- Get player stats (implement your point/currency system here)
    local playerStats = {
        playerID = playerID,
        username = username,
        refinementPoints = 9999, -- Default for development
        totalRefinements = 0,
        successfulRefinements = 0,
        timestamp = getTimestamp()
    }

    -- You could load this from ModData or a database
    -- For now, return default values

    sendServerCommand(player, "BootRefine", "playerStatsResponse", playerStats)

    print("[BootRefineServer] Player stats sent to: " .. username)
end

-- Sound broadcasting for refinement effects
function BootRefineServerHandler.broadcastRefinementSound(player, soundName, isSuccess)
    if not player or not soundName then return end

    local playerX = player:getX()
    local playerY = player:getY()
    local playerZ = player:getZ()

    -- Play sound for all players in range
    for i = 0, getNumActivePlayers() - 1 do
        local otherPlayer = getSpecificPlayer(i)
        if otherPlayer then
            local distance = math.sqrt(
                (otherPlayer:getX() - playerX)^2 +
                (otherPlayer:getY() - playerY)^2
            )
            if distance <= 20 then -- Sound range
                sendServerCommand(otherPlayer, "BootRefine", "playRefinementSound", {
                    sound = soundName,
                    success = isSuccess,
                    x = playerX,
                    y = playerY,
                    z = playerZ
                })
            end
        end
    end

    print(string.format("[BootRefineServer] Broadcasting sound %s from %s", soundName, player:getUsername()))
end

-- Register server command handler
Events.OnClientCommand.Add(onClientCommand)

print("[BootRefineServer] Boot refinement server handler loaded successfully")