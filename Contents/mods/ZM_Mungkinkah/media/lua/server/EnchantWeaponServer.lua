if isClient() then return end

-- Global table to store all weapon enchantment data
-- Structure: WeaponEnchantments[playerUsername][weaponID] = {enchantment data}
local WeaponEnchantments = {}

local function addEnchantedWeaponToGlobalData(weaponID, username, weaponName, enchantLevel, isBroken)
    print("[ZM_EnchantWeaponServer] Adding enchanted weapon to global data")
    if not weaponID then return end

    -- Initialize global mod data if needed
    if not ModData.exists("enchantedWeaponIds") then
        ModData.add("enchantedWeaponIds", {})
    end

    local enchantedWeapons = ModData.get("enchantedWeaponIds")

    -- Add the weapon with metadata
    enchantedWeapons[weaponID] = {
        username = username,
        weaponName = weaponName,
        enchantLevel = enchantLevel,
        isBroken = isBroken,
        timestamp = getGameTime():getWorldAgeHours()
    }

    -- Save the mod data
    ModData.transmit("enchantedWeaponIds")
    print("[ZM_EnchantWeaponServer] Added weapon ID " .. weaponID .. " to global enchanted weapons database")
end

-- Serialize and save weapon enchantments to disk - separate file per user
local function saveWeaponEnchantmentsToFile()
    local dirPath = "WeaponsData/"
    local saveCount = 0

    -- Save each user's data to their own file
    for username, weapons in pairs(WeaponEnchantments) do
        local filePath = dirPath .. "weapons_" .. username .. ".txt"
        print("[ZM_EnchantWeaponServer] Saving data for user: " .. username .. " to file: " .. filePath)

        -- Write to file
        local writer = getFileWriter(filePath, true, false)
        if writer then
            -- Write user header
            writer:write("USER:" .. username .. "\n")

            -- Write each weapon's data
            local weaponsCount = 0
            for weaponID, data in pairs(weapons) do
                local dataString = weaponID .. "|" ..
                       tostring(data.minDamage) .. "|" ..
                       tostring(data.maxDamage) .. "|" ..
                       tostring(data.enchantLevel) .. "|" ..
                       tostring(data.isPositive) .. "|" ..
                       tostring(data.weaponType) .. "|" ..
                       tostring(data.originalName) .. "|" ..
                       tostring(data.customName or "Unknown") .. "|" ..
                       tostring(data.saveName or "INVALIDDATA") .. "|" ..
                       tostring(data.timestamp) .. "|" ..
                       tostring(data.boundToOrb or false)

                writer:write(dataString .. "\n")
                weaponsCount = weaponsCount + 1
            end

            writer:close()
            saveCount = saveCount + 1
            print("[ZM_EnchantWeaponServer] Saved " .. weaponsCount .. " weapons for " .. username)
        else
            print("[ZM_EnchantWeaponServer] ERROR: Failed to open file for writing: " .. filePath)
        end
    end

    print("[ZM_EnchantWeaponServer] Successfully saved weapon data for " .. saveCount .. " users")
    return true
end

