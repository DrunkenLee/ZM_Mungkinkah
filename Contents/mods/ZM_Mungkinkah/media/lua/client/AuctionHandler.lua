--***********************************************************
--**               AUCTION HANDLER CLIENT                 **
--**          Client-side auction functionality           **
--***********************************************************

AuctionHandler = AuctionHandler or {}

-- Require UI panel
local ISAuctionCreateUI = ISAuctionCreateUI or require("ISUI/ISAuctionCreateUI")

-- Function to open the auction creation UI
function AuctionHandler.openCreateAuctionUI()
    if ISAuctionCreateUI then
        ISAuctionCreateUI.open()
    else
        print("[AuctionHandler] ISAuctionCreateUI not found")
    end
end

-- Function to create auction listing from inventory item
function AuctionHandler.createAuctionListing(item, startingPrice, buyoutPrice, duration)
    local player = getPlayer()
    if not player or not item then
        print("[AuctionHandler] ERROR: Invalid player or item")
        return false
    end

    -- Validate parameters
    startingPrice = tonumber(startingPrice) or 1
    buyoutPrice = tonumber(buyoutPrice) or startingPrice * 2
    duration = tonumber(duration) or 24 -- default 24 hours

    if startingPrice <= 0 or buyoutPrice <= 0 or duration <= 0 then
        player:Say("Invalid auction parameters. Please check your values.")
        return false
    end

    if buyoutPrice < startingPrice then
        player:Say("Buyout price must be higher than starting price.")
        return false
    end

    -- Get item data
    local itemData = {
        itemType = item:getFullType(),
        itemName = item:getDisplayName(),
        itemID = tostring(item:getID()),
        condition = item:getCondition(),
        -- uses = item:getUsedDelta(),
        weight = item:getWeight(),
        category = item:getCategory(),
        -- Add more item properties as needed
        customName = item:getName(),
        tooltip = item:getTooltip()
    }


    -- Get item modData if exists
    local modData = item:getModData()
    if modData then
        itemData.modData = {}
        for key, value in pairs(modData) do
            itemData.modData[key] = value
        end
    end

    -- Create auction data
    local auctionData = {
        sellerUsername = player:getUsername(),
        sellerSteamID = player:getSteamID(),
        itemData = itemData,
        startingPrice = startingPrice,
        buyoutPrice = buyoutPrice,
        currentBid = startingPrice,
        duration = duration,
        timestamp = os.time(),
        description = "",
        isActive = true
    }


    -- if itemData.condition < 100 then
    --     player:Say("Only list pristine item on auction.")
    --     return false
    -- end

    print("[AuctionHandler] Creating auction listing for: " .. itemData.itemName)

    -- Send to server for HTTP request
    sendClientCommand("PlayerAuction", "createListing", auctionData)

    return true
end

-- Function to create auction from equipped item
function AuctionHandler.createAuctionFromEquipped(bodyLocation, startingPrice, buyoutPrice, duration)
    local player = getPlayer()
    if not player then return false end

    local item = player:getWornItem(bodyLocation)
    if not item then
        player:Say("No item equipped in " .. bodyLocation)
        return false
    end

    return AuctionHandler.createAuctionListing(item, startingPrice, buyoutPrice, duration)
end

function AuctionHandler.createAuctionFromHand(startingPrice, buyoutPrice, duration)
    local player = getPlayer()
    if not player then return false end

    local item = player:getPrimaryHandItem()
    if not item then
        player:Say("No item in primary hand")
        return false
    end

    return AuctionHandler.createAuctionListing(item, startingPrice, buyoutPrice, duration)
end

-- Simple helper to request listing of AuctionLog files
function AuctionHandler.dumpAuctionLogDir()
    local player = getPlayer()
    if player then player:Say("Requesting AuctionLog dump...") end
    sendClientCommand("PlayerAuction", "listAuctionFiles", {})
end

