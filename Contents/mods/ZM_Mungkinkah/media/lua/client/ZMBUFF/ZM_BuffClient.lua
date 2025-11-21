-- Only run on client
if isServer() then return end

-- Load moodle handler
local ZM_BuffMoodle
pcall(function()
    ZM_BuffMoodle = require("ZM_BuffMoodle")
end)

ZM_BuffClient = ZM_BuffClient or {}

-- Item configuration list (matches server)
ZM_BuffClient.itemList = {
    {
        name = "Jessica Pill Giant Ox",
        description = "A mystical pill that grants Unlimited carrying capacity for a while.",
        modifier = {
            carryCapacity = 1000,
            durationMinutes = 60,
        },
    },
    {
        name = "Jessica Pill Oak Remedy",
        description = "A mystical pill that reset your body weight to normal.",
        modifier = {
            resetWeight = 75,
        },
    },
}

-- Use item function - sends request to server
ZM_BuffClient.UseItem = function(player, item)
    if not item or not player then
        -- print("[ZM_BuffClient] ERROR: Invalid item or player")
        return
    end

    local itemUID = item:getID()
    local itemName = item:getDisplayName()

    -- Find matching item config
    local itemConfig = nil
    for _, config in ipairs(ZM_BuffClient.itemList) do
        if string.find(itemName, config.name) then
            itemConfig = config
            break
        end
    end

    -- print("[ZM_BuffClient] UseItem called - UID: " .. tostring(itemUID) .. ", Name: " .. tostring(itemName))

    -- Send to server with full item data
    sendClientCommand(player, 'ZM_Buff', 'UseItem', {
        itemUID = itemUID,
        itemName = itemName,
        modifier = itemConfig and itemConfig.modifier or nil
    })
end

-- Handle server responses
local function onServerCommand(module, command, args)
    if module ~= 'ZM_Buff' then return end

    local player = getSpecificPlayer(0)

    if command == 'ShowInfiniteCarryHint' then
        local mins = args and args.minutes or 60
        if player then
            -- player:Say("Giant Ox active. For unlimited carry: open Debug > Cheats > Infinite Carry Weight.")
            if ZM_BuffMoodle then
                ZM_BuffMoodle.activateGiantOx(player, mins)
            end
        end
        return
    end

    if command == 'ApplyWeightReset' then
        if player and args and args.weight then
            local nutrition = player:getNutrition()
            if nutrition then
                nutrition:setWeight(tonumber(args.weight) or 75)
                player:Say("Weight reset to " .. tostring(args.weight) .. " kg.")
                if ZM_BuffMoodle then
                    ZM_BuffMoodle.activateOakRemedy(player)
                end
            end
        end
        return
    end

    if command == 'UseItemResponse' then
        -- Success - item was used
        local itemUID = args.itemUID
        local itemName = args.itemName
        local modifier = args.modifier
        local message = args.message or "Item used successfully!"

        -- print("[ZM_BuffClient] Item used successfully - UID: " .. tostring(itemUID))

        -- Show notification to player
        if player then
            player:Say(message)

            -- Apply effects + visual feedback
            if modifier then
                if modifier.carryCapacity then
                    -- Enable Unlimited Carry (client-side cheat toggle)
                    if player.setUnlimitedCarry then
                        player:setUnlimitedCarry(true)
                        local md = player:getModData()
                        local nowMs = (getTimestampMs and getTimestampMs() or 0)
                        local minutes = tonumber(modifier.durationMinutes) or 60
                        md.ZM_GiantOxEndMs = nowMs + (minutes * 60 * 1000)
                        player:Say("Giant Ox active: Unlimited Carry enabled for " .. tostring(minutes) .. " minutes.")
                    end
                    -- Activate Giant Ox moodle
                    if ZM_BuffMoodle then
                        ZM_BuffMoodle.activateGiantOx(player, modifier.durationMinutes)
                    end
                elseif modifier.resetWeight then
                    player:Say("Your body weight has been normalized to " .. modifier.resetWeight .. " kg.")
                    -- Activate Oak Remedy moodle
                    if ZM_BuffMoodle then
                        ZM_BuffMoodle.activateOakRemedy(player)
                    end
                end
            end
        end

        -- Remove the item from inventory after successful use
        local playerInv = player:getInventory()
        local items = playerInv:getItems()
        for i = 0, items:size() - 1 do
            local invItem = items:get(i)
            if invItem:getID() == itemUID then
                playerInv:Remove(invItem)
                -- print("[ZM_BuffClient] Removed used item from inventory")
                break
            end
        end

    elseif command == 'UseItemResponseUsed' then
        -- Item was already used before
        local itemUID = args.itemUID
        local message = args.message or "This item has already been used before."

        -- print("[ZM_BuffClient] Item already used - UID: " .. tostring(itemUID))

        if player then
            player:Say(message)
        end

        -- Remove the item from inventory if it still exists
        if player then
            local playerInv = player:getInventory()
            if playerInv then
                local items = playerInv:getItems()
                for i = 0, items:size() - 1 do
                    local invItem = items:get(i)
                    if invItem and invItem:getID() == itemUID then
                        playerInv:Remove(invItem)
                        -- print("[ZM_BuffClient] Removed already-used item from inventory")
                        break
                    end
                end
            end
        end

    elseif command == 'UseItemResponseError' then
        -- Error occurred
        local itemUID = args.itemUID
        local message = args.message or "Failed to use item."

        -- print("[ZM_BuffClient] ERROR using item - UID: " .. tostring(itemUID))

        if player then
            player:Say(message)
        end
    end
