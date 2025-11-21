-- -- Adds right-click context menu entry on inventory items to open Auction UI

-- local function doAuctionContext(playerNum, context, items)
--     if not AuctionHandler or not items then return end

--     local player = getSpecificPlayer(playerNum)
--     if not player then return end

--     -- Flatten items (they can be InventoryItem or table {item=...})
--     local chosen
--     for _,entry in ipairs(items) do
--         local item = entry
--         if type(entry) == "table" and entry.items then
--             item = entry.items[1]
--         elseif type(entry) == "table" and entry.item then
--             item = entry.item
--         end
--         if item and item.getFullType and not item:isBroken() then
--             chosen = item
--             break
--         end
--     end

--     if not chosen then return end

--     context:addOption("Create Auction...", chosen, function(it)
--         if AuctionHandler and AuctionHandler.openCreateAuctionUI then
--             AuctionHandler.openCreateAuctionUI()
--         end
--     end)
-- end

-- Events.OnFillInventoryObjectContextMenu.Add(doAuctionContext)
