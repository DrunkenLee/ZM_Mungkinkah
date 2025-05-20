-- Server-side function to remove a dupe item by its ID and container location
DupeA = DupeA or {}

function DupeA.ServerDeleteItemByID(itemID, x, y, z)
    local cell = getCell()
    if not cell then
        print("[ZM_DupeRemover] No cell found!")
        return false
    end

    for level = 0, cell:getMaxZ() do
        local square = cell:getGridSquare(x, y, level)
        if square then
            -- Check world objects
            local worldObjects = square:getWorldObjects()
            if worldObjects and worldObjects:size() > 0 then
                for i = 0, worldObjects:size() - 1 do
                    local obj = worldObjects:get(i)
                    if obj and obj.getItem then
                        local item = obj:getItem()
                        if item and item:getID() == itemID then
                            square:transmitRemoveItemFromSquare(obj)
                            obj:removeFromSquare()
                            print("[ZM_DupeRemover] Removed dupe item from world at " .. x .. "," .. y .. "," .. level)
                            return true
                        end
                    end
                end
            end

            -- Check containers in objects
            local objects = square:getObjects()
            if objects and objects:size() > 0 then
                for i = 0, objects:size() - 1 do
                    local containerObj = objects:get(i)
                    if containerObj and containerObj:getContainer() then
                        local container = containerObj:getContainer()
                        local items = container:getItems()
                        for j = 0, items:size() - 1 do
                            local item = items:get(j)
                            if item and item:getID() == itemID then
                                container:DoRemoveItem(item)
                                container:removeItemOnServer(item)
                                container:dirty()
                                print("[ZM_DupeRemover] Removed dupe item from container at " .. x .. "," .. y .. "," .. level)
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    print("[ZM_DupeRemover] Dupe item with ID " .. tostring(itemID) .. " not found at " .. x .. "," .. y)
    return false
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "DupeA" and command == "deleteDupeItem" then
        local itemID = args.itemID
        local x, y, z = args.x, args.y, args.z
        print("[DupeA] Server received deleteDupeItem for ID:", itemID, "at", x, y, z)
        local result = DupeA.ServerDeleteItemByID(itemID, x, y, z)
        if result then
            print("[DupeA] Dupe item deleted successfully.")
        else
            print("[DupeA] Failed to delete dupe item.")
        end
    end
end)