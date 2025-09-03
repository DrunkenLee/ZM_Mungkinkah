-- Context Menu for Mystic Orb Binding
local ZM_Ticket = {}
ZM_Ticket.availableTypes = {
    "mechanical_boost",
    "car_repair"
}
local ETWCombinedTraitChecks = require "ETWCombinedTraitChecks";
local ETWCommonLogicChecks = require "ETWCommonLogicChecks";
local ETWCommonFunctions = require "ETWCommonFunctions";

ZM_Ticket.UseMechanicalBoostTicket = function(playerObj, itemID)

    if not playerObj then
        print("ERROR: Player is nil in UseMechanicalBoostTicket.")
        return
    end

    if not itemID then
        print("ERROR: Item is nil in UseMechanicalBoostTicket.")
        return
    end

    local ticketID = "ZM_Ticket_" .. itemID .. playerObj:getUsername()


    print("DEBUG: Starting mechanical boost ticket usage..." .. ticketID)

    playerObj:Say("Using mechanical boost ticket...")

    ZM_Ticket.useTicket(playerObj, ticketID, "mechanical_boost")
end

ZM_Ticket.UseCarpentryBoostTicket = function(playerObj, itemID)
    if not playerObj then
        print("ERROR: Player is nil in UseCarpentryBoostTicket.")
        return
    end

    if not itemID then
        print("ERROR: Item is nil in UseCarpentryBoostTicket.")
        return
    end

    local ticketID = "ZM_Ticket_" .. itemID .. playerObj:getUsername()


    print("DEBUG: Starting carpentry boost ticket usage..." .. ticketID)

    playerObj:Say("Using carpentry boost ticket...")

    ZM_Ticket.useTicket(playerObj, ticketID, "carpentry_boost")
end

ZM_Ticket.UseElectronicsBoostTicket = function(playerObj, itemID)
    if not playerObj then
        print("ERROR: Player is nil in UseElectronicsBoostTicket.")
        return
    end

    if not itemID then
        print("ERROR: Item is nil in UseElectronicsBoostTicket.")
        return
    end

    local ticketID = "ZM_Ticket_" .. itemID .. playerObj:getUsername()


    print("DEBUG: Starting electronics boost ticket usage..." .. ticketID)

    playerObj:Say("Using electronics boost ticket...")

    ZM_Ticket.useTicket(playerObj, ticketID, "electronics_boost")
end

ZM_Ticket.UseMetalWeldingBoostTicket = function(playerObj, itemID)
    if not playerObj then
        print("ERROR: Player is nil in UseMetalWeldingBoostTicket.")
        return
    end

    if not itemID then
        print("ERROR: Item is nil in UseMetalWeldingBoostTicket.")
        return
    end

    local ticketID = "ZM_Ticket_" .. itemID .. playerObj:getUsername()


    print("DEBUG: Starting metal welding boost ticket usage..." .. ticketID)

    playerObj:Say("Using metal welding boost ticket...")

    ZM_Ticket.useTicket(playerObj, ticketID, "metal_welding_boost")
end

ZM_Ticket.UseCookingBoostTicket = function(playerObj, itemID)
    if not playerObj then
        print("ERROR: Player is nil in UseCookingBoostTicket.")
        return
    end

    if not itemID then
        print("ERROR: Item is nil in UseCookingBoostTicket.")
        return
    end

    local ticketID = "ZM_Ticket_" .. itemID .. playerObj:getUsername()


    print("DEBUG: Starting cooking boost ticket usage..." .. ticketID)

    playerObj:Say("Using cooking boost ticket...")

    ZM_Ticket.useTicket(playerObj, ticketID, "cooking_boost")
end

ZM_Ticket.UseFarmingBoostTicket = function(playerObj, itemID)
    if not playerObj then
        print("ERROR: Player is nil in UseFarmingBoostTicket.")
        return
    end

    if not itemID then
        print("ERROR: Item is nil in UseFarmingBoostTicket.")
        return
    end

    local ticketID = "ZM_Ticket_" .. itemID .. playerObj:getUsername()


    print("DEBUG: Starting farming boost ticket usage..." .. ticketID)

    playerObj:Say("Using farming boost ticket...")

    ZM_Ticket.useTicket(playerObj, ticketID, "farming_boost")
