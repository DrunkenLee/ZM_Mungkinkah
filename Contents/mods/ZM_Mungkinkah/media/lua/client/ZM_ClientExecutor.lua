local RemoteFunctions = {
    playersayfunct = function(args)
        local player = getSpecificPlayer(0);
        if player then
            local message = args[1] or "Hello from server!";
            player:Say(message);
        end
    end,

    setflagnpc = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] then
            --print("Error: No flag name provided.");
            return;
        end
        if player then
            local username = player:getUsername();
            local flagName = args[1]
            SendFlagRequestToServer.add(username, flagName)
            player:Say("Flag '" .. flagName .. "' set for player: " .. username);
        end
    end,

    removeflagnpc = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] then
            --print("Error: No flag name provided.");
            return;
        end
        if player then
            local username = player:getUsername();
            local flagName = args[1]
            SendFlagRequestToServer.remove(username, flagName)
            player:Say("Flag '" .. flagName .. "' removed for player: " .. username);
        end
    end,

    togglezmflag = function(args)
        if not _G.PlayerFlagHandler then
            --print("Error: PlayerFlagHandler not found in global scope");
            return;
        end

        local player = getSpecificPlayer(0);
        if not args[1] then
            --print("Error: No flag name provided.");
            return;
        end

        if player then
            local username = player:getUsername();
            local flagName = args[1];

            local currentValue = false;
            if _G.PlayerFlagHandler.getFlagOnPlayer then
                currentValue = _G.PlayerFlagHandler.getFlagOnPlayer(username, flagName);
            end

            _G.PlayerFlagHandler.setFlagOnPlayer(username, flagName, not currentValue);
            player:Say("ZM Flag '" .. flagName .. "' toggled for player: " .. username);
        end
    end,

    sethourssurv = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] then
            --print("Error: No hours value provided.");
            return;
        end

        local hours = tonumber(args[1]);
        if not hours then
            --print("Error: Invalid hours value provided.");
            return;
        end

        if player then
            player:setHoursSurvived(hours);
            player:Say("Hours survived set to: " .. hours);
        end
    end,

    setzombiekills = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] then
            --print("Error: No zombie kills value provided.");
            return;
        end

        local kills = tonumber(args[1]);
        if not kills then
            --print("Error: Invalid zombie kills value provided.");
            return;
        end

        if player then
            player:setZombieKills(kills);
            player:Say("Zombie kills set to: " .. kills);
        end
    end,

    debugapplyenchant = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] or not args[3] or not args[4] then
            --print("Error: Missing parameters. Usage: debugapplyenchant <minDMG> <maxDMG> <enchantment> <name>");
            return;
        end

        local minDMG = tonumber(args[1]);
        local maxDMG = tonumber(args[2]);
        local enchantment = tonumber(args[3]);
        local name = args[4];

        if not minDMG or not maxDMG or not enchantment then
            --print("Error: Invalid numeric values provided for minDMG, maxDMG, or enchantment.");
            return;
        end

        if player then
            if _G.DebugApplyEnchantment then
                _G.DebugApplyEnchantment(minDMG, maxDMG, enchantment, name);
                player:Say("Applied enchantment: " .. enchantment .. " to weapon for " .. name);
            else
                --print("Error: DebugApplyEnchantment function not found in global scope");
            end
        end
    end,

    setserverwideflag = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] then
            --print("Error: Missing parameters. Usage: setserverwideflag <flagName> <value>");
            return;
        end

        local flagName = args[1];
        local flagValue = tonumber(args[2]);

        if not flagValue then
            --print("Error: Invalid flag value provided. Must be a number.");
            return;
        end

        if player then
            if _G.ZMServerwideFlagHandler and _G.ZMServerwideFlagHandler.consoleSetFlag then
                _G.ZMServerwideFlagHandler.consoleSetFlag(flagName, flagValue);
                player:Say("Set serverwide flag '" .. flagName .. "' to: " .. flagValue);
            else
                --print("Error: ZMServerwideFlagHandler.consoleSetFlag function not found in global scope");
            end
        end
    end,

    checkIsolationZoneHorde = function()
        local player = getSpecificPlayer(0);
        if not player then
            return;
        end

        -- Get all players currently in isolation zones
        local playersInZones = ZM_MiniHordeSpawner.getAllPlayersInIsolationZones()

        if #playersInZones == 0 then
            player:Say("No players detected in isolation zones.")
            return
        end

        -- Execute horde check for each player in zones
        for _, playerData in ipairs(playersInZones) do
            --print("Executing horde check for player: " .. playerData.username .. " in " .. playerData.zone)
            player:Say("Horde check executed for " .. playerData.username .. " in " .. playerData.zone)
        end

        -- Execute the actual horde zone check
        ZM_MiniHordeSpawner.checkAllHordeZones()

        -- Print zone status for feedback
        local counts = ZM_MiniHordeSpawner.getZonePlayerCounts()
        player:Say("Zone check complete - Zone 1: " .. counts.Horde1 .. " players, Zone 2: " .. counts.Horde2 .. " players")
    end,

    -- ServerPoints Management Functions
    addplayerpoints = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] then
            --print("Error: Missing parameters. Usage: addplayerpoints <username> <points>");
            return;
        end

        local username = args[1];
        local points = tonumber(args[2]);

        if not points then
            --print("Error: Invalid points value provided.");
            return;
        end

        if player then
            sendClientCommand("ServerPoints", "add", { username, points });
            player:Say("Added " .. points .. " ServerPoints to " .. username);
            --print("Redeemed " .. points .. " [ServerPoints]");
        end
    end,

    takeplayerpoints = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] then
            --print("Error: Missing parameters. Usage: takeplayerpoints <username> <points>");
            return;
        end

        local username = args[1];
        local points = tonumber(args[2]);

        if not points then
            --print("Error: Invalid points value provided.");
            return;
        end

        if player then
            local takenPoints = 0 - points;
            sendClientCommand("ServerPoints", "add", { username, takenPoints });
            player:Say("Taken " .. points .. " ServerPoints from " .. username);
            --print("Taken " .. points .. " [ServerPoints]");
        end
    end,

    getplayerpoints = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] then
            --print("Error: No username provided.");
            return;
        end

        local username = args[1];

        if player then
            sendClientCommand("ServerPoints", "get", { username });
            player:Say("Points request sent for " .. username);
        end
    end,

    depositpoints = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] then
            --print("Error: Missing parameters. Usage: depositpoints <username> <amount>");
            return;
        end

        local username = args[1];
        local amount = tonumber(args[2]);

        if not amount or amount <= 0 then
            --print("Error: Invalid deposit amount provided.");
            return;
        end

        if player then
            sendClientCommand("ServerPoints", "deposit", { username, amount });
            player:Say("Deposit request sent: " .. amount .. " points for " .. username);
            --print("Deposit request sent: " .. amount .. " points for " .. username);
        end
    end,

    depositraidpoints = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] then
            --print("Error: Missing parameters. Usage: depositraidpoints <username> <amount>");
            return;
        end

        local username = args[1];
        local amount = tonumber(args[2]);

        if not amount or amount <= 0 then
            --print("Error: Invalid raid deposit amount provided.");
            return;
        end

        if player then
            sendClientCommand("ServerRaidPoints", "deposit", { username, amount });
            player:Say("Raid deposit request sent: " .. amount .. " raid points for " .. username);
            --print("Raid deposit request sent: " .. amount .. " raid points for " .. username);
        end
    end,

    withdrawpoints = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] then
            --print("Error: No username provided.");
            return;
        end

        local username = args[1];

        if player then
            sendClientCommand("ServerPoints", "withdraw", { username });
            player:Say("Withdrawal request sent for " .. username);
            --print("Withdrawal request sent for " .. username);
        end
    end,

    withdrawraidpoints = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] then
            --print("Error: No username provided.");
            return;
        end

        local username = args[1];

        if player then
            sendClientCommand("ServerRaidPoints", "withdraw", { username });
            player:Say("Raid withdrawal request sent for " .. username);
            --print("Raid withdrawal request sent for " .. username);
        end
    end,
    -- Add more functions as needed
}

