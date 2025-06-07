JessicaSupplyRun = {}

function JessicaSupplyRun.checkAndSpawnAmbulance(player)
    -- Safety check
    if not player then return nil end

    -- Define area to check
    local areaToCheck = {
        x1 = 12926,
        y1 = 11117,
        x2 = 12926 + 5,
        y2 = 11117 + 6,
    }

    -- Get cell
    local cell = getCell()
    if not cell then return nil end

    -- Check if any vehicles exist in the area
    local allVehicles = cell:getVehicles()
    local vehicleFound = false
    local ambulanceFound = false

    if allVehicles then
        for i = 0, allVehicles:size()-1 do
            local vehicle = allVehicles:get(i)
            if vehicle then
                -- Check if vehicle is in the defined area
                local vx = vehicle:getX()
                local vy = vehicle:getY()

                if vx >= areaToCheck.x1 and vx <= areaToCheck.x2 and
                   vy >= areaToCheck.y1 and vy <= areaToCheck.y2 then
                    vehicleFound = true
                    -- If it's already an ambulance, return it
                    if vehicle:getScriptName() == "Base.VanAmbulance" then
                        ambulanceFound = true
                        player:Say("Ambulance is ready.")
                        return vehicle
                    end
                end
            end
        end
    end

    if vehicleFound then
        print("Found a vehicle in the area, but it's not an ambulance.")
        player:Say("There is a vehicle here, need to clear it out.")
        return nil
    end

    -- If no vehicles found in the area, request server to spawn an ambulance
    if not vehicleFound and not ambulanceFound then
        -- Send request to server
        sendClientCommand("JessicaSupplyRun", "SpawnAmbulance", {
            x = areaToCheck.x1 + (areaToCheck.x2 - areaToCheck.x1) / 2,
            y = areaToCheck.y1 + (areaToCheck.y2 - areaToCheck.y1) / 2,
            playerOnlineID = player:getOnlineID()
        })
        print("Requested server to spawn ambulance")
    end

    return nil
end

function JessicaSupplyRun.fillSuppliesToAmbulance(player, part)
    -- Safety check
    if not player then return false end

    local ambulance = player:getVehicle()

    if not ambulance or ambulance:getScriptName() ~= "Base.VanAmbulance" then
        print("Player is not in an ambulance")
        return false
    end

    -- Define the supplies to add (using REAL item IDs)
    local supplies = {
        { itemID = "Base.Bandaid", name = "Jessicas_Adhesive Bandages", count = 20, part = 1 },
        { itemID = "Base.AlcoholBandage", name = "Jessicas_Sterilized Bandage", count = 20, part = 1 },
        { itemID = "Base.Disinfectant", name = "Jessicas_Bottle of Disinfectant", count = 20, part = 2 },
        { itemID = "Base.SutureNeedle", name = "Jessicas_Suture Needle", count = 10, part = 2 },
        { itemID = "Base.SutureNeedleHolder", name = "Jessicas_Suture Needle Holder", count = 10, part = 3 },
        { itemID = "Base.Pills", name = "Jessicas_Painkillers", count = 50, part = 3 }
    }

    -- Get the trunk part of the ambulance to verify it exists
    local trunkPart = ambulance:getPartById("TruckBed")
    if not trunkPart or not trunkPart:getItemContainer() then
        print("Cannot access ambulance trunk")
        return false
    end

    -- Start the timed action - 30 seconds
    local action = ISFillAmbulanceSuppliesAction:new(player, ambulance, supplies, part, 30 * 60)
    ISTimedActionQueue.add(action)

    return true
end

