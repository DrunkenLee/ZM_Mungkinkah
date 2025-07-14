ZM_Autoshop = ZM_Autoshop or {}

local function getVehicleScriptNamesFromSandbox()
    local vehicleNames = {}

    -- Get all vehicle script names from sandbox options
    if SandboxVars and SandboxVars.ZM_Autoshop then
        if SandboxVars.ZM_Autoshop.vehicleScriptNames1 and SandboxVars.ZM_Autoshop.vehicleScriptNames1 ~= "" then
            table.insert(vehicleNames, SandboxVars.ZM_Autoshop.vehicleScriptNames1)
        end
        if SandboxVars.ZM_Autoshop.vehicleScriptNames2 and SandboxVars.ZM_Autoshop.vehicleScriptNames2 ~= "" then
            table.insert(vehicleNames, SandboxVars.ZM_Autoshop.vehicleScriptNames2)
        end
        -- Add more if you have vehicleScriptNames3, vehicleScriptNames4, etc.
    end

    return vehicleNames
end


function ZM_Autoshop.checkVehicleInEndpoint(player, vehicleScriptNames, endPointArea)
    -- Safety check
    if not player then
        print("Missing player parameter")
        return false, nil, nil
    end

    -- Use sandbox options if no vehicle names provided
    if not vehicleScriptNames then
        vehicleScriptNames = getVehicleScriptNamesFromSandbox()
    end

    -- Convert single script name to table for consistent processing
    if type(vehicleScriptNames) == "string" then
        vehicleScriptNames = {vehicleScriptNames}
    end

    -- Check if we have any vehicle names to look for
    if not vehicleScriptNames or #vehicleScriptNames == 0 then
        print("No vehicle script names found in sandbox options")
        return false, nil, nil
    end

    local defaultArea = {
        x1 = 12925,
        y1 = 11143,
        x2 = 12930,
        y2 = 11149,
    }

    endPointArea = endPointArea or defaultArea

    local cell = getCell()
    if not cell then
        print("Cannot access cell")
        return false, nil, nil
    end

    local playerX = player:getX()
    local playerY = player:getY()
    local playerInArea = (playerX >= endPointArea.x1 and playerX <= endPointArea.x2 and
                         playerY >= endPointArea.y1 and playerY <= endPointArea.y2)

    if not playerInArea then
        print("Player is not at the endpoint area.")
        print("Looking for vehicles: " .. table.concat(vehicleScriptNames, ", "))
        return false, nil, nil
    end

    local allVehicles = cell:getVehicles()
    local vehicleFound = false
    local foundVehicle = nil
    local foundScriptName = nil

    if allVehicles then
        for i = 0, allVehicles:size()-1 do
            local vehicle = allVehicles:get(i)
            if vehicle then
                local vx = vehicle:getX()
                local vy = vehicle:getY()

                if vx >= endPointArea.x1 and vx <= endPointArea.x2 and
                   vy >= endPointArea.y1 and vy <= endPointArea.y2 then

                    local scriptName = vehicle:getScriptName()
                    for _, targetScriptName in ipairs(vehicleScriptNames) do
                        print("Checking vehicle: " .. scriptName .. " against target: " .. targetScriptName)
                        if scriptName == targetScriptName then
                            vehicleFound = true
                            foundVehicle = vehicle
                            foundScriptName = scriptName
                            player:Say("Found vehicle: " .. scriptName)
                            print("Vehicle found from sandbox options: " .. scriptName)

                            -- Add vehicle condition report when vehicle is found
                            print("Generating vehicle condition report...")
                            local condition = ZM_Autoshop.printVehicleCondition(vehicle, true)
                            player:Say("Vehicle condition: " .. condition .. "%")

                            -- Store vehicle info before removal
                            local vehicleID = vehicle:getId()
                            local vehicleX = vehicle:getX()
                            local vehicleY = vehicle:getY()
                            local vehicleZ = vehicle:getZ()

                            vehicle:permanentlyRemove()

                            player:Say("The vehicle has been processed and removed.")
                            print("Vehicle " .. scriptName .. " has been removed from the endpoint.")
                            break
                        end
                    end
                    if vehicleFound then break end
                end
            end
        end
    end

    if not vehicleFound then
        print("None of the sandbox vehicles found at endpoint: " .. table.concat(vehicleScriptNames, ", "))
        return false, nil, nil
    end

    return true, foundVehicle, foundScriptName
end

function ZM_Autoshop.checkAnyVehicleInEndpoint(player, endPointArea)


    if not player then return false, {} end
    local defaultArea = {
        x1 = 12925,
        y1 = 11143,
        x2 = 12930,
        y2 = 11149,
    }

    endPointArea = endPointArea or defaultArea

    -- Get cell
    local cell = getCell()
    if not cell then return false, {} end

    local allVehicles = cell:getVehicles()
    local vehiclesFound = {}

    if allVehicles then
        for i = 0, allVehicles:size()-1 do
            local vehicle = allVehicles:get(i)
            if vehicle then
                local vx = vehicle:getX()
                local vy = vehicle:getY()

                if vx >= endPointArea.x1 and vx <= endPointArea.x2 and
                   vy >= endPointArea.y1 and vy <= endPointArea.y2 then
                    table.insert(vehiclesFound, vehicle)
                    print("[CHECK ANY VEHICLE] Found vehicle in area: " .. vehicle:getScriptName())
                end
            end
        end
    end

    return #vehiclesFound > 0, vehiclesFound
