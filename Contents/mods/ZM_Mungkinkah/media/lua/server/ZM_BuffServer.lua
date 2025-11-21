-- Only run on server
if isClient() then return end

ZMBuffServer = ZMBuffServer or {}

-- Item configuration list
ZMBuffServer.itemList = {
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

-- Initialize ModData on server start
local function initializeModData()
    if not ModData.exists("ZMBuffUsage") then
        ModData.add("ZMBuffUsage", {})
        -- print("[ZMBuffServer] Initialized ZMBuffUsage ModData")
    end
end

-- Record that an item has been used
local function recordBuffUsage(itemUID)
    local buffUsage = ModData.get("ZMBuffUsage")
    if buffUsage then
        buffUsage[itemUID] = (buffUsage[itemUID] or 0) + 1
        ModData.transmit("ZMBuffUsage")
        -- print("[ZMBuffServer] Recorded usage for item UID: " .. tostring(itemUID))
        return true
    end
    return false
end

-- Check if an item has been used before
local function isBuffUsed(itemUID)
    local buffUsage = ModData.get("ZMBuffUsage")
    if buffUsage then
        return buffUsage[itemUID] ~= nil and buffUsage[itemUID] > 0
    end
    return false
end

-- Handle UseItem command from client
local function onUseItem(player, args)
    if not player or not args then
        -- print("[ZMBuffServer] ERROR: Invalid player or args")
        return
    end

    local itemUID = args.itemUID
    local itemName = args.itemName

    if not itemUID or not itemName then
        -- print("[ZMBuffServer] ERROR: No itemUID or itemName provided")
        return
    end

    print("[ZMBuffServer] UseItem called with item UID: " .. tostring(itemUID) .. ", name: " .. tostring(itemName))

    -- Check if item was already used
    if isBuffUsed(itemUID) then
        -- print("[ZMBuffServer] Item UID " .. tostring(itemUID) .. " has already been used.")
        sendServerCommand(player, 'ZM_Buff', 'UseItemResponseUsed', {
            itemUID = itemUID,
            itemName = itemName,
            message = "This item has already been used before."
        })
        return
    end

    -- Find the item config from server's list (don't trust client)
    local itemConfig = nil
    for _, config in ipairs(ZMBuffServer.itemList) do
        if string.find(itemName, config.name) then
            itemConfig = config
            break
        end
    end

    if not itemConfig or not itemConfig.modifier then
        -- print("[ZMBuffServer] ERROR: No matching item config found for: " .. tostring(itemName))
        sendServerCommand(player, 'ZM_Buff', 'UseItemResponseError', {
            itemUID = itemUID,
            itemName = itemName,
            message = "Invalid item configuration."
        })
        return
    end

    local modifier = itemConfig.modifier

    -- Record the usage
    if recordBuffUsage(itemUID) then
        -- print("[ZMBuffServer] Successfully recorded usage for item UID: " .. tostring(itemUID))

        -- Apply the buff effects using safe B41 APIs
        if modifier then
            -- Giant Ox - Cheat-based approach: show player how to enable Infinite Carry
            if modifier.carryCapacity and modifier.durationMinutes then
                sendServerCommand(player, 'ZM_Buff', 'ShowInfiniteCarryHint', {
                    minutes = modifier.durationMinutes
                })
                -- print("[ZMBuffServer] Sent Infinite Carry hint to client for duration " .. tostring(modifier.durationMinutes) .. " minutes")
            end

            -- Oak Remedy - Reset weight (use client application to avoid server-only desync)
            if modifier.resetWeight then
                local targetWeight = tonumber(modifier.resetWeight) or 75
                -- Ask client to apply and display result
                sendServerCommand(player, 'ZM_Buff', 'ApplyWeightReset', { weight = targetWeight })
                -- print("[ZMBuffServer] Requested client to reset weight to: " .. tostring(targetWeight))
            end
        end

        -- Send success response to client
        sendServerCommand(player, 'ZM_Buff', 'UseItemResponse', {
            itemUID = itemUID,
            itemName = itemName,
            modifier = modifier,
            message = "Item used successfully!"
        })
    else
        -- print("[ZMBuffServer] ERROR: Failed to record usage for item UID " .. tostring(itemUID))
        sendServerCommand(player, 'ZM_Buff', 'UseItemResponseError', {
            itemUID = itemUID,
            itemName = itemName,
            message = "Failed to use item. Please try again."
        })
    end
end

-- Register command handler
local function onClientCommand(module, command, player, args)
    if module ~= 'ZM_Buff' then return end

    if command == 'UseItem' then
        onUseItem(player, args)
    end
end

-- Event registration
Events.OnClientCommand.Add(onClientCommand)
Events.OnServerStarted.Add(initializeModData)

-- print("[ZMBuffServer] Server module loaded successfully")