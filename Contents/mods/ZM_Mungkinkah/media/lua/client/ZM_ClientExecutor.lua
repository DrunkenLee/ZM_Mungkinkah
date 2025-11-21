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

    ----------------------------------------- Quest Management Functions -----------------------------------------
    resetquest = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] then
            --print("Error: Missing parameters. Usage: resetquest <username> <questID>");
            return;
        end

        local username = args[1];
        local questID = args[2];

        if player then
            if SendQuestRequestToServer and SendQuestRequestToServer.reset then
                SendQuestRequestToServer.reset(username, questID);
                player:Say("Reset quest '" .. questID .. "' for player: " .. username);
            else
                player:Say("SendQuestRequestToServer.reset not available");
                --print("Error: SendQuestRequestToServer.reset function not found");
            end
        end
    end,

    lockquest = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] then
            --print("Error: Missing parameters. Usage: lockquest <username> <questID>");
            return;
        end

        local username = args[1];
        local questID = args[2];

        if player then
            if SendQuestRequestToServer and SendQuestRequestToServer.lock then
                SendQuestRequestToServer.lock(username, questID);
                player:Say("Locked quest '" .. questID .. "' for player: " .. username);
            else
                player:Say("SendQuestRequestToServer.lock not available");
                --print("Error: SendQuestRequestToServer.lock function not found");
            end
        end
    end,

    unlockquest = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] then
            --print("Error: Missing parameters. Usage: unlockquest <username> <questID>");
            return;
        end

        local username = args[1];
        local questID = args[2];

        if player then
            if SendQuestRequestToServer and SendQuestRequestToServer.unlock then
                SendQuestRequestToServer.unlock(username, questID);
                player:Say("Unlocked quest '" .. questID .. "' for player: " .. username);
            else
                player:Say("SendQuestRequestToServer.unlock not available");
                --print("Error: SendQuestRequestToServer.unlock function not found");
            end
        end
    end,
    ----------------------------------------- End of Quest Management Functions -----------------------------------------

    ----------------------------------------- Task Management Functions -----------------------------------------
    unlocktask = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] or not args[3] then
            --print("Error: Missing parameters. Usage: unlocktask <username> <questID> <taskID>");
            return;
        end

        local username = args[1];
        local questID = args[2];
        local taskID = args[3];

        if player then
            if SendTaskRequestToServer and SendTaskRequestToServer.unlock then
                SendTaskRequestToServer.unlock(username, questID, taskID);
                player:Say("Unlocked task '" .. taskID .. "' in quest '" .. questID .. "' for player: " .. username);
            else
                player:Say("SendTaskRequestToServer.unlock not available");
                --print("Error: SendTaskRequestToServer.unlock function not found");
            end
        end
    end,

    locktask = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] or not args[3] then
            --print("Error: Missing parameters. Usage: locktask <username> <questID> <taskID>");
            return;
        end

        local username = args[1];
        local questID = args[2];
        local taskID = args[3];

        if player then
            if SendTaskRequestToServer and SendTaskRequestToServer.lock then
                SendTaskRequestToServer.lock(username, questID, taskID);
                player:Say("Locked task '" .. taskID .. "' in quest '" .. questID .. "' for player: " .. username);
            else
                player:Say("SendTaskRequestToServer.lock not available");
                --print("Error: SendTaskRequestToServer.lock function not found");
            end
        end
    end,

    completetask = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] or not args[3] then
            --print("Error: Missing parameters. Usage: completetask <username> <questID> <taskID>");
            return;
        end

        local username = args[1];
        local questID = args[2];
        local taskID = args[3];

        if player then
            if SendTaskRequestToServer and SendTaskRequestToServer.complete then
                SendTaskRequestToServer.complete(username, questID, taskID);
                player:Say("Completed task '" .. taskID .. "' in quest '" .. questID .. "' for player: " .. username);
            else
                player:Say("SendTaskRequestToServer.complete not available");
                --print("Error: SendTaskRequestToServer.complete function not found");
            end
        end
    end,

    resettask = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] or not args[3] then
            --print("Error: Missing parameters. Usage: resettask <username> <questID> <taskID>");
            return;
        end

        local username = args[1];
        local questID = args[2];
        local taskID = args[3];

        if player then
            if SendTaskRequestToServer and SendTaskRequestToServer.reset then
                SendTaskRequestToServer.reset(username, questID, taskID);
                player:Say("Reset task '" .. taskID .. "' in quest '" .. questID .. "' for player: " .. username);
            else
                player:Say("SendTaskRequestToServer.reset not available");
                --print("Error: SendTaskRequestToServer.reset function not found");
            end
        end
    end,
    ----------------------------------------- End of Task Management Functions -----------------------------------------

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

    ----------------------------------------- ServerPoints Management Functions -----------------------------------------
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

    dumpPlayerPoints = function(args)
        local player = getSpecificPlayer(0);
        if player then
            sendClientCommand("ServerPoints", "bridge", {})
        end
    end,

    withdrawauctionpoints = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] then
            --print("Error: No username provided.");
            return;
        end

        local username = args[1];

        if player then
            if GlobalMethods and GlobalMethods.withdrawAuctionPoints then
                GlobalMethods.withdrawAuctionPoints(username);
                player:Say("Auction withdrawal request sent for " .. username);
            else
                player:Say("GlobalMethods.withdrawAuctionPoints not available");
                --print("Error: GlobalMethods.withdrawAuctionPoints function not found");
            end
        end
    end,
    -----------------------------------------  End of ServerPoints Management Functions -----------------------------------------

    -- allow can be: true/false, 1/0, "true"/"false", "yes"/"no", "on"/"off"
    setrestrictedgearallow = function(args)
        local player = getSpecificPlayer(0)
        if not args[1] or not args[2] or args[3] == nil then
            --print("Error: Usage setrestrictedgearallow <username> <itemType> <allow>")
            return
        end

        local username = tostring(args[1])
        local itemType = tostring(args[2])
        local allowRaw = args[3]

        local allow = false
        if type(allowRaw) == "boolean" then
            allow = allowRaw
        elseif type(allowRaw) == "number" then
            allow = allowRaw ~= 0
        elseif type(allowRaw) == "string" then
            local s = allowRaw:lower()
            allow = (s == "true" or s == "1" or s == "yes" or s == "on")
        end

        if ZMEquipmentHandler and ZMEquipmentHandler.setRestrictedGearAllow then
            ZMEquipmentHandler.setRestrictedGearAllow(username, itemType, allow)
            if player then
                player:Say(((allow and "Allowed " or "Blocked ") .. itemType .. " for " .. username))
            end
        else
            if player then
                player:Say("Equipment handler not available")
            end
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