function JessicaSupplyRun.endPointCheck(player)
    -- Safety check
    if not player then return false end

    -- Define the end point area
    local endPointArea = {
        x1 = 12925,
        y1 = 11143,
        x2 = 12925 + 5,
        y2 = 11143 + 6,
    }

    -- Get cell
    local cell = getCell()
    if not cell then return false end

    -- Check if player is within the end point area
    local playerX = player:getX()
    local playerY = player:getY()
    local playerInArea = (playerX >= endPointArea.x1 and playerX <= endPointArea.x2 and
                         playerY >= endPointArea.y1 and playerY <= endPointArea.y2)

    if not playerInArea then
        print("Player is not at the end point.")
        return false
    end

    -- Check if ambulance is in the area
    local allVehicles = cell:getVehicles()
    local ambulanceInArea = false
    local ambulance = nil

    if allVehicles then
        for i = 0, allVehicles:size()-1 do
            local vehicle = allVehicles:get(i)
            if vehicle then
                local vx = vehicle:getX()
                local vy = vehicle:getY()

                if vx >= endPointArea.x1 and vx <= endPointArea.x2 and
                   vy >= endPointArea.y1 and vy <= endPointArea.y2 then
                    -- Check if it's an ambulance
                    if vehicle:getScriptName() == "Base.VanAmbulance" then
                        ambulanceInArea = true
                        ambulance = vehicle
                        break
                    end
                end
            end
        end
    end

    if not ambulanceInArea then
        player:Say("The ambulance is not here.")
        print("Ambulance is not at the end point.")
        return false
    end

    -- Check if all required medical supplies are in the ambulance
    local requiredSupplies = {
        ["Jessicas_Adhesive Bandages"] = 20,
        ["Jessicas_Sterilized Bandage"] = 20,
        ["Jessicas_Bottle of Disinfectant"] = 20,
        ["Jessicas_Suture Needle"] = 10,
        ["Jessicas_Suture Needle Holder"] = 10,
        ["Jessicas_Painkillers"] = 50
    }

    local missingSupplies = {}
    local allSuppliesPresent = true

    -- Check trunk for supplies
    local trunkPart = ambulance:getPartById("TruckBed")
    if trunkPart and trunkPart:getItemContainer() then
        local trunkItems = trunkPart:getItemContainer():getItems()
        local supplyCounts = {}

        -- Count all supplies in trunk
        for i = 0, trunkItems:size()-1 do
            local item = trunkItems:get(i)
            local itemName = item:getName()

            -- Count items with Jessica's prefix
            if requiredSupplies[itemName] then
                supplyCounts[itemName] = (supplyCounts[itemName] or 0) + 1
            end
        end

        -- Check if we have enough of each required supply
        for itemName, requiredCount in pairs(requiredSupplies) do
            local foundCount = supplyCounts[itemName] or 0
            if foundCount < requiredCount then
                missingSupplies[itemName] = requiredCount - foundCount
                allSuppliesPresent = false
            end
        end
    else
        print("Cannot access ambulance trunk")
        return false
    end

    if not allSuppliesPresent then
        print("Missing some required supplies:")
        player:Say("Some medical supplies are missing. Please check the ambulance trunk.")
        for itemName, missingCount in pairs(missingSupplies) do
            print("  " .. itemName .. ": missing " .. missingCount)
        end
        return false
    end

    -- All conditions met: player, ambulance, and all supplies are in the delivery area
    player:Say("All supplies delivered successfully! Jessica will be so pleased.")
    print("Delivery complete! Player, ambulance, and all supplies are at the delivery point.")

    -- Store ambulance info before removing
    local vehicleID = ambulance:getId()
    local vehicleX = ambulance:getX()
    local vehicleY = ambulance:getY()
    local vehicleZ = ambulance:getZ()

    -- First, hide the ambulance on client side for immediate visual feedback
    -- This doesn't remove it from the game, just makes it invisible
    ambulance:setAlpha(0.0)

    -- Request server to officially remove the vehicle
    sendClientCommand("JessicaSupplyRun", "RemoveAmbulance", {
        vehicleID = vehicleID,
        x = vehicleX,
        y = vehicleY,
        z = vehicleZ
    })

    -- Set quest completion flag
    if PlayerFlagHandler and PlayerFlagHandler.setFlag then
        PlayerFlagHandler.setFlag("jessica_quest_complete", true)
    end

    return true
end