-- Function to get weapon enchantment data for a specific username
local function getUserWeaponData(username)
    if not username or username == "" then
        print("[ZM_EnchantWeaponServer] ERROR: No username provided")
        return nil
    end

    -- Define the file path
    local filePath = "WeaponsData/weapons_" .. username .. ".txt"
    print("[ZM_EnchantWeaponServer] Loading from: " .. filePath)

    -- Create table to store weapons data
    local weaponsData = {}

    -- Try to open and read the file
    local reader = getFileReader(filePath, false)
    if not reader then
        print("[ZM_EnchantWeaponServer] ERROR: Cannot read file for username: " .. username)
        return nil
    end

    -- Read the first line to verify username
    local line = reader:readLine()
    if not line or not line:find("USER:" .. username) then
        print("[ZM_EnchantWeaponServer] ERROR: File does not contain data for username: " .. username)
        reader:close()
        return nil
    end

    -- Parse the file line by line
    while true do
        line = reader:readLine()
        if not line then break end

        -- Split the line into components
        local parts = {}
        for part in string.gmatch(line, "[^|]+") do
            table.insert(parts, part)
        end

        -- If we have enough parts, construct the weapon data
        if #parts >= 10 then
            local weaponData = {
                weaponID = parts[1],
                minDamage = tonumber(parts[2]),
                maxDamage = tonumber(parts[3]),
                enchantLevel = tonumber(parts[4]),
                isPositive = parts[5] ~= "nil" and parts[5] == "true",
                weaponType = parts[6],
                originalName = parts[7],
                customName = parts[8],
                saveName = parts[9],
                timestamp = tonumber(parts[10]),
                boundToOrb = parts[11] == "true"
            }

            table.insert(weaponsData, weaponData)
        end
    end

    -- Close the file
    reader:close()

    print("[ZM_EnchantWeaponServer] Loaded " .. #weaponsData .. " weapons for " .. username)
    return weaponsData
end

local function clearEnchantedWeaponIds()
    -- Check if ModData exists before attempting to clear
    if ModData.exists("enchantedWeaponIds") then
        -- Reset to empty table
        ModData.remove("enchantedWeaponIds")
        ModData.add("enchantedWeaponIds", {})
        -- Transmit the empty data to all clients
        ModData.transmit("enchantedWeaponIds")
        print("[ZM_EnchantWeaponServer] DEBUG: All enchanted weapon IDs have been cleared from ModData")
        return true
    else
        print("[ZM_EnchantWeaponServer] DEBUG: No enchanted weapon IDs ModData exists to clear")
        return false
    end
end

local function storeWeaponEnchantment(username, weaponID, weaponType, enchantmentData)
    if not username or username == "" or not weaponID then
        print("[ZM_EnchantWeaponServer] ERROR: Invalid username or weaponID for storing enchantment")
        return false
    end

    -- Initialize user's weapons table if needed
    if not WeaponEnchantments[username] then
        WeaponEnchantments[username] = {}
    end

    -- Add timestamp to the data
    enchantmentData.timestamp = getGameTime():getWorldAgeHours()
    enchantmentData.weaponType = weaponType

    -- Store the data
    WeaponEnchantments[username][weaponID] = enchantmentData

    -- Save to disk
    local success = saveWeaponEnchantmentsToFile()

    print("[ZM_EnchantWeaponServer] Stored weapon enchantment for " ..
          username .. ", weapon ID: " .. weaponID)

    return success
end

-- Handle enchantment requests
local function onClientCommand(module, command, player, data)

  if module == "EnchantWeapon" and command == "clearEnchantedWeaponIds" then
    print("[ZM_EnchantWeaponServer] Received request to clear enchanted weapon IDs")

    -- Check if player has admin privileges (optional security check)
    local isAdmin = player:getAccessLevel() ~= "None"
    if isAdmin then
        local success = clearEnchantedWeaponIds()

        -- Send confirmation to client
        sendServerCommand(player, "EnchantWeapon", "clearEnchantedWeaponIdsResult", {
            success = success
        })

        print("[ZM_EnchantWeaponServer] Cleared enchanted weapon IDs: " .. tostring(success))
    else
        print("[ZM_EnchantWeaponServer] Permission denied for player: " .. player:getUsername())
        sendServerCommand(player, "EnchantWeapon", "clearEnchantedWeaponIdsResult", {
            success = false,
            error = "Permission denied"
        })
    end

    return
  end

  if module == "EnchantWeapon" and command == "trackEnchantedWeapon" then
      print("[ZM_EnchantWeaponServer] Tracking enchanted weapon")
      if data then
          print("[ZM_EnchantWeaponServer] Received data:")
          for key, value in pairs(data) do
            -- Handle different value types
            local valueStr
            if type(value) == "table" then
              valueStr = "table"
            else
              valueStr = tostring(value)
            end
            print("  - " .. key .. " = " .. valueStr)
          end
      else
          print("[ZM_EnchantWeaponServer] No data received")
      end

      local weaponID = data.weaponID
      local username = player:getUsername()
      local weaponName = data.weaponName
      local enchantLevel = data.enchantLevel or 0
      local isBroken = data.isBroken or false

      if not weaponID then
          weaponID = data.weaponID
      end

      if not weaponID then
          print("[ZM_EnchantWeaponServer] ERROR: No weapon ID provided for tracking")
          return
      end


      addEnchantedWeaponToGlobalData(weaponID, username, weaponName, enchantLevel, isBroken)

      sendServerCommand(player, "EnchantWeapon", "trackingConfirmed", {
          weaponID = weaponID,
          success = true
      })

      return
    end

    if module == "EnchantWeapon" and command == "checkEnchantedWeapon" then
      print("[ZM_EnchantWeaponServer] Checking if weapon exists in database")

      local weaponID = data.weaponID
      local isFound = false
      local isBroken = false
      local weaponMetadata = nil

      -- Check if the weapon exists in the enchanted weapons database
      if ModData.exists("enchantedWeaponIds") then
          local enchantedWeapons = ModData.get("enchantedWeaponIds")

          if enchantedWeapons and enchantedWeapons[weaponID] then
              print("[ZM_EnchantWeaponServer] Found weapon ID " .. weaponID .. " in database")
              print("[ZM_EnchantWeaponServer] Found weapon ID " .. weaponID .. " in database")
              isFound = true
              isBroken = enchantedWeapons[weaponID].isBroken or false
              weaponMetadata = enchantedWeapons[weaponID]  -- Store metadata in a variable we can access later
              print("[ZM_EnchantWeaponServer] Weapon found in database. Broken status: " .. tostring(isBroken))
          else
              print("[ZM_EnchantWeaponServer] Weapon not found in database")
          end
      else
          print("[ZM_EnchantWeaponServer] No enchanted weapons database exists")
      end

      -- Send the result back to the client
      sendServerCommand(player, "EnchantWeapon", "weaponCheckResult", {
          weaponID = weaponID,
          isFound = isFound,
          isBroken = isBroken,
          metadata = weaponMetadata  -- Use the variable we stored earlier
      })

      return  -- Add return statement to properly exit the handler
    end

    if module == "ZM_Mungkinkah" and command == "PlayWorldSound" then
        print("[ZM_EnchantWeaponServer] Broadcasting sound: " .. tostring(data.sound))

        -- Validate required fields
        if not data.x or not data.y or not data.z or not data.sound then
            print("[ZM_EnchantWeaponServer] ERROR: Missing required sound data!")
            return
        end

        -- Extract sound data
        local x = data.x
        local y = data.y
        local z = data.z
        local radius = data.radius or 20
        local volume = data.volume or 1.0
        local sound = data.sound

        -- Get all online players
        local players = getOnlinePlayers()
        if players then
            -- For each player, check distance and send sound command if they're nearby
            for i = 0, players:size() - 1 do
                local playerObj = players:get(i)

                -- Calculate distance to sound source
                local px = playerObj:getX()
                local py = playerObj:getY()
                local distance = math.sqrt((px - x)^2 + (py - y)^2)

                -- Only send to players within radius
                if distance <= radius then
                    -- Send command to this specific player
                    local sound = getSoundManager():PlaySound("rganvil", false, 0);
                    getSoundManager():PlayAsMusic("rganvil", sound, false, 0);
                    -- sound:setVolume(0.1);

                    sendServerCommand(playerObj, "ZM_Mungkinkah", "PlayWorldSound", {
                        x = x,
                        y = y,
                        z = z,
                        sound = sound,
                        distance = distance,
                        radius = radius,
                        volume = volume
                    })

                    print("[ZM_EnchantWeaponServer] Sound sent to player: " .. playerObj:getUsername())
                end
            end
        else
            -- Single player mode
            sendServerCommand("ZM_Mungkinkah", "PlayWorldSound", {
                x = x,
                y = y,
                z = z,
                sound = sound,
                radius = radius,
                volume = volume
            })
        end

        print("[ZM_EnchantWeaponServer] Sound broadcast completed")
        return
    end

    if module == "EnchantWeapon" and command == "saveEnchantmentData" then
      print("[ZM_EnchantWeaponServer] Saving weapon enchantment data")

      local weaponID = data.weaponID
      local weaponType = data.weaponType
      local uniqueID = data.uniqueID or (weaponID .. "_" .. getGameTime():getWorldAgeHours())

      local enchantmentData = {
          minDamage = data.minDamage,
          maxDamage = data.maxDamage,
          enchantLevel = data.enchantLevel,
          isPositive = data.isPositive,
          originalName = data.originalName,
          boundToOrb = data.boundToOrb,
          customName = data.customName,
          saveName = data.saveName,
          uniqueID = uniqueID,
          timestamp = data.timestamp or getGameTime():getWorldAgeHours()
      }

      -- Initialize username's weapons table if needed
      local username = player:getUsername()
      if not WeaponEnchantments[username] then
          WeaponEnchantments[username] = {}
      end

      -- Store using uniqueID as key instead of just weaponID
      WeaponEnchantments[username][uniqueID] = enchantmentData

      local success = storeWeaponEnchantment(player:getUsername(), weaponID, weaponType, enchantmentData)

      -- Acknowledge the save
      sendServerCommand(player, "EnchantWeapon", "saveEnchantmentResult", {
          weaponID = weaponID,
          success = success
      })

      print("[ZM_EnchantWeaponServer] Weapon data saved: " .. tostring(success))
      return
    end

    if module == "EnchantWeapon" and command == "loadEnchantmentData" then
        print("[ZM_EnchantWeaponServer] Loading weapon enchantment data")

        local weaponID = data.weaponID
        local username = player:getUsername()

        -- Retrieve from server-side storage
        local enchantmentData = getWeaponEnchantment(username, weaponID)
        -- Send the data back to client
        sendServerCommand(player, "EnchantWeapon", "loadEnchantmentResult", {
            weaponID = weaponID,
            success = enchantmentData ~= nil,
            enchantmentData = enchantmentData
        })

        print("[ZM_EnchantWeaponServer] Weapon data loaded: " .. tostring(enchantmentData ~= nil))
        return
    end

    if module == "EnchantWeapon" and command == "applyEnchantment" then
        print("[ZM_EnchantWeaponServer] Processing enchantment request")

        -- Get the weapon
        local weaponID = data.weaponID
        local playerID = data.playerID

        print("[ZM_EnchantWeaponServer] Weapon ID: " .. tostring(weaponID) .. ", Player ID: " .. tostring(playerID))

        -- Get player from ID
        local playerObj = getPlayerByOnlineID(playerID)
        print("[ZM_EnchantWeaponServer] Player ID: " .. tostring(playerID))
        if not playerObj then
            print("[ZM_EnchantWeaponServer] ERROR: Player not found!")
            return
        end

        print("[ZM_EnchantWeaponServer] Found player: " .. tostring(playerObj:getUsername()))

        -- Get weapon from inventory
        local inventory = playerObj:getInventory()
        local weapon = inventory:getItemById(weaponID)

        if not weapon then
            print("[ZM_EnchantWeaponServer] ERROR: Weapon not found!")
            return
        end

        print("[ZM_EnchantWeaponServer] Found weapon: " .. tostring(weapon:getName()))

        -- Step 1: Roll for damage type (1-2)
        local damageTypeRoll = ZombRand(2) + 1 -- 1 or 2
        local damageType = damageTypeRoll == 1 and "minDamage" or "maxDamage"

        -- Step 2: Roll for damage amount (1-10)
        local damageRoll = ZombRand(10) + 1 -- 1 to 10

        print("[ZM_EnchantWeaponServer] Rolls: Type=" .. damageTypeRoll .. ", Damage=" .. damageRoll)

        -- Step 3: Calculate damage modifier based on roll
        local damageModifier = damageRoll / 20 -- 0.05 to 0.5

        -- Step 4: Apply positive or negative effect based on roll
        local isPositive = damageRoll > 5
        local currentDamage = 0
        local newDamage = 0

        if damageType == "minDamage" then
            currentDamage = weapon:getMinDamage()
            if isPositive then
                newDamage = currentDamage + damageModifier
            else
                newDamage = math.max(0.1, currentDamage - damageModifier) -- Prevent negative damage
            end
            weapon:setMinDamage(newDamage)
        else -- maxDamage
            currentDamage = weapon:getMaxDamage()
            if isPositive then
                newDamage = currentDamage + damageModifier
            else
                newDamage = math.max(0.1, currentDamage - damageModifier) -- Prevent negative damage
            end
            weapon:setMaxDamage(newDamage)
        end

        print("[ZM_EnchantWeaponServer] Result: Type=" .. damageType .. ", Positive=" .. tostring(isPositive) ..
              ", Old=" .. currentDamage .. ", New=" .. newDamage)

        -- Mark as enchanted with the specific type
        if not weapon:getModData().enchantments then
            weapon:getModData().enchantments = {}
        end

        weapon:getModData().enchantments[damageType] = isPositive
        weapon:getModData().enchanted = true

        print("[ZM_EnchantWeaponServer] Sending response to client")

        -- Check if player is still connected
        if not playerObj:isConnected() then
            print("[ZM_EnchantWeaponServer] ERROR: Player is not connected!")
            return
        end

        -- Use pcall to catch any errors during sending
        local success, error = pcall(function()
            -- CRITICAL: Send the results back to client
            sendServerCommand(playerObj, "EnchantWeapon", "enchantResult", {
                weaponID = weaponID,
                damageType = damageType,
                isPositive = isPositive,
                damageRoll = damageRoll,
                newDamage = newDamage,
                currentDamage = currentDamage
            })
        end)

        if success then
            print("[ZM_EnchantWeaponServer] Response sent successfully!")
        else
            print("[ZM_EnchantWeaponServer] ERROR sending response: " .. tostring(error))
        end
    end

    if module == "EnchantWeapon" and command == "syncEnchantment" then
      print("[ZM_EnchantWeaponServer] Processing enchantment sync from client")

      -- Get the weapon
      local weaponID = data.weaponID
      local isPositive = data.isPositive
      local damageRoll = data.damageRoll
      local damageChange = data.damageChange or (damageRoll / 20)
      local damageCap = data.damageCap or 0.8
      local minDamage = data.minDamage
      local maxDamage = data.maxDamage
      local enchantLevel = data.enchantLevel or 0

      print("[ZM_EnchantWeaponServer] Weapon ID: " .. tostring(weaponID) ..
            ", Positive: " .. tostring(isPositive) ..
            ", Roll: " .. tostring(damageRoll) ..
            ", Min: " .. tostring(minDamage) ..
            ", Max: " .. tostring(maxDamage))

      -- Get player object
      local playerObj = getPlayerByOnlineID(player:getOnlineID())

      if not playerObj then
          print("[ZM_EnchantWeaponServer] ERROR: Player not found!")
          return
      end

      -- Get weapon from inventory
      local inventory = playerObj:getInventory()
      local weapon = inventory:getItemById(weaponID)
      if not weapon then
          local primaryItem = playerObj:getPrimaryHandItem()
          if primaryItem and primaryItem:getID() == weaponID then
              weapon = primaryItem
          else
              print("[ZM_EnchantWeaponServer] ERROR: Weapon not found in inventory or primary hand!")
              return
          end
      end

      -- Validate and apply the changes to both min and max damage
      local currentMinDamage = weapon:getMinDamage()
      local currentMaxDamage = weapon:getMaxDamage()

      -- Use more flexible validation - allow up to 1.5x the damage cap as the maximum change
      local validationMultiplier = 1.5
      local maxAllowedChange = damageCap * validationMultiplier

      print("[ZM_EnchantWeaponServer] Current values - Min: " .. currentMinDamage .. ", Max: " .. currentMaxDamage)
      print("[ZM_EnchantWeaponServer] New values - Min: " .. minDamage .. ", Max: " .. maxDamage)
      print("[ZM_EnchantWeaponServer] Change amount: " .. damageChange .. ", Max allowed: " .. maxAllowedChange)

      -- Only apply if changes are within acceptable range
      local success = false
      if (math.abs(minDamage - currentMinDamage) <= maxAllowedChange) and
         (math.abs(maxDamage - currentMaxDamage) <= maxAllowedChange) then

          weapon:setMinDamage(minDamage)
          weapon:setMaxDamage(maxDamage)

          -- Mark as enchanted
          if not weapon:getModData().enchantments then
              weapon:getModData().enchantments = {}
          end
          weapon:getModData().enchantments["minDamage"] = isPositive
          weapon:getModData().enchantments["maxDamage"] = isPositive
          weapon:getModData().enchanted = true

          -- Store enchantment level
          if not weapon:getModData().enchantmentStats then
              weapon:getModData().enchantmentStats = {
                  enchantCounter = enchantLevel or 0,
                  originalName = weapon:getName():gsub("_.*_[+-]%d+$", "")
              }
          else
              weapon:getModData().enchantmentStats.enchantCounter = enchantLevel or
                  weapon:getModData().enchantmentStats.enchantCounter
          end

          print("[ZM_EnchantWeaponServer] Enchantment applied successfully")
          success = true

          -- ADD THIS: Track the enchanted weapon in global data
          local weaponName = weapon:getName()
          local username = playerObj:getUsername()
          local isBroken = weapon:getCondition() <= 0 or data.isBroken or false
          addEnchantedWeaponToGlobalData(weaponID, username, weaponName, enchantLevel, isBroken)
          print("[ZM_EnchantWeaponServer] Weapon added to global tracking database")
      else
          print("[ZM_EnchantWeaponServer] ERROR: Invalid enchantment data from client! Changes too large.")
          print("[ZM_EnchantWeaponServer] Min diff: " .. math.abs(minDamage - currentMinDamage) ..
                ", Max diff: " .. math.abs(maxDamage - currentMaxDamage) ..
                ", Allowed: " .. maxAllowedChange)

          addEnchantedWeaponToGlobalData(weaponID, username, weaponName, enchantLevel, isBroken)
          success = true
      end
      sendServerCommand(playerObj, "EnchantWeapon", "syncAcknowledged", {
          weaponID = weaponID,
          isPositive = isPositive,
          minDamage = weapon:getMinDamage(),
          maxDamage = weapon:getMaxDamage(),
          success = success
      })
    end

    if module == "EnchantWeapon" and command == "getUserWeapons" then
        print("[ZM_EnchantWeaponServer] Getting weapons data for user: " .. tostring(data.username))
        local username = data.username

        -- Get the weapons data
        local weaponsData = getUserWeaponData(username)

        -- Send data back to the client
        sendServerCommand(player, "EnchantWeapon", "receiveUserWeapons", {
            username = username,
            weapons = weaponsData
        })
        return
    end
end



-- IMPORTANT: Make sure we remove any existing handler and add our new one
Events.OnClientCommand.Remove(onClientCommand)
Events.OnClientCommand.Add(onClientCommand)
print("[ZM_EnchantWeaponServer] Registered client command handler")