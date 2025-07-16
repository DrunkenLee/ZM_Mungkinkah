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
            print("Error: No flag name provided.");
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
            print("Error: No flag name provided.");
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
            print("Error: PlayerFlagHandler not found in global scope");
            return;
        end

        local player = getSpecificPlayer(0);
        if not args[1] then
            print("Error: No flag name provided.");
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
            print("Error: No hours value provided.");
            return;
        end

        local hours = tonumber(args[1]);
        if not hours then
            print("Error: Invalid hours value provided.");
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
            print("Error: No zombie kills value provided.");
            return;
        end

        local kills = tonumber(args[1]);
        if not kills then
            print("Error: Invalid zombie kills value provided.");
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
            print("Error: Missing parameters. Usage: debugapplyenchant <minDMG> <maxDMG> <enchantment> <name>");
            return;
        end

        local minDMG = tonumber(args[1]);
        local maxDMG = tonumber(args[2]);
        local enchantment = tonumber(args[3]);
        local name = args[4];

        if not minDMG or not maxDMG or not enchantment then
            print("Error: Invalid numeric values provided for minDMG, maxDMG, or enchantment.");
            return;
        end

        if player then
            if _G.DebugApplyEnchantment then
                _G.DebugApplyEnchantment(minDMG, maxDMG, enchantment, name);
                player:Say("Applied enchantment: " .. enchantment .. " to weapon for " .. name);
            else
                print("Error: DebugApplyEnchantment function not found in global scope");
            end
        end
    end,

    setserverwideflag = function(args)
        local player = getSpecificPlayer(0);
        if not args[1] or not args[2] then
            print("Error: Missing parameters. Usage: setserverwideflag <flagName> <value>");
            return;
        end

        local flagName = args[1];
        local flagValue = tonumber(args[2]);

        if not flagValue then
            print("Error: Invalid flag value provided. Must be a number.");
            return;
        end

        if player then
            if _G.ZMServerwideFlagHandler and _G.ZMServerwideFlagHandler.consoleSetFlag then
                _G.ZMServerwideFlagHandler.consoleSetFlag(flagName, flagValue);
                player:Say("Set serverwide flag '" .. flagName .. "' to: " .. flagValue);
            else
                print("Error: ZMServerwideFlagHandler.consoleSetFlag function not found in global scope");
            end
        end
    end,

    -- Add more functions as needed
}


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
            print("Error: Undefined remote function: " .. tostring(functionName));
        end
    end
end

Events.OnServerCommand.Add(onServerCommand);
print("ZM_ClientExecutor loaded - Remote function execution enabled");