local function onServerCommand(module, command, args)
    if module == "JessicaSupplyRun" and command == "AmbulanceSpawned" then
        local player = getSpecificPlayer(0)
        if player then
            player:Say("Ambulance has arrived!")

            -- Add key to inventory if provided
            if args.keyID then
                local keyItem = player:getInventory():AddItem("Base.CarKey")
                if keyItem then
                    keyItem:getModData().VehicleID = args.keyID
                    keyItem:setName("Ambulance Key")
                end
            end
        end
    end

    if module == "JessicaSupplyRun" and command == "AmbulanceRemoved" then
        local player = getSpecificPlayer(0)
        if player and args.success then
            player:Say(args.message)

            -- Remove ambulance from client side if it still exists
            if args.vehicleID then
                local cell = getCell()
                if cell then
                    local allVehicles = cell:getVehicles()
                    if allVehicles then
                        for i = 0, allVehicles:size()-1 do
                            local vehicle = allVehicles:get(i)
                            if vehicle and vehicle:getId() == args.vehicleID then
                                -- Try multiple methods to ensure removal
                                print("Removing ambulance from client side")
                                vehicle:setAlpha(0.0) -- Make invisible first
                                if not vehicle._alreadyRemoved then
                                  vehicle:removeFromWorld()
                                  vehicle:removeFromSquare()
                                  vehicle._alreadyRemoved = true
                                end

                                -- As a last resort
                                if isClient() then
                                    vehicle:permanentlyRemove() -- More forceful removal
                                end
                                break
                            end
                        end
                    end
                end
            end

            -- Add visual effects at the ambulance's last position
            if args.x and args.y and args.z then
                local square = getCell():getGridSquare(args.x, args.y, args.z)
                if square then

                end
            end
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)

local function EveryOneMinute()
    local player = getSpecificPlayer(0)
    if player and not player:isDead() then
        -- Check if player has the jessica_quest_start flag
        if PlayerFlagHandler.getFlag("jessica_quest_start") then

            if ambulance then
                -- print("[JessicaSupplyRun] Player found the ambulance!")
            end
        else
            -- Other logic
        end
    end
end

Events.EveryOneMinute.Add(EveryOneMinute)

print("Jessica's Supply Run initialized")

-- Timed action for filling ambulance supplies
ISFillAmbulanceSuppliesAction = ISBaseTimedAction:derive("ISFillAmbulanceSuppliesAction")

function ISFillAmbulanceSuppliesAction:isValid()
    -- Make sure player is still in the ambulance
    return self.ambulance ~= nil and
           self.character:getVehicle() == self.ambulance and
           self.ambulance:getScriptName() == "Base.VanAmbulance"
end

function ISFillAmbulanceSuppliesAction:update()
    -- Update animation and sound effects
    self.character:setMetabolicTarget(Metabolics.LightWork)

    -- Play sound occasionally during the action
    if self.soundTime <= 0 then
        self.soundTime = 150 + ZombRand(100)
        self.character:playSound("LoadSupplies")
    else
        self.soundTime = self.soundTime - 1
    end
end

function ISFillAmbulanceSuppliesAction:start()
    -- Notify player action started
    self.character:Say("I'm gathering medical supplies...")

    -- Set up animation
    self:setActionAnim("MoveItemsInArea")
    self:setOverrideHandModels(nil, nil)

    -- Initial sound time
    self.soundTime = 50
end

function ISFillAmbulanceSuppliesAction:stop()
    -- Cleanup when action is interrupted
    ISBaseTimedAction.stop(self)
    self.character:Say("I stopped gathering supplies.")
end

function ISFillAmbulanceSuppliesAction:perform()
    -- Action completed
    ISBaseTimedAction.perform(self)

    -- Access player's inventory
    local inventory = self.character:getInventory()
    if not inventory then
        self.character:Say("Can't access my inventory.")
        return
    end

    -- Fill the player's inventory with supplies
    local itemsAdded = 0
    for _, supply in ipairs(self.supplies) do
        -- Only process supplies that match the requested part (or all if no part specified)
        if not self.part or supply.part == self.part then
            -- Add the specified number of this item
            for i = 1, supply.count do
                local item = InventoryItemFactory.CreateItem(supply.itemID)
                if item then
                    -- Rename the item
                    item:setName(supply.name)
                    inventory:AddItem(item)
                    itemsAdded = itemsAdded + 1
                else
                    print("Failed to create item: " .. supply.itemID)
                end
            end
        end
    end

    -- Notify player of completion
    if self.part then
        self.character:Say("Gathered supplies for part " .. self.part .. ".")
        print("Added " .. itemsAdded .. " items for part " .. self.part .. " to player inventory.")
    else
        self.character:Say("Gathered all the medical supplies.")
        print("Added " .. itemsAdded .. " items to player inventory.")
    end

    -- Mark ambulance as being associated with Jessica's quest
    local modData = self.ambulance:getModData()
    modData.isJessicaQuestAmbulance = true
    modData.lastSuppliesPart = self.part or "all"
end

function ISFillAmbulanceSuppliesAction:new(character, ambulance, supplies, part, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.ambulance = ambulance
    o.supplies = supplies
    o.part = part
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = time
    o.soundTime = 0
    return o
end