end

ZM_Ticket.UseTailoringBoostTicket = function(playerObj, itemID)
    if not playerObj then
        print("ERROR: Player is nil in UseTailoringBoostTicket.")
        return
    end

    if not itemID then
        print("ERROR: Item is nil in UseTailoringBoostTicket.")
        return
    end

    local ticketID = "ZM_Ticket_" .. itemID .. playerObj:getUsername()


    print("DEBUG: Starting tailoring boost ticket usage..." .. ticketID)

    playerObj:Say("Using tailoring boost ticket...")

    ZM_Ticket.useTicket(playerObj, ticketID, "tailoring_boost")
end

ZM_Ticket.UseFirstAidBoostTicket = function(playerObj, itemID)
    if not playerObj then
        print("ERROR: Player is nil in UseFirstAidBoostTicket.")
        return
    end

    if not itemID then
        print("ERROR: Item is nil in UseFirstAidBoostTicket.")
        return
    end

    local ticketID = "ZM_Ticket_" .. itemID .. playerObj:getUsername()


    print("DEBUG: Starting first aid boost ticket usage..." .. ticketID)

    playerObj:Say("Using first aid boost ticket...")

    ZM_Ticket.useTicket(playerObj, ticketID, "firstaid_boost")
end

ZM_Ticket.isTicketUsed = function(playerObj, ticketID, item, ticketType)
    if not playerObj then
        print("ERROR: Player is nil in isTicketUsed.")
        return
    end

    if not ticketID then
        print("ERROR: Ticket ID is nil in isTicketUsed.")
        return
    end
    print("DEBUG: PRINTING PAYLOAD IN isTicketUsed")
    print("DEBUG: Ticket ID: " .. ticketID)
    print("DEBUG: Ticket Type: " .. (ticketType or "nil"))

    local inventory = playerObj:getInventory()
    inventory:Remove(item)
    sendClientCommand(playerObj, "ZM_Ticket", "checkusedticket", {
        ticketID = ticketID,
        ticketType = ticketType
    })
end

