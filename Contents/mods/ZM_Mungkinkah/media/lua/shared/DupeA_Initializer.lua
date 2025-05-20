DupeA = DupeA or {}
DupeA.coords = {}
DupeA.dupes = {items={}, count=0, coords="", tittle=""}

function DupeA.ResetDupes()
    DupeA.dupes = {items={}, count=0, coords="", tittle=""}
end

function DupeA.SearchItemsInContainer(container, x, y, z)
    local list = {}
    local items = container:getItems()
    if not items then return list end
    for i = 0, items:size()-1 do
        local item = items:get(i)
        if item then
            local itemList = {}
            itemList.item = item
            itemList.x = x
            itemList.y = y
            itemList.z = z
            table.insert(list, itemList)
            if item:getCategory() == "Container" then
                local ls = DupeA.SearchItemsInContainer(item:getItemContainer(), x, y, z)
                for _, v in ipairs(ls) do
                    table.insert(list, v)
                end
            end
        end
    end
    return list
end

function DupeA.IsItemMoved(container)
    local moved = container:getType() == "none"
    --DupeA.PrintDebug("ISMOVED: " .. container:getType())
    if moved == true then return moved end
    local itemContainer = container:getContainingItem()
    if not itemContainer then return moved end
    local innerContainer = itemContainer:getContainer()
    if innerContainer then
        moved = DupeA.IsItemMoved(innerContainer)
    end

    return moved
end

function DupeA.AnalyzeItems(coords, tittle, player)
    local dupes = {items={}, count=0, coords="", tittle=tittle}
    local list = {}
    local vehicles = {}
    --print("Player in: " .. player:getX() .. " " .. player:getY())

    local x1 = math.floor(coords.startX)
    local x2 = math.floor(coords.endX)
    local y1 = math.floor(coords.startY)
    local y2 = math.floor(coords.endY)

    if x1 > x2 then
        x1 = math.floor(coords.endX)
        x2 = math.floor(coords.startX)
    end
    if y1 > y2 then
        y1 = math.floor(coords.endY)
        y2 = math.floor(coords.startY)
    end

    dupes.coords = x1.." x "..y1.."   -   "..x2.." x "..y2

    local cell = player:getCell()
    for x = x1, x2, 1 do
        for y = y1, y2, 1 do
            for z = 0, cell:getMaxZ(), 1 do
                local square = cell:getGridSquare(x, y, z)
                if square then

                    -- Add items from objects
                    local items = square:getObjects()
                    if items and items:size()>0 then
                        for i = 0, items:size()-1 do
                            local container = items:get(i):getContainer()
                            if container then
                                --print("Container on Square")
                                local ls = DupeA.SearchItemsInContainer(container, x, y, z)
                                for _, v in ipairs(ls) do
                                    table.insert(list, v)
                                end
                            end
                        end
                    end

                    --Add items from moving objects
                    items = square:getStaticMovingObjects()
                    if items and items:size()>0 then
                        for i = 0, items:size()-1 do
                            local container = items:get(i):getContainer()
                            if container then
                                --print("Container moveble on Square")
                                local ls = DupeA.SearchItemsInContainer(container, x, y, z)
                                for _, v in ipairs(ls) do
                                    table.insert(list, v)
                                end
                            end
                        end
                    end

                    -- Add items from vehicles
                    local vehicle = square:getVehicleContainer()
                    if vehicle then
                        local vehicleId = vehicles[vehicle:getId()]
                        if not vehicleId then
                            vehicles[vehicle:getId()] = true
                            local numParts = vehicle:getPartCount()
                            for n = 0, numParts - 1, 1 do
                                local part = vehicle:getPartByIndex(n)
                                if part:isContainer() then
                                    local container = part:getItemContainer()
                                    if container then
                                        --print("Container on Vehicle")
                                        --print(container:getType())
                                        local ls = DupeA.SearchItemsInContainer(container, x, y, z)
                                        for _, v in ipairs(ls) do
                                            table.insert(list, v)
                                        end
                                    end
                                end
                            end
                        end
                    end


                    if items and items:size()>0 then
                        for i = 0, items:size()-1 do
                            local container = items:get(i):getContainer()
                            if container then
                                --print("Container on Square")
                                local ls = DupeA.SearchItemsInContainer(container, x, y, z)
                                for _, v in ipairs(ls) do
                                    table.insert(list, v)
                                end
                            end
                        end
                    end

                    -- Add items from world
                    items = square:getWorldObjects()
                    if items and items:size()>0 then
                        for i = 0, items:size()-1 do
                            local item = items:get(i)
                            if item then
                                --print("Item Square")
                                local itemList = {}
                                itemList.item = item:getItem()
                                itemList.x = x
                                itemList.y = y
                                itemList.z = z
                                table.insert(list, itemList)
                                if item:getItem():getCategory() == "Container" then
                                    --print("Item is Container")
                                   -- print(item:getItem():getType())
                                    local ls = DupeA.SearchItemsInContainer(item:getItem():getItemContainer(), x, y, z)
                                    for _, v in ipairs(ls) do
                                        table.insert(list, v)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    dupes.count = #list
    local entries = {}
    for _,v in ipairs(list) do
        local item = v.item
        local itemId = item:getID()
        local name = item:getType()

        --DupeA.PrintDebug("ITEM: " .. name .. " " .. itemId)

        local entry = entries[itemId]
        if entry then
            local dupe = {id=itemId, item=item, x=v.x, y=v.y, z=v.z, xo=entry.x, yo=entry.y, zo=entry.z}
            table.insert(dupes.items, dupe)
        end
        entries[itemId] = v

        -- Just a test to force create duped items for test purpose.
        -- local inventory = player:getInventory()
        -- local t = inventory:addItem(item)
    end

    return dupes

