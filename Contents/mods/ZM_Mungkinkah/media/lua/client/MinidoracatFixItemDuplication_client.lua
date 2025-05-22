-- client/MinidoracatFixItemDuplication_client.lua

local MinidoracatFixItemDuplication = {}

MinidoracatFixItemDuplication.containerCache = {}
MinidoracatFixItemDuplication.containersUpdated = false

-- 重置容器快取
MinidoracatFixItemDuplication.resetContainerCache = function()
    MinidoracatFixItemDuplication.containerCache = {}
    MinidoracatFixItemDuplication.containersUpdated = false
end

-- 檢查容器是否可以被添加
MinidoracatFixItemDuplication.canBeAdded = function(container, playerObj)
    if not container or not playerObj then return false end

    -- 檢查是否為殭屍物品欄
    if container:getType() == "inventoryfemale" or container:getType() == "inventorymale" then
        -- print("[MinidoracatFixItemDuplication] Ignoring zombie inventory")
        return true
    end

    -- 檢查是否為鎖定的容器
    local object = container:getParent()
    if object and instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
        -- print(string.format("[MinidoracatFixItemDuplication] Ignoring locked container %s", container:getType()))
        return false
    end

    return true
end


MinidoracatFixItemDuplication.removeDuplicateItem = function(item)
    if not item then return false end

    local container = item:getContainer()
    if not container then return false end


    if isClient() then
        DupeA.CheckAndDeleteDupesAroundPlayer(getSpecificPlayer(0))
    end

    if item:getWorldItem() then
        item:getWorldItem():removeFromWorld()
        item:getWorldItem():removeFromSquare()
        item:getWorldItem():setSquare(nil)
    end

    -- 從容器中移除物品
    container:Remove(item)

    return true
end

-- 檢查重複物品並移除
MinidoracatFixItemDuplication.checkAndRemoveDuplicateItems = function(playerObj)
    if not playerObj then
        -- print("[MinidoracatFixItemDuplication] Player is nil")
        return
    end

    local playerItemIds = {}
    local containerItemIds = {}
    local removedItems = {}

    -- 檢查玩家物品
    local playerInventory = playerObj:getInventory()
    if playerInventory then
        local playerItemList = playerInventory:getItems()
        for i = 0, playerItemList:size() - 1 do
            local item = playerItemList:get(i)
            if item then
                playerItemIds[item:getID()] = true
            end
        end
    end

    -- 檢查容器物品
    for index, container in pairs(MinidoracatFixItemDuplication.containerCache) do
        local itemList = container:getItems()
        if itemList then
            local itemsToRemove = {}
            for i = 0, itemList:size() - 1 do
                local item = itemList:get(i)
                if item then
                    local itemId = item:getID()
                    if playerItemIds[itemId] or containerItemIds[itemId] then
                        table.insert(itemsToRemove, item)
                    else
                        containerItemIds[itemId] = true
                    end
                end
            end

            -- 移除重複物品
            for _, item in ipairs(itemsToRemove) do
                if MinidoracatFixItemDuplication.removeDuplicateItem(item) then
                    print(string.format("[MinidoracatFixItemDuplication] Removed duplicate item: %s (ID: %s, Type: %s) from container %d",
                        item:getName(), tostring(item:getID()), item:getType(), index))
                    table.insert(removedItems, {
                        name = item:getName(),
                        type = item:getType(),
                        id = item:getID(),
                        containerIndex = index
                    })
                end
            end
        end
    end

    -- 發送移除的物品信息到服務器進行記錄
    if #removedItems > 0 then
        sendClientCommand(playerObj, "MinidoracatFixItemDuplication", "LogRemovedItems", {
            playerName = playerObj:getUsername(),
            removedItems = removedItems
        })
        print(string.format("[MinidoracatFixItemDuplication] Removed %d duplicate items", #removedItems))
    -- else
    --     print("[MinidoracatFixItemDuplication] No duplicate items found")
    end
end

-- 刷新物品欄視窗容器時的事件處理
MinidoracatFixItemDuplication.OnRefreshInventoryWindowContainers = function(inventoryPage, state)
    local playerObj = getSpecificPlayer(inventoryPage.player)
    if not playerObj or inventoryPage.onCharacter or playerObj:getVehicle() then
        -- 忽略角色容器和車輛
        return
    end

    if state == "begin" then
        MinidoracatFixItemDuplication.resetContainerCache()
    elseif state == "buttonsAdded" then
        -- 只在按鈕實際添加時更新
        local containersChanged = false
        if inventoryPage.backpacks then
            for i = 1, (#inventoryPage.backpacks - 1) do
                local invToAdd = inventoryPage.backpacks[i].inventory
                if invToAdd and MinidoracatFixItemDuplication.canBeAdded(invToAdd, playerObj) then
                    if not MinidoracatFixItemDuplication.containerCache[i] then
                        MinidoracatFixItemDuplication.containerCache[i] = invToAdd
                        containersChanged = true
                    end
                end
            end
        end

        if containersChanged then
            MinidoracatFixItemDuplication.checkAndRemoveDuplicateItems(playerObj)
            MinidoracatFixItemDuplication.containersUpdated = true
        end
    end
end

-- 玩家登入事件處理
MinidoracatFixItemDuplication.OnPlayerConnect = function(playerObj)
    MinidoracatFixItemDuplication.checkAndRemoveDuplicateItems(playerObj)
end

-- 安全地註冊事件
local function safeAddEvent(event, func)
    if event then
        event.Add(func)
    end
end

-- 安全地移除事件
local function safeRemoveEvent(event, func)
    if event then
        event.Remove(func)
    end
end

-- 移除任何現有的事件處理器以防止重複
safeRemoveEvent(Events.OnRefreshInventoryWindowContainers, MinidoracatFixItemDuplication.OnRefreshInventoryWindowContainers)
safeRemoveEvent(Events.OnPlayerConnect, MinidoracatFixItemDuplication.OnPlayerConnect)

-- 註冊事件處理器
safeAddEvent(Events.OnRefreshInventoryWindowContainers, MinidoracatFixItemDuplication.OnRefreshInventoryWindowContainers)
safeAddEvent(Events.OnPlayerConnect, MinidoracatFixItemDuplication.OnPlayerConnect)


Events.EveryTenMinutes.Add(function()
    DupeA.CheckAndDeleteDupesAroundPlayer(getSpecificPlayer(0))
end)

if EventsPlus then
  EventsPlus:Add("OnItemMoved", function(character, item, source, destination)
    local itemCat = item:getCategory()
    if itemCat == "Weapon" then
      DupeA.CheckAndDeleteDupesAroundPlayer(getSpecificPlayer(0))
    end
  end, "My callback context")
end


print("[MinidoracatFixItemDuplication] Client-side script loaded")