end

function ZM_Autoshop.printVehicleCondition(vehicle, detailed)
    if not vehicle then
        print("Error: No vehicle provided to assess")
        return 0
    end

    -- Get all vehicle parts
    local parts = vehicle:getPartCount()
    local totalCondition = 0
    local partCount = 0
    local allPartsInfo = {}

    -- Important systems to check separately (for display purposes)
    local engine = vehicle:getPartById("Engine")
    local battery = vehicle:getPartById("Battery")
    local gasAmount = vehicle:getPartById("GasTank") and vehicle:getPartById("GasTank"):getContainerContentAmount() or 0
    local gasCapacity = vehicle:getPartById("GasTank") and vehicle:getPartById("GasTank"):getContainerCapacity() or 100

    -- Collect ALL parts for condition calculation
    for i=1, parts do
        local part = vehicle:getPartByIndex(i-1)
        if part then
            local condition = part:getCondition()
            local partId = part:getId()

            -- Add to total condition calculation
            totalCondition = totalCondition + condition
            partCount = partCount + 1

            -- Store part info for detailed display
            table.insert(allPartsInfo, {
                id = partId,
                condition = condition,
                isTire = partId:contains("Tire"),
                isEngine = partId == "Engine",
                isBattery = partId == "Battery",
                isGasTank = partId == "GasTank"
            })
        end
    end

    -- Get additional condition factors
    local rust = vehicle:getRust() * 100
    local thumpCondition = (vehicle:getThumpCondition() or 0) * 100

    -- Convert rust to a condition value (100% - rust percentage)
    local rustCondition = math.max(0, 100 - rust)

    -- Header for the report
    print("====== VEHICLE CONDITION REPORT ======")
    print("Vehicle: " .. vehicle:getScriptName())
    print("ID: " .. vehicle:getId())
    print("Total Parts Assessed: " .. partCount)

    -- Print key systems status
    print("\n--- KEY SYSTEMS ---")
    if engine then
        local engineCondition = engine:getCondition()
        print(string.format("Engine: %d%% (%s)",
            engineCondition,
            engineCondition > 70 and "Good" or (engineCondition > 30 and "Fair" or "Poor")))
    else
        print("Engine: Not found")
    end

    if battery then
        local batteryCharge = battery:getInventoryItem() and battery:getInventoryItem():getUsedDelta() * 100 or 0
        print(string.format("Battery: %d%% charged", math.floor(batteryCharge)))
    else
        print("Battery: Not installed")
    end

    local gasPercentage = (gasCapacity > 0) and (gasAmount / gasCapacity * 100) or 0
    print(string.format("Fuel: %d%% (%0.1f/%0.1f)",
        math.floor(gasPercentage),
        gasAmount,
        gasCapacity))

    -- Print tire conditions specifically
    print("\n--- TIRES ---")
    local tireCount = 0
    for _, partInfo in ipairs(allPartsInfo) do
        if partInfo.isTire then
            tireCount = tireCount + 1
            print(string.format("%s: %d%% (%s)",
                partInfo.id,
                partInfo.condition,
                partInfo.condition > 70 and "Good" or (partInfo.condition > 30 and "Fair" or "Poor")))
        end
    end
    if tireCount == 0 then
        print("No tires found")
    end

    -- Calculate base condition (average of ALL parts)
    local baseCondition = partCount > 0 and (totalCondition / partCount) or 0

    -- Show detailed parts report if requested
    if detailed then
        print("\n--- ALL PARTS DETAILED REPORT ---")
        for _, partInfo in ipairs(allPartsInfo) do
            local status = partInfo.condition > 70 and "Good" or (partInfo.condition > 30 and "Fair" or "Poor")
            print(string.format("%s: %d%% (%s)", partInfo.id, partInfo.condition, status))
        end
    end

    -- Calculate final overall condition including rust and thump factors
    -- Weight: Parts (70%), Rust Condition (20%), Thump Condition (10%)
    local overallCondition = math.floor(
        (baseCondition * 0.7) +
        (rustCondition * 0.2) +
        (thumpCondition * 0.1)
    )

    -- Print summary with breakdown
    print("\n--- SUMMARY ---")
    print(string.format("Base Parts Condition: %d%% (from %d parts)", math.floor(baseCondition), partCount))
    print(string.format("Rust Factor: %d%% (Rust Level: %d%%)", math.floor(rustCondition), math.floor(rust)))
    print(string.format("Thump Factor: %d%%", math.floor(thumpCondition)))
    print("---")
    print(string.format("Final Overall Condition: %d%% (%s)",
        overallCondition,
        overallCondition > 70 and "Good" or (overallCondition > 30 and "Fair" or "Poor")))
    print(string.format("Calculation: (%d%% × 0.7) + (%d%% × 0.2) + (%d%% × 0.1) = %d%%",
        math.floor(baseCondition), math.floor(rustCondition), math.floor(thumpCondition), overallCondition))
    print(string.format("Total Condition Points: %d / %d (Average from %d parts)",
        totalCondition,
        partCount * 100,
        partCount))

    print("======================================")

    return overallCondition
end

print("ZM_Autoshop module loaded")