end

-- Register server command handler
Events.OnServerCommand.Add(onServerCommand)

-- Add context menu for buff pills
local function addBuffPillContextMenu(playerNum, context, items)
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return end

    for _, v in ipairs(items) do
        local item = nil

        if instanceof(v, "InventoryItem") then
            item = v
        elseif v.items and #v.items > 0 then
            item = v.items[1]
        end

        if item and instanceof(item, "InventoryItem") then
            local itemType = item:getFullType()
            local isInPlayerInventory = playerObj:getInventory():contains(item)

            if isInPlayerInventory then
                -- Giant Ox Pill
                if itemType == "ZM_Mungkinkah.JessicaPill_GiantOx" then
                    context:addOption("Consume Pill", playerObj, ZM_BuffClient.UseItem, item)
                end

                -- Oak Remedy Pill
                if itemType == "ZM_Mungkinkah.JessicaPill_OakRemedy" then
                    context:addOption("Consume Pill", playerObj, ZM_BuffClient.UseItem, item)
                end
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addBuffPillContextMenu)

-- print("[ZM_BuffClient] Client module loaded successfully")

-- Periodic updater to disable Unlimited Carry when Giant Ox expires
-- Fast ticked expiry check (throttled) for precise disable timing
local ZM_BuffClient_NextCheckMs = 0
local function ZM_BuffClient_Update()
    local player = getSpecificPlayer(0)
    if not player then return end
    local now = getTimestampMs and getTimestampMs() or 0
    if now < (ZM_BuffClient_NextCheckMs or 0) then return end
    ZM_BuffClient_NextCheckMs = now + 500 -- check every 0.5s
    local md = player:getModData()
    if md and md.ZM_GiantOxEndMs then
        if now >= md.ZM_GiantOxEndMs then
            if player.isUnlimitedCarry and player:isUnlimitedCarry() then
                if player.setUnlimitedCarry then
                    player:setUnlimitedCarry(false)
                end
                player:Say("Giant Ox expired: Unlimited Carry disabled.")
            end
            if ZM_BuffMoodle and ZM_BuffMoodle.deactivateGiantOx then
                ZM_BuffMoodle.deactivateGiantOx(player)
            end
            md.ZM_GiantOxEndMs = nil
        end
    end
end

Events.EveryOneMinute.Add(ZM_BuffClient_Update)