--- Client execution command - allows server to remotely execute functions on client machines
---
--- @author GitHub Copilot

-- Import these modules to register and execute LuaCommands.
require 'LuaCommands/LuaCommands';
local ServerUtils = require 'ExtraCommands/ServerUtils';

--- Command name
--- @type string
local CMD_NAME = 'clientexe';

--- Executes the command when fired in a Single-Player environment.
---
--- @param args string[] Any arguments passed with the command.
local function onSinglePlayerCommand(args)
    return 'Command not supported in single-player mode.';
end

--- Executes the command when fired in a Server environment.
---
--- @param author string The username of the player that executed the command, or 'admin' if console or RCON.
--- @param args string[] Any arguments passed with the command.
local function onServerCommand(author, args)
    local helper = LuaServerCommandHandler;

    if not args[1] or not args[2] then
        return "Usage: /clientexe <username> <functionName> [args...]";
    end

    local username = args[1];
    local functionName = args[2];

    -- We no longer need to get the player object
    -- Just check if the player exists in the server's player list
    -- if not getPlayerFromUsername(username) then
    --     return "Player not found: " .. username;
    -- end

    -- Create a table for any additional arguments
    local functionArgs = {};
    for i = 3, #args do
        table.insert(functionArgs, args[i]);
    end

    -- Send the function execution request to ALL clients
    -- but include the target username in the data
    sendServerCommand("ZM_ClientExe", "ExecuteFunction", {
        targetUsername = username,
        functionName = functionName,
        args = functionArgs
    });

    return "Instructed " .. username .. " to execute function: " .. functionName;
end

-- Register the command here.
LuaCommands.register(CMD_NAME, function(author, command, args)
    if isClient() then
        return nil
    elseif isServer() then
        return onServerCommand(author, args)
    end
    return onSinglePlayerCommand(args);
end);

-- Print to the console to see if this file is valid and executed.
print('Registered LuaCommand: ' .. CMD_NAME);