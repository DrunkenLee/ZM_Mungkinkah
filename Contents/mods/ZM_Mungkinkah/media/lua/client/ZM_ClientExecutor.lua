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
        -- Access the global PlayerFlagHandler directly
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

            -- Get current flag value
            local currentValue = false;
            -- Only call getFlagOnPlayer if the function exists
            if _G.PlayerFlagHandler.getFlagOnPlayer then
                currentValue = _G.PlayerFlagHandler.getFlagOnPlayer(username, flagName);
            end

            -- Toggle the flag
            _G.PlayerFlagHandler.setFlagOnPlayer(username, flagName, not currentValue);
            player:Say("ZM Flag '" .. flagName .. "' toggled for player: " .. username);
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