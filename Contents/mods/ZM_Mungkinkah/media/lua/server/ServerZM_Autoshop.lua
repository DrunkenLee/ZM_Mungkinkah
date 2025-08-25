if isClient() then return end

local ServerZM_Autoshop = {}

local function onClientCommand(module, command, player, args)
  if module ~= "ZM_Autoshop" then return end

  if command == "RemoveVehicle" then
    if not args.vehicleID then
      print("Error: No vehicle ID provided for removal")
      sendServerCommand(player, "ZM_Autoshop", "VehicleRemoved", {
        success = false,
        message = "No vehicle ID provided",
        finalPoints = args.finalPoints,
        basePrice = args.basePrice,
        condition = args.condition,
      })
      return
    end

    print("Server received request to remove vehicle with ID: " .. args.vehicleID)

    local vehicleToRemove = getVehicleById(args.vehicleID)
    if vehicleToRemove then
      local vehicleX = vehicleToRemove:getX()
      local vehicleY = vehicleToRemove:getY()
      local vehicleZ = vehicleToRemove:getZ()
      local scriptName = args.scriptName or vehicleToRemove:getScriptName()
      local condition = args.condition or 0
      local finalPoints = args.finalPoints or 0

      print("Removing vehicle: " .. scriptName .. " at position (" .. vehicleX .. ", " .. vehicleY .. ")")
      print("Vehicle condition: " .. condition .. "%, Points awarded: " .. finalPoints)

      vehicleToRemove:setAlpha(0.0)
      vehicleToRemove:removeFromWorld()
      vehicleToRemove:removeFromSquare()

      local cell = getCell()
      if cell then
        local cellVehicles = cell:getVehicles()
        if cellVehicles then
          for i = 0, cellVehicles:size() - 1 do
            local v = cellVehicles:get(i)
            if v and v:getId() == args.vehicleID then
              cellVehicles:remove(i)
              break
            end
          end
        end
      end

      vehicleToRemove:permanentlyRemove()

      print("SERVER LOG: Vehicle sold - Player: " .. player:getUsername() ..
          ", Vehicle: " .. scriptName ..
          ", Condition: " .. condition .. "%" ..
          ", Points: " .. finalPoints)

      sendServerCommand(player, "ZM_Autoshop", "VehicleRemoved", {
        success = true,
        message = "The vehicle has been processed and removed.",
        vehicleID = args.vehicleID,
        scriptName = scriptName,
        condition = condition,
        finalPoints = finalPoints,
        x = vehicleX,
        y = vehicleY,
        z = vehicleZ
      })

      local players = getOnlinePlayers()
      local NOTIFY_RADIUS = 20

      for i = 0, players:size() - 1 do
        local nearbyPlayer = players:get(i)

        if nearbyPlayer ~= player then
          local px = nearbyPlayer:getX()
          local py = nearbyPlayer:getY()
          local dx = px - vehicleX
          local dy = py - vehicleY
          local distanceSquared = dx*dx + dy*dy

          if distanceSquared <= (NOTIFY_RADIUS * NOTIFY_RADIUS) then
            sendServerCommand(nearbyPlayer, "ZM_Autoshop", "VehicleRemoved", {
              success = true,
              message = "A vehicle has been processed at the auto shop.",
              vehicleID = args.vehicleID,
              scriptName = scriptName,
              x = vehicleX,
              y = vehicleY,
              z = vehicleZ,
              isNearbyNotification = true
            })
          end
        end
      end

      print("Vehicle " .. scriptName .. " successfully removed from server")
    else
      print("Could not find vehicle with ID: " .. args.vehicleID)
      sendServerCommand(player, "ZM_Autoshop", "VehicleRemoved", {
        success = false,
        message = "Vehicle not found on server."
      })
    end
  end
end

Events.OnClientCommand.Add(onClientCommand)

print("Server ZM_Autoshop initialized with proper vehicle removal system")
