ZM_IsolationZone = ZM_IsolationZone or {}

ZM_IsolationZone.Coordinates = {
    Entrance1 = { x = 100, y = 200, z = 0 },
    Entrance2 = { x = 150, y = 250, z = 0 },
    Exit = { x = 300, y = 400, z = 0 }
}

ZM_IsolationZone.entranceTrigger = function(player)
    -- Code to handle entrance trigger
end


-- local function ZM_IsolationOnPreFillInventoryObjectContextMenu(playerNum, context, items)
--   -- this are itemIds not itemName
--   validItems = {
--       "Base.Axe",
--       "RMWeapons.ApocalypseRelic",
--   }

--   for _, item in ipairs(items) do
--       if validItems[item:getName()] then
--           context:addOption("Offer to Forest Spirit", item, ZM_IsolationZone.OfferingLogic(item))
--       end
--   end

-- end


ZM_IsolationZone.OfferingLogic = function(item)
  local player = getPlayer()
  if not player then return end

  player:getInventory():Remove(item)
  player:getInventory():AddItem("Base.Coin")
  player:Say("You offered the item to the forest spirit!")
end

Events.OnPreFillInventoryObjectContextMenu.Add(ZM_IsolationOnPreFillInventoryObjectContextMenu)