-- ServerPoints Response Handlers
local function onServerPointsResponse(module, command, arguments)
    local player = getSpecificPlayer(0);
    if not player then return; end

    if module == "ServerPoints" then
        if command == "get" then
            local points = arguments[1] or 0;
            -- player:Say("Current ServerPoints: " .. tostring(points));
            --print("Received points: " .. tostring(points));
        elseif command == "depositResult" then
            if arguments.success then
                -- player:Say("Successfully deposited " .. arguments.amount .. " points");
            else
                -- player:Say("Deposit failed: " .. (arguments.message or "Unknown error"));
            end
        elseif command == "withdrawResult" then
            if arguments.success then
                -- player:Say("Successfully withdrew " .. arguments.amount .. " points");
            else
                -- player:Say("Withdrawal failed: " .. (arguments.message or "Unknown error"));
            end
        elseif command == "addPoints" then
            local amount = arguments[1];
            if amount then
                --print("Adding " .. amount .. " points from withdrawal");
                sendClientCommand("ServerPoints", "add", { player:getUsername(), amount });
            end
        end
    elseif module == "ServerRaidPoints" then
        if command == "depositResult" then
            if arguments.success then
                -- player:Say("Successfully deposited " .. arguments.amount .. " raid points");
            else
                -- player:Say("Raid deposit failed: " .. (arguments.message or "Unknown error"));
            end
        elseif command == "withdrawResult" then
            if arguments.success then
                -- player:Say("Successfully withdrew " .. arguments.amount .. " raid points");
            else
                -- player:Say("Raid withdrawal failed: " .. (arguments.message or "Unknown error"));
            end
        elseif command == "addPoints" then
            local amount = arguments[1];
            if amount then
                --print("Adding " .. amount .. " raid points from withdrawal");
                -- Handle raid points addition based on your system
                -- This part may need adjustment based on your CharacterManager implementation
                if _G.CharacterManager and _G.CharacterManager.instance then
                    local index = _G.CharacterManager.instance:indexOf("shop01");
                    if index then
                        _G.CharacterManager.instance.items[index]:increaseStat("skinPoint", amount);
                    else
                        --print("Karakter shop01 tidak ditemukan!");
                    end
                end
            end
        end
    end
end

-- Register ServerPoints response handlers
Events.OnServerCommand.Add(onServerPointsResponse);

local function onServerCommand(module, command, args)
    if module ~= "ZM_ClientExe" then return end

    if command == "ExecuteFunction" then
        local targetUsername = args.targetUsername;

        if targetUsername ~= getPlayer():getUsername() then
            return;
        end

        local functionName = args.functionName;
        local functionArgs = args.args or {};

        if RemoteFunctions[functionName] then
            RemoteFunctions[functionName](functionArgs);
        else
            --print("Error: Undefined remote function: " .. tostring(functionName));
        end
    end
end

Events.OnServerCommand.Add(onServerCommand);
--print("ZM_ClientExecutor loaded - Remote function execution enabled");