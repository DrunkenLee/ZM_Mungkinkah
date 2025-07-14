ZM_Autoshop = ZM_Autoshop or {}

local function getVehiclePriceFromSandbox(vehicleScriptName)
  if not SandboxVars or not SandboxVars.ZM_Autoshop then
    print("No sandbox variables found for ZM_Autoshop")
    return 0
  end

  for i = 1, 10 do
    local vehicleNameKey = "vehicleScriptNames" .. i
    local vehiclePriceKey = "vehicleScriptNames" .. i .. "Price"

    local configuredVehicle = SandboxVars.ZM_Autoshop[vehicleNameKey]
    local configuredPrice = SandboxVars.ZM_Autoshop[vehiclePriceKey]

    if configuredVehicle and configuredVehicle == vehicleScriptName then
      print("Found price for " .. vehicleScriptName .. ": " .. (configuredPrice or 0))
      return configuredPrice or 0
    end
  end

  print("No price configured for vehicle: " .. vehicleScriptName)
  return 0
end

local function calculateConditionAdjustedPoints(basePrice, condition)
  if not basePrice or basePrice <= 0 then
    return 0
  end

  if not condition or condition < 0 then
    condition = 0
  elseif condition > 100 then
    condition = 100
  end

  local finalPoints = math.floor(basePrice * (condition / 100.0))

  print(string.format("Points calculation: %d base price × %d%% condition = %d points",
      basePrice, condition, finalPoints))

  return finalPoints
end

local function getVehicleScriptNamesFromSandbox()
  local vehicleNames = {}

  if SandboxVars and SandboxVars.ZM_Autoshop then
    for i = 1, 10 do
      local vehicleKey = "vehicleScriptNames" .. i
      local vehicleName = SandboxVars.ZM_Autoshop[vehicleKey]

      if vehicleName and vehicleName ~= "" then
        table.insert(vehicleNames, vehicleName)
        print("Added vehicle from sandbox slot " .. i .. ": " .. vehicleName)
      end
    end
  end

  return vehicleNames
end

