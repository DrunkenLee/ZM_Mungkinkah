--***********************************************************
--**               AUCTION TEST COMMAND                   **
--**        Test auction functionality via console        **
--***********************************************************

require 'LuaCommands/LuaCommands'

local CMD_NAME = 'auction'

-- Single player command
local function onSinglePlayerCommand(args)
    return 'Auction command not supported in single-player mode.'
end

-- Server command
local function onServerCommand(author, args)
    if not args[1] then
        return "Usage: /auction <test|create|list> [parameters]"
    end

    local action = args[1]:lower()

    if action == "test" then
        -- Test HTTP connection
        print("[AuctionCommand] Testing HTTP connection...")
        return "Testing auction system HTTP connection - check server logs"

    elseif action == "create" then
        -- Create test auction
        if not args[2] then
            return "Usage: /auction create <username> [itemType] [price]"
        end

        local username = args[2]
        local itemType = args[3] or "Base.Axe"
        local price = tonumber(args[4]) or 100

        local player = getPlayerFromUsername(username)
        if not player then
            return "Player not found: " .. username
        end

        -- Send test auction creation command to player
        sendServerCommand(player, "PlayerAuction", "testCreate", {
            itemType = itemType,
            startingPrice = price,
            buyoutPrice = price * 2,
            duration = 24
        })

        return "Test auction creation sent to " .. username

    elseif action == "list" then
        -- List active auctions
        if not args[2] then
            return "Usage: /auction list <username>"
        end

        local username = args[2]
        local player = getPlayerFromUsername(username)
        if not player then
            return "Player not found: " .. username
        end

        -- Send auction list request
        sendServerCommand(player, "PlayerAuction", "requestList", {})

        return "Auction list request sent to " .. username

    else
        return "Unknown action: " .. action .. ". Use: test, create, or list"
    end
end

-- Register the command
if LuaCommands then
    LuaCommands.register(CMD_NAME, function(author, command, args)
        if isClient() then
            return nil
        elseif isServer() then
            return onServerCommand(author, args)
        end
        return onSinglePlayerCommand(args)
    end)
end

print('Registered LuaCommand: ' .. CMD_NAME)