-- Extend server command handler to display result of list
local function onAuctionServerCommand(module, command, args)
    if module ~= "PlayerAuction" then return end

    local player = getPlayer()
    if not player then return end

    if command == "listAuctionFilesResult" then
        local files = (args and args.files) or {}
        player:Say("AuctionLog: " .. tostring(#files) .. " file(s)")
        print("[AuctionHandler] AuctionLog directory dump (" .. tostring(#files) .. "):")
        for i = 1, #files do
            print(string.format("  [%02d] %s", i, tostring(files[i])))
        end
        return
    end

    if command == "listingResult" then
        if args.success then
            player:Say("Auction listing created successfully! ID: " .. (args.auctionID or "Unknown"))
            print("[AuctionHandler] Auction created with ID: " .. (args.auctionID or "Unknown"))

            -- Remove item from inventory if server confirms
            if args.removeItemID then
                local inventory = player:getInventory()
                local items = inventory:getItems()
                for i = 0, items:size() - 1 do
                    local item = items:get(i)
                    if tostring(item:getID()) == args.removeItemID then
                        -- If the item is currently equipped in hands, unequip it first
                        local primary = player:getPrimaryHandItem()
                        if primary and tostring(primary:getID()) == args.removeItemID then
                            player:setPrimaryHandItem(nil)
                        end
                        local secondary = player:getSecondaryHandItem()
                        if secondary and tostring(secondary:getID()) == args.removeItemID then
                            player:setSecondaryHandItem(nil)
                        end

                        -- Finally remove from inventory
                        inventory:Remove(item)

                        -- Ensure visual/equipment state is refreshed
                        if player.resetEquippedHandsModels then
                            player:resetEquippedHandsModels()
                        end

                        print("[AuctionHandler] Unequipped and removed item: " .. item:getDisplayName())
                        break
                    end
                end
            end
        else
            player:Say("Failed to create auction: " .. (args.message or "Unknown error"))
            print("[AuctionHandler] Auction creation failed: " .. (args.message or "Unknown error"))
        end
    elseif command == "auctionNotification" then
        -- Handle auction notifications (bids, purchases, etc.)
        if args.message then
            player:Say("[AUCTION] " .. args.message)
        end
    elseif command == "testCreate" then
        -- Handle test auction creation
        player:Say("Creating test auction for: " .. args.itemType)

        -- Create a mock item for testing
        local testItemData = {
            itemType = args.itemType,
            itemName = args.itemType,
            itemID = "test_" .. os.time(),
            condition = 1.0,
            uses = 0,
            weight = 1.0,
            category = "Weapon"
        }

        local auctionData = {
            sellerUsername = player:getUsername(),
            sellerSteamID = player:getSteamID(),
            itemData = testItemData,
            startingPrice = args.startingPrice,
            buyoutPrice = args.buyoutPrice,
            currentBid = args.startingPrice,
            duration = args.duration,
            timestamp = os.time(),
            isActive = true
        }
        print(auctionData)
        sendClientCommand("PlayerAuction", "createListing", auctionData)
    elseif command == "requestList" then
        -- Handle auction list request
        player:Say("Requesting auction list from API...")
        sendClientCommand("PlayerAuction", "getAuctions", {})
    elseif command == "auctionList" then
        -- Handle auction list response
        if args.success then
            player:Say("Received auction list - check server logs for details")
        else
            player:Say("Failed to get auction list: " .. (args.message or "Unknown error"))
        end
    elseif command == "deliverItem" then
        local itemType = args.itemType
        if not itemType then return end

        local reason = tostring(args.reason or args.status or "win")
        local price = tonumber(args.price) or 0

        local inv = player:getInventory()
        local item = InventoryItemFactory.CreateItem(itemType)
        if not item then
            player:Say("Delivery failed: cannot create item " .. tostring(itemType) .. ". Contact admin.")
            return
        end

        -- Only charge points if this is a winning delivery (not expired/cancelled)
        if reason ~= "expired" and reason ~= "cancelled" then
            if price <= 0 then
                -- No price provided; treat as free or logged error
                print("[AuctionHandler] deliverItem without valid price; skipping point deduction")
            else
                local username = player:getUsername()
                local playerServerPoints = GlobalMethods.getPlayerPoints(username) or 0
                if playerServerPoints == 0 then
                    -- try once more to refresh
                    playerServerPoints = GlobalMethods.getPlayerPoints(username) or 0
                end

                GlobalMethods.takePlayerPoints(username, price)
            end
        else
            -- Expired/cancelled: do not deduct points
            print("[AuctionHandler] deliverItem reason is '" .. reason .. "' — skipping point deduction")
        end

        -- Apply basic itemData
        local idata = args.itemData or {}
        if idata.customName and item.setName then
            item:setName(tostring(idata.customName))
        end
        if idata.condition and item.setCondition then
            local cond = tonumber(idata.condition) or item:getCondition()
            item:setCondition(math.max(0, math.min(100, cond)))
        end

        -- Apply modData (direct copy)
        local m = args.modData or {}
        if m and type(m) == "table" then
            local md = item:getModData()
            for k, v in pairs(m) do md[k] = v end
        end

        -- If weapon and savedDamageValues given, try to apply
        if item:IsWeapon() then
            local md = item:getModData()
            local minD = (idata.enchantMinDamage or idata.originalMinDamage)
            local maxD = (idata.enchantMaxDamage or idata.originalMaxDamage)
            if md and md.savedDamageValues then
                if type(md.savedDamageValues.minDamage) == "number" then minD = md.savedDamageValues.minDamage end
                if type(md.savedDamageValues.maxDamage) == "number" then maxD = md.savedDamageValues.maxDamage end
            end
            if type(minD) == "number" and item.setMinDamage then item:setMinDamage(minD) end
            if type(maxD) == "number" and item.setMaxDamage then item:setMaxDamage(maxD) end
        end

        inv:AddItem(item)
        local msg = (reason == "expired" or reason == "cancelled") and "Returned (expired)" or "Delivered"
        player:Say(msg .. ": " .. (item:getDisplayName() or itemType))
        getSoundManager():PlaySound("cekring", false, 1.0)
    end
end

Events.OnServerCommand.Add(onAuctionServerCommand)

function AuctionHandler.showAuctionDialog(item)
    return AuctionHandler.createAuctionListing(item, 100, 200, 24)
end

function AuctionHandler.quickAuction(item, multiplier)
    multiplier = tonumber(multiplier) or 1

    -- Safely get a base price; some items may not implement getBasePrice
    local base = 1000
    if item and type(item.getBasePrice) == "function" then
        local v = item:getBasePrice()
        if type(v) == "number" then
            base = v
        end
    end

    local basePrice = math.max(1, math.floor(base * multiplier))
    return AuctionHandler.createAuctionListing(item, basePrice, basePrice * 2, 24)
end

-- Test function for console
function AuctionHandler.testAuction()
    local player = getPlayer()
    if not player then return end

    local item = player:getPrimaryHandItem()
    if item then
        player:Say("Testing auction with item in hand: " .. item:getDisplayName())
        return AuctionHandler.quickAuction(item, 1.5)
    else
        player:Say("Hold an item to test auction functionality")
        return false
    end
end

print("[AuctionHandler] Client auction handler loaded successfully")
