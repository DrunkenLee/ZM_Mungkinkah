-- server/MinidoracatFixItemDuplication_server.lua

if isClient() then return end

local MinidoracatFixItemDuplication = {}

-- 記錄移除的物品
MinidoracatFixItemDuplication.logRemovedItems = function(player, args)
    if not player or not args.playerName or not args.removedItems then
        print("[MinidoracatFixItemDuplication] Invalid arguments received")
        return
    end

    print(string.format("[MinidoracatFixItemDuplication] Logging removed items for player: %s", args.playerName))

    for _, itemInfo in ipairs(args.removedItems) do
        print(string.format("[MinidoracatFixItemDuplication] Removed: %s (ID: %s, Type: %s) from container %d",
            itemInfo.name, tostring(itemInfo.id), itemInfo.type, itemInfo.containerIndex))
    end

    print(string.format("[MinidoracatFixItemDuplication] Total items removed: %d", #args.removedItems))
end

-- 註冊客戶端命令處理器
local function onClientCommand(module, command, player, args)
    if module == "MinidoracatFixItemDuplication" and command == "LogRemovedItems" then
        MinidoracatFixItemDuplication.logRemovedItems(player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)

print("[MinidoracatFixItemDuplication] Server-side script loaded")