end

function DupeA.DeleteItem(item, index)
    --DupeA.PrintDebug("Selected Item: " .. item:getType() .. " index: " .. index)
    local container = item:getContainer()
    if not container then return end

    if DupeA.IsItemMoved(container) then return end

    if container:getType() == "floor" then
        local temp = item:getWorldItem()
        local square = temp:getSquare()
        if square then
            square:transmitRemoveItemFromSquare(temp)
            temp:removeFromSquare()
        end
    else
        --DupeA.PrintDebug("ContainerName: " .. container:getType())
        container:DoRemoveItem(item)
        container:removeItemOnServer(item)
    end
    local removedItem = table.remove(DupeA.dupes.items, index)
    DupeA.PrintDebug("Deleted Item: " .. item:getType())
end

function DupeA.CheckAndDeleteDupesAroundPlayer(player)
    -- Define a 20-tile radius area around the player
    local px, py = player:getX(), player:getY()
    local coords = {
        startX = px - 20,
        startY = py - 20,
        endX = px + 20,
        endY = py + 20
    }
    local tittle = "AutoDupeCleanup"
    local dupes = DupeA.AnalyzeItems(coords, tittle, player)
    print("[DupeA] Checking for dupes in 20-tile area... Found: " .. tostring(dupes.count))
    if #dupes.items > 0 then
        for i = #dupes.items, 1, -1 do
            local dupe = dupes.items[i]
            -- Request server to delete
            DupeA.RequestServerDeleteDupe(dupe.id, dupe.x, dupe.y, dupe.z)
            DupeA.DeleteItem(dupe.item, i)
            -- Also delete on client if running as client
            print("[DupeA] Deleted dupe item on client: " .. tostring(dupe.item:getType()) .. " at " .. dupe.x .. "," .. dupe.y .. "," .. dupe.z)
        end
        print("[DupeA] All dupe delete requests sent to server.")
    else
        print("[DupeA] No dupes found in area.")
    end
end

function DupeA.RequestServerDeleteDupe(itemID, x, y, z)
    sendClientCommand("DupeA", "deleteDupeItem", { itemID = itemID, x = x, y = y, z = z })
end
