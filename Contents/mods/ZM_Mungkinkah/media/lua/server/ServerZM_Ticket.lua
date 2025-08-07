local ServerZM_Ticket = {}
ServerZM_Ticket.MOD_ID = "ZM_Ticket"
ServerZM_Ticket.used = {}  -- Initialize this immediately
ServerZM_Ticket.loaded = true  -- Set to true by default to avoid issues


ServerZM_Ticket.saveData = function()
    -- Use ModData API instead of file I/O for better reliability
    if not ServerZM_Ticket.used then
        ServerZM_Ticket.used = {}
    end

    -- Store data in global ModData which persists across saves
    ModData.add("ZM_Ticket_Used", ServerZM_Ticket.used)
    ModData.transmit("ZM_Ticket_Used") -- Ensure it's transmitted in multiplayer

    print("DEBUG: Saved Ticket usage data to ModData")
    print("DEBUG: Current ticket data:")
    for id, user in pairs(ServerZM_Ticket.used) do
        print("   Ticket: " .. id .. ", User: " .. tostring(user))
    end

    sendServerCommand("ZM_Ticket", "saveusedticketsresponse", {
        usedTickets = ServerZM_Ticket.used
    })
    return true
end

ServerZM_Ticket.loadData = function()
    if ModData.exists("ZM_Ticket_Used") then
        ServerZM_Ticket.used = ModData.get("ZM_Ticket_Used") or {}
    else
        ServerZM_Ticket.used = {}
        ModData.add("ZM_Ticket_Used", ServerZM_Ticket.used)
    end
    ServerZM_Ticket.loaded = true
end


ServerZM_Ticket.addUsedTicket = function(ticketID, username)
    if not ServerZM_Ticket.loaded then
        ServerZM_Ticket.loadData()
    end

    -- Make sure used tickets exists
    if not ServerZM_Ticket.used then
        ServerZM_Ticket.used = {}
    end

    -- Mark the ticket as used
    ServerZM_Ticket.used[ticketID] = username or true  -- Store username if provided, otherwise just true

    -- Debug output to confirm data structure
    print("[ZM_Ticket]: Added ticket:", ticketID, "for user:", username)
    print("[ZM_Ticket]: Current used tickets table contains", tableSize(ServerZM_Ticket.used), "entries")

    ServerZM_Ticket.saveData()
    return true
end

-- Helper function to count table entries (copied from ServerOrbData)
function tableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

ServerZM_Ticket.isTicketUsed = function(ticketID)
    if not ServerZM_Ticket.loaded then
        ServerZM_Ticket.loadData()
    end

    -- Make sure used tickets exists
    if not ServerZM_Ticket.used then
        ServerZM_Ticket.used = {}
        return false
    end

    sendServerCommand("ZM_Ticket", "isTicketUsedResponse", {
        ticketID = ServerZM_Ticket.used[ticketID],
        used = ServerZM_Ticket.used[ticketID] ~= nil
    })
    return ServerZM_Ticket.used[ticketID] or false
end


Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "ZM_Ticket" then
        if command == "addusedticket" then
            local ticketID = args.ticketID
            local ticketType = args.ticketType
            local username = args.username

            -- Add null checks before toString to avoid errors
            print("DEBUG: Received addusedticket command with ticketID: "
                  .. (ticketID and tostring(ticketID) or "nil")
                  .. ", ticketType: " .. (ticketType and tostring(ticketType) or "nil")
                  .. ", username: " .. (username and tostring(username) or "nil"))

            if not ticketID or not ticketType or not username then
                print("ERROR: Missing parameters in addusedticket command.")
                return
            end
            ServerZM_Ticket.addUsedTicket(ticketID, username, ticketType)

        elseif command == "checkusedticket" then
            local ticketID = args.ticketID
            local ticketType = args.ticketType
            if not ticketID then
                print("ERROR: Missing ticketID in checkusedticket command")
                return
            end

            print("DEBUG: Checking if ticket is used: " .. ticketID)

            -- Check if ticket is used
            local isUsed = ServerZM_Ticket.isTicketUsed(ticketID)
            local username = nil

            if type(isUsed) == "string" then
                username = isUsed
                isUsed = true
            end

            -- Send the response back to the client
            sendServerCommand(player, "ZM_Ticket", "isTicketUsedResponse", {
                ticketID = ticketID,
                used = isUsed,
                username = username,
                ticketType = ticketType
            })

            print("DEBUG: Ticket check result for " .. ticketID .. ": " .. tostring(isUsed)
                  .. (username and " by " .. username or "") .. (ticketType and " (" .. ticketType .. ")" or ""))
        end
    end
end)

-- Initialize the used tickets table
Events.OnServerStarted.Add(function()
    ServerZM_Ticket.loadData()
end)

Events.OnGameStart.Add(function()
    ServerZM_Ticket.loadData()
end)

-- CRUCIAL: Return the module so other files can use it
return ServerZM_Ticket