ZM_Ticket.useTicket = function(playerObj, ticketID, ticketType)  -- Changed parameter name
    local player = playerObj

    if not player then
        print("ERROR: Player is nil in useTicket.")
        return
    end

    print("DEBUG: Using ticket...")
    print("DEBUG: Ticket ID: " .. ticketID)
    -- print("DEBUG: Item: " .. (item and item:getFullType() or "nil"))
    print("DEBUG: Ticket Type: " .. (ticketType or "nil"))

    sendClientCommand(player, "ZM_Ticket", "addusedticket", {
        ticketID = ticketID,
        ticketType = ticketType,
        username = player:getUsername() or "ZM_User_Unknown"
    })

    if ticketType == "mechanical_boost" then
        -- Logic here
        ETWCommonFunctions.applyXPBoost(player, Perks.Mechanics, 10);
        -- PlayerTierHandler.giveBookXPBoost(player, "Mechanics")
        getSoundManager():PlaySound("rganvilsuccess", false, 1.0)

    elseif ticketType == "car_repair" then
        -- Logic here
        local playerId = player:getOnlineID()
        setLastRepairTime(playerId, true)
        getSoundManager():PlaySound("rganvilsuccess", false, 1.0)

    elseif ticketType == "firstaid_boost" then
        -- Logic here`
        PlayerTierHandler.giveBookXPBoost(player, "FirstAid")
        getSoundManager():PlaySound("rganvilsuccess", false, 1.0)

    elseif ticketType == "tailoring_boost" then
        -- Logic here
        ETWCommonFunctions.applyXPBoost(player, Perks.Tailoring, 10);
        -- PlayerTierHandler.giveBookXPBoost(player, "Tailoring")
        getSoundManager():PlaySound("rganvilsuccess", false, 1.0)

    elseif ticketType == "farming_boost" then
        -- Logic here
        ETWCommonFunctions.applyXPBoost(player, Perks.Farming, 10);
        -- PlayerTierHandler.giveBookXPBoost(player, "Farming")
        getSoundManager():PlaySound("rganvilsuccess", false, 1.0)

    elseif ticketType == "cooking_boost" then
        -- Logic here
        ETWCommonFunctions.applyXPBoost(player, Perks.Cooking, 10);
        -- PlayerTierHandler.giveBookXPBoost(player, "Cooking")
        getSoundManager():PlaySound("rganvilsuccess", false, 1.0)

    elseif ticketType == "metal_welding_boost" then
        -- Logic here
        ETWCommonFunctions.applyXPBoost(player, Perks.MetalWelding, 10);
        -- PlayerTierHandler.giveBookXPBoost(player, "MetalWelding")
        getSoundManager():PlaySound("rganvilsuccess", false, 1.0)

    elseif ticketType == "carpentry_boost" then
        -- Logic here
        ETWCommonFunctions.applyXPBoost(player, Perks.Carpentry, 10);
        -- PlayerTierHandler.giveBookXPBoost(player, "Carpentry")
        getSoundManager():PlaySound("rganvilsuccess", false, 1.0)

    elseif ticketType == "electronics_boost" then
        -- Logic here
        ETWCommonFunctions.applyXPBoost(player, Perks.Electronics, 10);
        -- PlayerTierHandler.giveBookXPBoost(player, "Electronics")
        getSoundManager():PlaySound("rganvilsuccess", false, 1.0)

    end
end

local function addContextToCheckTicket(playerNum, context, items)

  local playerObj = getSpecificPlayer(0)
  if not playerObj then return end

  for _, v in ipairs(items) do

      if instanceof(v, "InventoryItem") then

          local item = v
          print("Found direct item: " .. item:getFullType())
          print(item:getID())
          local itemType = item:getFullType()
          local payload = {}

          if itemType == "ZM_Mungkinkah.ZM_PermanentMechanicalBoostTicket" then
              local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
              context:addOption("Use Mechanical Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "mechanical_boost")
          end

          if itemType == "ZM_Mungkinkah.ZM_CarRepairTicket" then
              local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
              context:addOption("Use Car Repair Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "car_repair")
          end

          if itemType == "ZM_Mungkinkah.ZM_PermanentFirstAidBoostTicket" then
              local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
              context:addOption("Use First Aid Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "firstaid_boost")
          end

          if itemType == "ZM_Mungkinkah.ZM_PermanentTailoringBoostTicket" then
              local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
              context:addOption("Use Tailoring Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "tailoring_boost")
          end

          if itemType == "ZM_Mungkinkah.ZM_PermanentFarmingBoostTicket" then
              local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
              context:addOption("Use Farming Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "farming_boost")
          end

          if itemType == "ZM_Mungkinkah.ZM_PermanentCookingBoostTicket" then
              local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
              context:addOption("Use Cooking Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "cooking_boost")
          end

          if itemType == "ZM_Mungkinkah.ZM_PermanentMetalWeldingBoostTicket" then
              local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
              context:addOption("Use Metal Welding Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "metal_welding_boost")
          end

          if itemType == "ZM_Mungkinkah.ZM_PermanentElectronicsBoostTicket" then
              local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
              context:addOption("Use Electronics Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "electronics_boost")
          end

          if itemType == "ZM_Mungkinkah.ZM_PermanentCarpentryBoostTicket" then
              local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
              context:addOption("Use Carpentry Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "carpentry_boost")
          end

      elseif v.items and #v.items > 0 then
          local item = v.items[1]
          if instanceof(item, "InventoryItem") then
              local itemType = item:getFullType()

              if itemType == "ZM_Mungkinkah.ZM_PermanentMechanicalBoostTicket" then
                  local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
                  context:addOption("Use Mechanical Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "mechanical_boost")
              end

              if itemType == "ZM_Mungkinkah.ZM_CarRepairTicket" then
                  local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
                  context:addOption("Use Car Repair Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "car_repair")
              end

              if itemType == "ZM_Mungkinkah.ZM_PermanentFirstAidBoostTicket" then
                  local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
                  context:addOption("Use First Aid Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "firstaid_boost")
              end

              if itemType == "ZM_Mungkinkah.ZM_PermanentTailoringBoostTicket" then
                  local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
                  context:addOption("Use Tailoring Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "tailoring_boost")
              end

              if itemType == "ZM_Mungkinkah.ZM_PermanentFarmingBoostTicket" then
                  local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
                  context:addOption("Use Farming Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "farming_boost")
              end

              if itemType == "ZM_Mungkinkah.ZM_PermanentCookingBoostTicket" then
                  local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
                  context:addOption("Use Cooking Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "cooking_boost")
              end

              if itemType == "ZM_Mungkinkah.ZM_PermanentMetalWeldingBoostTicket" then
                  local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
                  context:addOption("Use Metal Welding Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "metal_welding_boost")
              end

              if itemType == "ZM_Mungkinkah.ZM_PermanentElectronicsBoostTicket" then
                  local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
                  context:addOption("Use Electronics Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "electronics_boost")
              end

              if itemType == "ZM_Mungkinkah.ZM_PermanentCarpentryBoostTicket" then
                  local ticketID = "ZM_Ticket_" .. item:getID() .. playerObj:getUsername()
                  context:addOption("Use Carpentry Boost Ticket", playerObj, ZM_Ticket.isTicketUsed, ticketID, item, "carpentry_boost")
              end

          end

      end
  end
end

Events.OnFillInventoryObjectContextMenu.Add(addContextToCheckTicket)

Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "ZM_Ticket" then return end

    local player = getSpecificPlayer(0)
    if not player then
        print("ERROR: Cannot get player in OnServerCommand handler")
        return
    end

    if command == "isTicketUsedResponse" then
        local ticketID = args.ticketID
        local used = args.used
        local username = args.username
        local ticketType = args.ticketType

        -- if not ticketID then
        --     print("ERROR: Missing ticketID in isTicketUsedResponse")
        --     return
        -- end

        if used then
            print("DEBUG: Ticket " .. ticketID .. " has already been used"
                  .. (username and " by " .. username or ""))
            player:Say("This ticket has already been used.")
        else
            print("DEBUG: Ticket is available for use.")

            if ticketType == "mechanical_boost" then
                player:Say("using permanent mechanical boost ticket.")
                ZM_Ticket.useTicket(player, ticketID, "mechanical_boost")

            elseif ticketType == "car_repair" then
                player:Say("using car repair ticket.")
                ZM_Ticket.useTicket(player, ticketID, "car_repair")

            elseif ticketType == "firstaid_boost" then
                player:Say("using first aid boost ticket.")
                ZM_Ticket.useTicket(player, ticketID, "firstaid_boost")

            elseif ticketType == "tailoring_boost" then
                player:Say("using tailoring boost ticket.")
                ZM_Ticket.useTicket(player, ticketID, "tailoring_boost")

            elseif ticketType == "farming_boost" then
                player:Say("using farming boost ticket.")
                ZM_Ticket.useTicket(player, ticketID, "farming_boost")

            elseif ticketType == "cooking_boost" then
                player:Say("using cooking boost ticket.")
                ZM_Ticket.useTicket(player, ticketID, "cooking_boost")

            elseif ticketType == "metal_welding_boost" then
                player:Say("using metal welding boost ticket.")
                ZM_Ticket.useTicket(player, ticketID, "metal_welding_boost")

            elseif ticketType == "electronics_boost" then
                player:Say("using electronics boost ticket.")
                ZM_Ticket.useTicket(player, ticketID, "electronics_boost")

            elseif ticketType == "carpentry_boost" then
                player:Say("using carpentry boost ticket.")
                ZM_Ticket.useTicket(player, ticketID, "carpentry_boost")

            end
        end
    elseif command == "saveusedticketsresponse" then
        print("DEBUG: Received confirmation that ticket usage data was saved")
        player:Say("Ticket usage data has been saved.")
    end

end)