function ZM_Autoshop.checkVehicleInEndpoint(player, vehicleScriptNames, endPointArea)
  if not player then
    print("Missing player parameter")
    return false, nil, nil
  end

  if not vehicleScriptNames then
    vehicleScriptNames = getVehicleScriptNamesFromSandbox()
  end

  if type(vehicleScriptNames) == "string" then
    vehicleScriptNames = {vehicleScriptNames}
  end

  if not vehicleScriptNames or #vehicleScriptNames == 0 then
    print("No vehicle script names found in sandbox options")
    return false, nil, nil
  end

  local defaultArea = {
    x1 = 11329,
    y1 = 8225,
    x2 = 11334,
    y2 = 8232,
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
    player:Say("You are not at the endpoint area.")
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

              print("Generating vehicle condition report...")
              local condition = ZM_Autoshop.printVehicleCondition(vehicle, true)
              player:Say("Vehicle condition: " .. condition .. "%")

              local basePrice = getVehiclePriceFromSandbox(scriptName)

              if basePrice <= 0 then
                player:Say("Error: No price configured for this vehicle type.")
                print("Error: No price found for vehicle " .. scriptName)
                return false, nil, nil
              end

              local finalPoints = calculateConditionAdjustedPoints(basePrice, condition)

              if finalPoints <= 0 then
                player:Say("Vehicle condition too poor - no payment awarded.")
                print("Vehicle condition too poor for payment")
              else
                GlobalMethods.addPlayerPoints(player:getUsername(), finalPoints)

                player:Say(string.format("Vehicle sold! Base price: %d, Condition: %d%%, Points awarded: %d",
                      basePrice, condition, finalPoints))
                print(string.format("Awarded %d points to %s for %s (condition: %d%%)",
                    finalPoints, player:getUsername(), scriptName, condition))

                -- Play success sound locally to the client
                getSoundManager():PlaySound("cekring", false, 1.0)
                print("Playing success sound: cekring.ogg")
              end

              local vehicleID = vehicle:getId()
              local vehicleX = vehicle:getX()
              local vehicleY = vehicle:getY()
              local vehicleZ = vehicle:getZ()

              sendClientCommand(player, "ZM_Autoshop", "RemoveVehicle", {
                vehicleID = vehicleID,
                scriptName = scriptName,
                condition = condition,
                basePrice = basePrice,
                finalPoints = finalPoints,
                x = vehicleX,
                y = vehicleY,
                z = vehicleZ
              })

              player:Say("Processing vehicle removal...")
              print("Sent vehicle removal request to server for: " .. scriptName)
              break
            end
          end
          if vehicleFound then break end
        end
      end
    end
  end

  if not vehicleFound then
    player:Say("No matching vehicle found in the endpoint area, I need to bring " .. table.concat(vehicleScriptNames, ", "))
    print("None of the sandbox vehicles found at endpoint: " .. table.concat(vehicleScriptNames, ", "))
    return false, nil, nil
  end

  return true, foundVehicle, foundScriptName
end

local function onServerCommand(module, command, args)
  if module ~= "ZM_Autoshop" then return end

  if command == "VehicleRemoved" then
    local player = getPlayer()
    if not player then return end

    if args.success then
      player:Say("The vehicle has been processed and removed.")
      print("Server confirmed vehicle removal: " .. (args.vehicleID or "unknown"))
    else
      player:Say("Failed to process vehicle removal.")
      print("Server failed to remove vehicle: " .. (args.message or "unknown error"))
    end
  end
end

Events.OnServerCommand.Add(onServerCommand)

function ZM_Autoshop.checkAnyVehicleInEndpoint(player, endPointArea)
  if not player then return false, {} end
  local defaultArea = {
    x1 = 11330,
    y1 = 8226,
    x2 = 11332,
    y2 = 8231,
  }

  endPointArea = endPointArea or defaultArea

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

  local parts = vehicle:getPartCount()
  local totalCondition = 0
  local partCount = 0
  local allPartsInfo = {}

  local engine = vehicle:getPartById("Engine")
  local battery = vehicle:getPartById("Battery")
  local gasAmount = vehicle:getPartById("GasTank") and vehicle:getPartById("GasTank"):getContainerContentAmount() or 0
  local gasCapacity = vehicle:getPartById("GasTank") and vehicle:getPartById("GasTank"):getContainerCapacity() or 100

  for i=1, parts do
    local part = vehicle:getPartByIndex(i-1)
    if part then
      local condition = part:getCondition()
      local partId = part:getId()

      totalCondition = totalCondition + condition
      partCount = partCount + 1

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

  local rust = vehicle:getRust() * 100
  local thumpCondition = (vehicle:getThumpCondition() or 0) * 100

  local rustCondition = math.max(0, 100 - rust)

  print("====== VEHICLE CONDITION REPORT ======")
  print("Vehicle: " .. vehicle:getScriptName())
  print("ID: " .. vehicle:getId())
  print("Total Parts Assessed: " .. partCount)

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

  local baseCondition = partCount > 0 and (totalCondition / partCount) or 0

  if detailed then
    print("\n--- ALL PARTS DETAILED REPORT ---")
    for _, partInfo in ipairs(allPartsInfo) do
      local status = partInfo.condition > 70 and "Good" or (partInfo.condition > 30 and "Fair" or "Poor")
      print(string.format("%s: %d%% (%s)", partInfo.id, partInfo.condition, status))
    end
  end

  local overallCondition = math.floor(
    (baseCondition * 0.7) +
    (rustCondition * 0.2) +
    (thumpCondition * 0.1)
  )

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

function ZM_Autoshop.listCurrentPricing()
  print("====== CURRENT AUTOSHOP PRICING ======")
  if not SandboxVars or not SandboxVars.ZM_Autoshop then
    print("No sandbox variables configured!")
    return
  end

  for i = 1, 10 do
    local vehicleKey = "vehicleScriptNames" .. i
    local priceKey = "vehicleScriptNames" .. i .. "Price"

    local vehicleName = SandboxVars.ZM_Autoshop[vehicleKey]
    local vehiclePrice = SandboxVars.ZM_Autoshop[priceKey]

    if vehicleName and vehicleName ~= "" then
      print(string.format("Slot %d: %s = %d points", i, vehicleName, vehiclePrice or 0))
    end
  end
  print("======================================")
end

print("ZM_Autoshop module loaded with pricing system")
