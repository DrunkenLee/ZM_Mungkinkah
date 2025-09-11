--***********************************************************
--**            SIMPLE WEAPON ENCHANT UI                   **
--***********************************************************

ISEnchantWeaponUI = ISPanel:derive("ISEnchantWeaponUI")

-- Global variable to track UI instance
local EnchantingUI = nil

-- First, add a callback system to track pending weapon checks
if not _G.PendingWeaponChecks then
    _G.PendingWeaponChecks = {}
end

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- Add this server response handler to process weapon checks
local function handleWeaponCheckResponse(module, command, args)
    if module == "EnchantWeapon" and command == "weaponCheckResult" then
        local weaponID = args.weaponID
        local isFound = args.isFound
        local isBroken = args.isBroken or false

        -- Check if we have a pending callback for this weapon
        if _G.PendingWeaponChecks[weaponID] then
            -- Call the callback with the result
            _G.PendingWeaponChecks[weaponID](isFound, isBroken, args)
            -- Remove the pending check
            _G.PendingWeaponChecks[weaponID] = nil
        end
    end
end

-- Register the server response handler
Events.OnServerCommand.Add(handleWeaponCheckResponse)

function ISEnchantWeaponUI:initialise()
    ISPanel.initialise(self)

    -- Always reset protection flag to false on UI initialization
    if PlayerFlagHandler and PlayerFlagHandler.setFlag then
        PlayerFlagHandler.setFlag("enchantProtection", false)
    end
end

function ISEnchantWeaponUI:createChildren()
    ISPanel.createChildren(self)

    -- Button dimensions
    local btnWid = 120
    local btnHgt = FONT_HGT_MEDIUM + 6

    -- Enchant button (always start with 2500 points cost)
    self.enchantButton = ISButton:new(self.width/2 - btnWid/2, 150,
                                    btnWid, btnHgt, "Pay (2500 pts)",
                                    self, ISEnchantWeaponUI.onClick)
    self.enchantButton:initialise()
    self.enchantButton:instantiate()
    self.enchantButton.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    self.enchantButton.font = UIFont.Medium
    self:addChild(self.enchantButton)

    -- Status text - simple text display
    self.statusText = "Ready to enchant"
    self.statusColor = {r=1, g=1, b=1}

    -- Add protection checkbox (always start unchecked)
    self.protectionCheckbox = ISTickBox:new(self.width/2 - 100, 280, 200, 20, "", self, ISEnchantWeaponUI.onToggleProtection)
    self.protectionCheckbox:initialise()
    self.protectionCheckbox:instantiate()
    self.protectionCheckbox:addOption("Enable Enchant Protection (+10000 pts)")
    -- Force it to be unchecked regardless of flag state
    self.protectionCheckbox:setSelected(1, false)
    self.protectionCheckbox.tooltip = "Protection prevents weapon breakage on negative enchantment, but costs 10,000 extra points"
    self:addChild(self.protectionCheckbox)

    -- Close button
    self.closeButton = ISButton:new(self.width - btnWid - 10, self.height - btnHgt - 10,
                                  btnWid, btnHgt, "Close", self, ISEnchantWeaponUI.onClick)
    self.closeButton.internal = "CLOSE"
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self.closeButton.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    self.closeButton.font = UIFont.Medium
    self:addChild(self.closeButton)
    self.enchantResult = nil
end

function ISEnchantWeaponUI:onToggleProtection(index, selected)
    PlayerFlagHandler.giveFlag("enchantProtection", selected)
    self:updateEnchantButton()
end

function ISEnchantWeaponUI:updateEnchantButton()
    -- Remove old button if it exists
    if self.enchantButton then
        self:removeChild(self.enchantButton)
    end

    -- Button dimensions (same as in createChildren)
    local btnWid = 120
    local btnHgt = FONT_HGT_MEDIUM + 6

    -- Get current protection status and calculate cost
    local hasProtection = PlayerFlagHandler.getFlag("enchantProtection") or false
    local cost = hasProtection and 12500 or 2500

    -- Create new button with updated text
    self.enchantButton = ISButton:new(self.width/2 - btnWid/2, 150,
                                    btnWid, btnHgt, "Pay (" .. cost .. " pts)",
                                    self, ISEnchantWeaponUI.onClick)
    self.enchantButton:initialise()
    self.enchantButton:instantiate()
    self.enchantButton.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    self.enchantButton.font = UIFont.Medium
    self:addChild(self.enchantButton)
end

-- Add this helper function to rename weapons after enchantment
function ISEnchantWeaponUI:renameEnchantedWeapon(weapon, username, isPositive)
  if not weapon then return end

  -- Initialize ModData for enchantment tracking if needed
  if not weapon:getModData().enchantmentStats then
      weapon:getModData().enchantmentStats = {
          enchantCounter = 0,
          originalName = weapon:getName()
      }
  end

  -- Get original name or current base name
  local baseName = weapon:getModData().enchantmentStats.originalName

  -- Update enchant counter (increment for positive, decrement for negative)
  -- Respect the +10/-10 limits
  if isPositive then
      if weapon:getModData().enchantmentStats.enchantCounter < 10 then
          weapon:getModData().enchantmentStats.enchantCounter = weapon:getModData().enchantmentStats.enchantCounter + 1
      end
  else
      if weapon:getModData().enchantmentStats.enchantCounter > -10 then
          weapon:getModData().enchantmentStats.enchantCounter = weapon:getModData().enchantmentStats.enchantCounter - 1
      end
  end

  -- Get current counter value
  local counter = weapon:getModData().enchantmentStats.enchantCounter

  -- Rename based on counter value
  if counter > 0 then
      -- Positive enchantment level
      weapon:setName(baseName .. "_" .. username .. "_+" .. counter)
  elseif counter < 0 then
      -- Negative enchantment level (use absolute value for display)
      weapon:setName(baseName .. "_" .. username .. "_-" .. math.abs(counter))
  else
      -- Counter is zero - reset to original name
      weapon:setName(baseName)
  end

  print("DEBUG: Weapon renamed to: " .. weapon:getName())
  return counter
end

-------------------------------------------- ON CLICK FUNCTION --------------------------------------------

function ISEnchantWeaponUI:onClick(button)
  local weaponIDExists = false
  local serverEnchantLevel = 20
  if button.internal == "CLOSE" then
      self:close()
      return
  end

  -- Get player and weapon with proper validation
  local player = getSpecificPlayer(0)
  if not player then
      self.statusText = "Error: Player not found"
      self.statusColor = {r=1, g=0.3, b=0.3}
      return
  end

  -- Get the weapon from player's hands
  local weapon = player:getPrimaryHandItem()
  if not weapon then
      self.statusText = "No weapon in hand!"
      self.statusColor = {r=1, g=0.3, b=0.3}
      return
  end

  local weaponID = weapon:getID()
  local weaponName = weapon:getName() or ""

  -- Set UI status to "checking"
  self.statusText = "Checking weapon database..."
  self.statusColor = {r=0.7, g=0.7, b=0.7}

  -- Send request to server to check if this weapon exists in the database
  sendClientCommand("EnchantWeapon", "checkEnchantedWeapon", {
      weaponID = weaponID,
      weaponName = weaponName
  })

  -- Store callback for when server responds
  _G.PendingWeaponChecks[weaponID] = function(isFound, isBroken, data)
      -- If the weapon is found and is broken, update UI and weapon
      print("DEBUG: Weapon check result - Found: " .. tostring(isFound) .. ", Broken: " .. tostring(isBroken))
      print("DEBUG: Weapon check result - Found: " .. tostring(isFound) .. ", Broken: " .. tostring(isBroken))
      print("DEBUG: Weapon check result - Found: " .. tostring(isFound) .. ", Broken: " .. tostring(isBroken))
      print("DEBUG: Weapon check result - Found: " .. tostring(isFound) .. ", Broken: " .. tostring(isBroken))

      if data then
          weaponIDExists = true
          if data.metadata and data.metadata.enchantLevel then
              serverEnchantLevel = data.metadata.enchantLevel or 20
          end
          print("DEBUG: Weapon check data - " .. tostring(data))
          print("DEBUG: Weapon check data - " .. tostring(data))
          print("DEBUG: Weapon check data - " .. tostring(data))
      end

      if isFound and isBroken then
          print("DEBUG: Weapon is Found and Broken")
          self.statusText = "Found broken weapon in database with the same ID!"
          self.statusColor = {r=1, g=0.3, b=0.3}

          -- Set condition to 0 if not already
          if weapon:getCondition() > 0 then
              weapon:setCondition(0)
              player:Say("Awh shit! My weapon broke!")
          end
          return
      end

      -- Continue with normal enchantment flow if the weapon isn't broken
      self:continueEnchantment(weapon, player, weaponIDExists, serverEnchantLevel)
  end

  -- Don't proceed yet - wait for server response via callback
end

-- Extract the rest of the enchantment logic to a separate function
function ISEnchantWeaponUI:continueEnchantment(weapon, player, weaponIDExists, serverEnchantLevel)

    local weaponName = weapon:getName() or ""
    if string.find(weaponName, "Broken") then
        self.statusText = "Weapon is broken!"
        self.statusColor = {r=1, g=0.3, b=0.3}
        return
    end

    -- Check if weapon exists and is a weapon
    if not weapon:IsWeapon() then
        self.statusText = "No weapon in hand!"
        self.statusColor = {r=1, g=0.3, b=0.3}
        return
    end

    -- Check if it's a melee weapon that needs the "Legend" requirement
    local isMelee = not weapon:isRanged()
    if isMelee then
        local weaponName = weapon:getName() or ""
        if not string.find(weaponName, "Legend") then
            self.statusText = "Only legendary melee weapons can be enchanted!"
            self.statusColor = {r=1, g=0.3, b=0.3}
            return
        end
    end

    -- Check if weapon is already at maximum enchantment level (+10)
    if weapon:getModData() and weapon:getModData().enchantmentStats and
       weapon:getModData().enchantmentStats.enchantCounter == 10 then
        self.statusText = "Weapon is too fragile for further enchantment (+10)!"
        self.statusColor = {r=1, g=0.6, b=0.1}
        return
    end
    -- Get username for points check and payment
    local username = player:getUsername() or "Player"
    local hasProtection = PlayerFlagHandler.getFlag("enchantProtection") or false
    local pointCost = 2500
    if hasProtection then
        pointCost = pointCost + 10000 -- Add 10,000 for protection
    end

    local playerPoints = GlobalMethods.getPlayerPoints(username) or 0
    if playerPoints == 0 then
        playerPoints = GlobalMethods.getPlayerPoints(username)
    end

    if playerPoints < pointCost then
        self.statusText = "Not enough points! (Need: " .. pointCost .. ")"
        self.statusColor = {r=1, g=0.3, b=0.3}
        return
    end

    -- Get current enchantment level - with safe access
    local enchantLevel = 0
    if weapon:getModData() and weapon:getModData().enchantmentStats then
        enchantLevel = weapon:getModData().enchantmentStats.enchantCounter or 0
    end
    local absLevel = math.abs(enchantLevel)

    -- Determine damage cap based on absolute enchantment level
    local damageCap = 0.2 -- Base cap is 30%
    if absLevel >= 3 and absLevel < 5 then
        damageCap = 0.4 -- 50% for +3 to +4
    elseif absLevel >= 5 and absLevel < 7 then
        damageCap = 0.6 -- 70% for +5 to +6
    elseif absLevel >= 7 then
        damageCap = 0.8 -- 100% for +7 and beyond
    end

    print(tostring(weaponIDExists) .. " ---- " .. tostring(serverEnchantLevel) .. " ---- " .. tostring(absLevel))
    if weaponIDExists and serverEnchantLevel ~= enchantLevel and serverEnchantLevel ~= 20 then
      print("DEBUG: Weapon ID exists on server, but enchantment level differs")
      self.statusText = "Weapon enchantment data mismatch from server! Please contact admin."
      return
    end

    -- Deduct points
    GlobalMethods.takePlayerPoints(username, pointCost)


    -- Perform enchantment logic on the client - now affecting both damage values
    local isPositive = ZombRand(10) < 6 -- 60% chance of positive outcome


    ---- +7 ENCHANTMENT BREAKAGE CHECK ----
    if enchantLevel and enchantLevel == 6 then
        print("DEBUG: Enchantment level 6 detected")
        isPositive = ZombRand(10) < 4
    end

    ---- +8 ENCHANTMENT BREAKAGE CHECK ----
    if enchantLevel and enchantLevel == 7 then
        print("DEBUG: Enchantment level 7 detected")
        isPositive = ZombRand(10) <= 3
    end

    ---- +9 ENCHANTMENT BREAKAGE CHECK ----
    if enchantLevel and enchantLevel == 8 then
        print("DEBUG: Enchantment level 8 detected")
        isPositive = ZombRand(10) <= 2
    end

    ---- +10 ENCHANTMENT BREAKAGE CHECK ----
    if enchantLevel and enchantLevel == 9 then
        print("DEBUG: Enchantment level 9 detected")
        isPositive = ZombRand(10) <= 1
    end

    local damageRoll = ZombRand(1, 21) -- Random roll between 1 and 20
    local minDamage = weapon:getMinDamage()
    local maxDamage = weapon:getMaxDamage()


    -- Apply the dynamic cap to damage change based on enchantment level
    local damageChange = math.min(damageRoll / 20, damageCap)

    -- Store original values for UI display
    local origMinDamage = minDamage
    local origMaxDamage = maxDamage

    -- Apply changes to both min and max damage
    if isPositive then
        -- Positive outcome: increase both damages
        minDamage = minDamage + damageChange
        maxDamage = maxDamage + damageChange
    else
        -- Negative outcome: decrease both damages and check for enchant protection
        if absLevel >= 7 then
          local isEnchantProtection = PlayerFlagHandler.getFlag("enchantProtection")
          if not isEnchantProtection then
              DebugSetWeaponConditionToZero()

              sendClientCommand("EnchantWeapon", "trackEnchantedWeapon", {
                weaponID = weaponID,
                weaponName = weaponName,
                enchantLevel = enchantLevel,
                isBroken = true
              })

              minDamage = minDamage - damageChange
              maxDamage = maxDamage - damageChange
          end
        else

          sendClientCommand("EnchantWeapon", "trackEnchantedWeapon", {
            weaponID = weaponID,
            weaponName = weaponName,
            enchantLevel = enchantLevel,
            isBroken = false
          })

          minDamage = minDamage - damageChange
          if minDamage < 0 then minDamage = 0 end
          maxDamage = maxDamage - damageChange
          if maxDamage < 0 then maxDamage = 0 end
          end
    end

    -- Ensure min damage is always less than or equal to max damage
    if minDamage > maxDamage then
        minDamage = maxDamage
    end

    -- Play different sounds based on outcome
    local x = player:getX()
    local y = player:getY()
    local z = player:getZ()

    -- Play sound locally first
    if isPositive then
        getSoundManager():PlaySound("rganvilsuccess", false, 1.0)
    else
        getSoundManager():PlaySound("rganvil", false, 1.0)
    end

    -- Send sound command to server to broadcast to all players
    sendClientCommand(player, "ZM_Mungkinkah", "PlayWorldSound", {
        x = x,
        y = y,
        z = z,
        radius = 20,
        volume = 1.0,
        sound = isPositive and "rganvilsuccess" or "rganvil"
    })

    -- Update weapon stats
    weapon:setMinDamage(minDamage)
    weapon:setMaxDamage(maxDamage)

    -- Rename weapon based on enchantment outcome
    local newLevel = self:renameEnchantedWeapon(weapon, username, isPositive)

    -- Store enchantment result for UI - now includes both damage types
    self.enchantResult = {
        isPositive = isPositive,
        damageRoll = damageRoll,
        damageChange = damageChange,
        damageCap = damageCap,
        enchantLevel = newLevel,
        newMinDamage = math.floor(minDamage * 10) / 10,
        newMaxDamage = math.floor(maxDamage * 10) / 10,
        origMinDamage = math.floor(origMinDamage * 10) / 10,
        origMaxDamage = math.floor(origMaxDamage * 10) / 10
    }

    -- Update status text showing changes to both damage types
    if isPositive then
        self.statusText = "Success! Damage increased by (Cap: " .. damageCap .. ")"
        self.statusColor = {r=0.3, g=1, b=0.3}
    else
        self.statusText = "Caution! Damage decreased by (Cap: " .. damageCap .. ")"
        self.statusColor = {r=1, g=0.5, b=0.2}
    end

    -- Sync changes to the server
    sendClientCommand("EnchantWeapon", "syncEnchantment", {
        weaponID = weapon:getID(),
        isPositive = isPositive,
        damageRoll = damageRoll,
        damageChange = damageChange,
        damageCap = damageCap,
        enchantLevel = newLevel,
        minDamage = minDamage,
        maxDamage = maxDamage
    })

    print("DEBUG: Enchantment applied and synced to server")
end

-------------------------------------------- ON CLICK FUNCTION --------------------------------------------

function clearEnchantedWeaponIds()
  local player = getSpecificPlayer(0)
  if not player then return end

  -- send client command to server to clear enchanted weapon IDs
  sendClientCommand(player, "EnchantWeapon", "clearEnchantedWeaponIds", {
      playerID = player:getOnlineID()
  })
  print("DEBUG: Enchanted weapon IDs cleared on server")
end

local function ZM_EnchantWeaponServerResponse(module, command, args)
  -- Debug output with unique identifier

  if module == "EnchantWeapon" and command == "enchantResult" then
      print("[ZM_EnchantWeapon] Processing enchant result")

      -- Get the weapon ID and enchantment details
      local weaponID = args.weaponID
      local damageType = args.damageType
      local isPositive = args.isPositive
      local damageRoll = args.damageRoll
      local newDamage = args.newDamage
      local currentDamage = args.currentDamage

      print("[ZM_EnchantWeapon] Enchant details - Type: " .. damageType .. ", Roll: " .. damageRoll .. ", Positive: " .. tostring(isPositive))

      -- Try to use the global UI reference
      if _G.ZM_EnchantingUI then
          print("[ZM_EnchantWeapon] Found UI through global reference")
          if _G.ZM_EnchantingUI:isVisible() then
              print("[ZM_EnchantWeapon] UI is visible, updating")
              _G.ZM_EnchantingUI:updateEnchantResult(weaponID, damageType, isPositive, damageRoll, newDamage, currentDamage)
              return
          else
              print("[ZM_EnchantWeapon] UI exists but is not visible")
          end
      else
          print("[ZM_EnchantWeapon] Global UI reference not found")
      end

      -- Rest of your command handling...
  end
end

-- Add this function to handle server sync acknowledgements
local function handleSyncAcknowledgement(module, command, args)
    if module == "EnchantWeapon" and command == "syncAcknowledged" then
        local player = getSpecificPlayer(0)
        if not player then return end

        local inventory = player:getInventory()
        local weapon = inventory:getItemById(args.weaponID)
        if not weapon then
            weapon = player:getPrimaryHandItem()
            if not weapon or weapon:getID() ~= args.weaponID then return end
        end

        -- If server reports success, update saved values
        if args.success then
            print("[ZM_Mungkinkah] Server accepted enchantment changes")
            -- Make sure we save the server's values
            if not weapon:getModData().savedDamageValues then
                weapon:getModData().savedDamageValues = {}
            end
            weapon:getModData().savedDamageValues.minDamage = args.minDamage
            weapon:getModData().savedDamageValues.maxDamage = args.maxDamage
            return
        end

        -- Otherwise, revert to server values
        print("[ZM_Mungkah] Server rejected changes, reverting to server values")
        -- weapon:setMinDamage(args.minDamage)
        -- weapon:setMaxDamage(args.maxDamage)

        -- Update saved values to match server
        if not weapon:getModData().savedDamageValues then
            weapon:getModData().savedDamageValues = {}
        end
        weapon:getModData().savedDamageValues.minDamage = args.minDamage
        weapon:getModData().savedDamageValues.maxDamage = args.maxDamage

        -- If we have UI open, update it
        if _G.ZM_EnchantingUI and _G.ZM_EnchantingUI:isVisible() then
            _G.ZM_EnchantingUI.statusText = "Enchantment failed! Server rejected changes."
            _G.ZM_EnchantingUI.statusColor = {r=1, g=0.3, b=0.3}
        end
    end
end

-- Register this handler for server responses
Events.OnServerCommand.Add(handleSyncAcknowledgement)

-- IMPORTANT: Make sure we properly remove any existing handler and add our new one
Events.OnServerCommand.Remove(ZM_EnchantWeaponServerResponse)
Events.OnServerCommand.Add(ZM_EnchantWeaponServerResponse)
print("[ZM_EnchantWeapon] Registered unique server command handler")

-- Update UI with enchantment result
function ISEnchantWeaponUI:updateEnchantResult(weaponID, damageType, isPositive, damageRoll, newDamage, currentDamage)
  print("DEBUG: updateEnchantResult called")

  -- Find the weapon in inventory
  local player = getSpecificPlayer(0)
  if not player then
      print("DEBUG: Error - Player is nil")
      return
  end

  local inventory = player:getInventory()
  local weapon = inventory:getItemById(weaponID)

  if not weapon then
      print("DEBUG: Error - Weapon not found")
      return
  end

  print("DEBUG: Found weapon: " .. weapon:getName())

  -- Store the result for display
  self.enchantResult = {
      damageType = damageType,
      isPositive = isPositive,
      damageRoll = damageRoll,
      newDamage = math.floor(newDamage * 10) / 10, -- Round to 1 decimal
      currentDamage = math.floor(currentDamage * 10) / 10 -- Round to 1 decimal
  }

  -- Update status text - Fix ternary syntax
  local damageTypeText = damageType == "minDamage" and "minimum" or "maximum"
  if isPositive then
      self.statusText = "Success! " .. damageTypeText .. " damage increased by " .. (damageRoll / 20)
      self.statusColor = {r=0.3, g=1, b=0.3}
  else
      self.statusText = "Caution! " .. damageTypeText .. " damage decreased by " .. (damageRoll / 20)
      self.statusColor = {r=1, g=0.5, b=0.2}
  end

  print("DEBUG: Status updated: " .. self.statusText)

  -- Update the weapon display if needed
  if damageType == "minDamage" then
      weapon:setMinDamage(newDamage)
  else
      weapon:setMaxDamage(newDamage)
  end

  print("DEBUG: Weapon updated successfully")
end

-- Draw UI with enhanced weapon status info
function ISEnchantWeaponUI:prerender()
    local hasProtection = PlayerFlagHandler.getFlag("enchantProtection") or false
    -- Draw background
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    -- Draw title
    local title = "MangEwok's Enchanting Service"
    self:drawText(title, self.width/2 - getTextManager():MeasureStringX(UIFont.Medium, title)/2, 10, 1, 1, 1, 1, UIFont.Medium)

    -- Adjusted weapon info panel position
    self:drawRectBorder(20, 40, self.width - 40, 110, 0.5, 0.4, 0.4, 0.4)
    self:drawRect(21, 41, self.width - 42, 108, 0.3, 0.05, 0.05, 0.05)

    -- Draw weapon info
    local player = getSpecificPlayer(0)
    if player then
        local weapon = player:getPrimaryHandItem()
        if weapon and weapon:IsWeapon() then
            local name = weapon:getName() or "Unknown Weapon"

            -- Adjusted weapon info positions
            local weaponInfoY = 50
            self:drawText(name, self.width/2 - getTextManager():MeasureStringX(UIFont.Medium, name)/2, weaponInfoY, 1, 0.9, 0.7, 1, UIFont.Medium)

            -- Get weapon stats
            local minDmg = weapon:getMinDamage() or 0
            local maxDmg = weapon:getMaxDamage() or 0
            local condition = weapon:getCondition() or 0
            local maxCondition = weapon:getConditionMax() or 100
            local conditionPercent = math.floor((condition / maxCondition) * 100)
            local weaponType = weapon:getType() or "Unknown Type"

            -- Format damage values to one decimal place
            minDmg = math.floor(minDmg * 10) / 10
            maxDmg = math.floor(maxDmg * 10) / 10

            -- Left column stats
            -- Highlight min damage if it was changed in the last enchantment
            local minDmgColor = {r=0.9, g=0.9, b=0.9}
            if self.enchantResult and self.enchantResult.damageType == "minDamage" then
                if self.enchantResult.isPositive then
                    minDmgColor = {r=0.3, g=1, b=0.3} -- Green for positive
                else
                    minDmgColor = {r=1, g=0.3, b=0.3} -- Red for negative
                end
            end
            weaponInfoY = weaponInfoY + FONT_HGT_SMALL + 10
            self:drawText("Min Damage: " .. minDmg, 30, weaponInfoY, minDmgColor.r, minDmgColor.g, minDmgColor.b, 1, UIFont.Small)

            -- Highlight max damage if it was changed in the last enchantment
            local maxDmgColor = {r=0.9, g=0.9, b=0.9}
            if self.enchantResult and self.enchantResult.damageType == "maxDamage" then
                if self.enchantResult.isPositive then
                    maxDmgColor = {r=0.3, g=1, b=0.3} -- Green for positive
                else
                    maxDmgColor = {r=1, g=0.3, b=0.3} -- Red for negative
                end
            end
            weaponInfoY = weaponInfoY + FONT_HGT_SMALL + 2
            self:drawText("Max Damage: " .. maxDmg, 30, weaponInfoY, maxDmgColor.r, maxDmgColor.g, maxDmgColor.b, 1, UIFont.Small)

            weaponInfoY = weaponInfoY + FONT_HGT_SMALL + 2
            self:drawText("Type: " .. weaponType, 30, weaponInfoY, 0.9, 0.9, 0.9, 1, UIFont.Small)

            -- Right column stats
            -- Adjusted condition and enchantment status positions
            local rightColumnY = 50
            -- Draw condition with color based on percentage
            local r, g, b = 1, 0, 0 -- Red for bad condition
            if conditionPercent > 75 then
                r, g, b = 0, 1, 0 -- Green for good condition
            elseif conditionPercent > 40 then
                r, g, b = 1, 1, 0 -- Yellow for medium condition
            end

            -- Right-aligned condition text with proper margin
            local conditionText = "Condition: " .. conditionPercent .. "%"
            local conditionTextWidth = getTextManager():MeasureStringX(UIFont.Small, conditionText)
            self:drawText(conditionText, self.width - conditionTextWidth - 30, rightColumnY, r, g, b, 1, UIFont.Small)

            rightColumnY = rightColumnY + FONT_HGT_SMALL + 2

            -- Right-aligned enchantment status with proper margin
            if enchanted then
                local enchantText = enchanted and "✦ FULLY ENCHANTED ✦" or "✦ PARTIALLY ENCHANTED ✦"
                local enchantTextWidth = getTextManager():MeasureStringX(UIFont.Small, enchantText)
                self:drawText(enchantText, self.width - enchantTextWidth - 30, rightColumnY, 0.5, 0.7, 1, 1, UIFont.Small)
            else
                local notEnchantedText = "Not Enchanted"
                local notEnchantedWidth = getTextManager():MeasureStringX(UIFont.Small, notEnchantedText)
                self:drawText(notEnchantedText, self.width - notEnchantedWidth - 30, rightColumnY, 0.6, 0.6, 0.6, 1, UIFont.Small)
            end

        else
            self:drawText("No weapon equipped", self.width/2 - getTextManager():MeasureStringX(UIFont.Medium, "No weapon equipped")/2, 70, 0.7, 0.7, 0.7, 1, UIFont.Medium)
            self:drawText("Equip a weapon in your main hand", self.width/2 - getTextManager():MeasureStringX(UIFont.Small, "Equip a melee weapon in your main hand")/2, 90, 0.6, 0.6, 0.6, 1, UIFont.Small)
        end
    end

    -- Adjusted enchantment info position
    local enchantInfoY = 180
    self:drawText("Enchant your weapon - roll the dice!",
                self.width/2 - getTextManager():MeasureStringX(UIFont.Small, "Enchant your weapon - roll the dice!")/2,
                enchantInfoY, 0.8, 0.8, 1, 1, UIFont.Small)

    -- Adjusted status text position
    local statusTextY = enchantInfoY + 30
    self:drawText(self.statusText,
                self.width/2 - getTextManager():MeasureStringX(UIFont.Medium, self.statusText)/2,
                statusTextY,
                self.statusColor.r, self.statusColor.g, self.statusColor.b,
                1, UIFont.Medium)

    -- Adjusted chance info position
    local chanceInfoY = statusTextY + 30
    self:drawText("50% Min/Max Damage - 50% Chance of Improvement",
                self.width/2 - getTextManager():MeasureStringX(UIFont.Small, "50% Min/Max Damage - 50% Chance of Improvement")/2,
                chanceInfoY,
                0.7, 0.7, 0.7,
                1, UIFont.Small)

    -- Adjusted price info position
    local priceInfoY = chanceInfoY + 20
    self:drawText("Price: 2500 points per enchant",
                self.width/2 - getTextManager():MeasureStringX(UIFont.Small, "Price: 2500 points per enchant")/2,
                priceInfoY,
                0.8, 0.8, 0.8,
                1, UIFont.Small)

    -- Adjusted enchantment result position
-- In the prerender function, update this section:
    if self.enchantResult then
      local resultY = priceInfoY + 50
      local changeText = self.enchantResult.isPositive and "increased" or "decreased"
      local changeAmount = math.floor(self.enchantResult.damageChange * 100) / 100

      local resultText = "Last roll: Both damages " .. changeText .. " by " .. changeAmount
      self:drawText(resultText,
                  self.width/2 - getTextManager():MeasureStringX(UIFont.Small, resultText)/2,
                  resultY,
                  self.enchantResult.isPositive and 0.3 or 1,
                  self.enchantResult.isPositive and 1 or 0.5,
                  self.enchantResult.isPositive and 0.3 or 0.2,
                  1, UIFont.Small)
    end
end

-- Updated close function to handle UI instance tracking
function ISEnchantWeaponUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    _G.ZM_EnchantingUI = nil
end

function ISEnchantWeaponUI:new(x, y, width, height)
    local o = {}
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.width = width
    o.height = height
    o.moveWithMouse = true
    return o
end


_G.ZM_EnchantingUI = _G.ZM_EnchantingUI or nil


function showEnchantWeaponUI()
    if _G.ZM_EnchantingUI and _G.ZM_EnchantingUI:isVisible() then
        return _G.ZM_EnchantingUI
    end

    local ui = ISEnchantWeaponUI:new(
        (getCore():getScreenWidth() / 2) - 250,
        (getCore():getScreenHeight() / 2) - 150,
        500,
        370
    )

    ui:initialise()
    ui:addToUIManager()
    _G.ZM_EnchantingUI = ui

    return ui
end

if not _G.ZM_Commands then _G.ZM_Commands = {} end
_G.ZM_Commands.ShowEnchantUI = showEnchantWeaponUI

function DebugApplyEnchantment(minDmg, maxDmg, enchantLevel, username)
  local player = getSpecificPlayer(0)
  if not player then return "ERROR: No player found" end

  local weapon = player:getPrimaryHandItem()
  if not weapon or not weapon:IsWeapon() then
      return "ERROR: No weapon equipped"
  end

  -- Store original values for reporting
  local originalName = weapon:getName()
  local originalMin = weapon:getMinDamage()
  local originalMax = weapon:getMaxDamage()
  local originalLevel = weapon:getModData().enchantmentStats
                        and weapon:getModData().enchantmentStats.enchantCounter or 0

  -- Validate parameters
  minDmg = minDmg or weapon:getMinDamage()
  maxDmg = maxDmg or weapon:getMaxDamage()
  enchantLevel = enchantLevel or 0
  if enchantLevel > 10 then enchantLevel = 10 end
  if enchantLevel < -10 then enchantLevel = -10 end
  username = username or player:getUsername() or "debug"

  -- Initialize result log
  local result = "[DEBUG] Enchanting weapon: " .. originalName .. "\n"

  -- First set to different values to force update
  weapon:setMinDamage(originalMin + 1)
  weapon:setMaxDamage(originalMax + 1)

  -- Then set to desired values
  weapon:setMinDamage(minDmg)
  weapon:setMaxDamage(maxDmg)

  -- Initialize ModData if needed
  if not weapon:getModData().enchantmentStats then
      weapon:getModData().enchantmentStats = {
          enchantCounter = 0,
          originalName = weapon:getName():gsub("_.*_[+-]%d+$", "")
      }
  end

  -- Set enchantment level
  weapon:getModData().enchantmentStats.enchantCounter = enchantLevel

  -- Set enchantment flags
  if not weapon:getModData().enchantments then
      weapon:getModData().enchantments = {}
  end
  weapon:getModData().enchantments["minDamage"] = enchantLevel >= 0
  weapon:getModData().enchantments["maxDamage"] = enchantLevel >= 0
  weapon:getModData().enchanted = true

  -- Save values for persistence
  if not weapon:getModData().savedDamageValues then
      weapon:getModData().savedDamageValues = {}
  end
  weapon:getModData().savedDamageValues.minDamage = minDmg
  weapon:getModData().savedDamageValues.maxDamage = maxDmg

  -- Rename the weapon
  local baseName = weapon:getModData().enchantmentStats.originalName
  local prefix = enchantLevel >= 0 and "+" or "-"
  local absLevel = math.abs(enchantLevel)

  if enchantLevel ~= 0 then
      weapon:setName(baseName .. "_" .. username .. "_" .. prefix .. absLevel)
  else
      weapon:setName(baseName)
  end

  -- Force re-equipping to update the weapon
  local tempWeapon = weapon
  player:setPrimaryHandItem(nil)
  player:setPrimaryHandItem(tempWeapon)

  -- Append results
  result = result .. "Changes applied:\n"
  result = result .. "  Name: " .. originalName .. " -> " .. weapon:getName() .. "\n"
  result = result .. "  Min damage: " .. originalMin .. " -> " .. weapon:getMinDamage() .. "\n"
  result = result .. "  Max damage: " .. originalMax .. " -> " .. weapon:getMaxDamage() .. "\n"
  result = result .. "  Enchant level: " .. originalLevel .. " -> " .. enchantLevel

  -- Sync changes to the server
  sendClientCommand("EnchantWeapon", "syncEnchantment", {
      weaponID = weapon:getID(),
      isPositive = enchantLevel >= originalLevel,
      damageRoll = 10, -- Default roll
      damageChange = math.max(minDmg - originalMin, maxDmg - originalMax),
      damageCap = 0.8,
      enchantLevel = enchantLevel,
      minDamage = minDmg,
      maxDamage = maxDmg
  })

  print(result)
  return "Weapon enchantment applied and synced to server"
end

_G.DebugApplyEnchantment = DebugApplyEnchantment

function DebugReplaceWeapon(minDmg, maxDmg, enchantLevel, username)
  local player = getSpecificPlayer(0)
  if not player then return "ERROR: No player found" end

  local weapon = player:getPrimaryHandItem()
  if not weapon or not weapon:IsWeapon() then
      return "ERROR: No weapon equipped"
  end

  -- Store original info
  local weaponType = weapon:getFullType()
  local weaponName = weapon:getName()
  local weaponCondition = weapon:getCondition()
  local isEquipped = (player:getPrimaryHandItem() == weapon)
  local weaponModData = weapon:getModData()

  -- Create a completely new weapon
  local inventory = player:getInventory()
  local newWeapon = inventory:AddItem(weaponType)

  -- Copy basic properties
  newWeapon:setCondition(weaponCondition)
  newWeapon:setMinDamage(minDmg)
  newWeapon:setMaxDamage(maxDmg)

  -- Copy mod data
  for k, v in pairs(weaponModData) do
      newWeapon:getModData()[k] = v
  end

  -- Set enchantment data
  if not newWeapon:getModData().enchantmentStats then
      newWeapon:getModData().enchantmentStats = {}
  end
  newWeapon:getModData().enchantmentStats.enchantCounter = enchantLevel
  newWeapon:getModData().enchantmentStats.originalName =
      weaponModData.enchantmentStats and weaponModData.enchantmentStats.originalName
      or weaponName:gsub("_.*_[+-]%d+$", "")

  -- Set enchantment flags
  if not newWeapon:getModData().enchantments then
      newWeapon:getModData().enchantments = {}
  end
  newWeapon:getModData().enchantments["minDamage"] = enchantLevel >= 0
  newWeapon:getModData().enchantments["maxDamage"] = enchantLevel >= 0
  newWeapon:getModData().enchanted = true

  newWeapon:getModData().savedDamageValues = {
      minDamage = minDmg,
      maxDamage = maxDmg
  }

  username = username or player:getUsername() or "debug"
  local baseName = newWeapon:getModData().enchantmentStats.originalName
  local prefix = enchantLevel >= 0 and "+" or "-"
  local absLevel = math.abs(enchantLevel)

  if enchantLevel ~= 0 then
      newWeapon:setName(baseName .. "_" .. username .. "_" .. prefix .. absLevel)
  else
      newWeapon:setName(baseName)
  end

  inventory:Remove(weapon)

  if isEquipped then
      player:setPrimaryHandItem(newWeapon)
  end

  sendClientCommand("EnchantWeapon", "syncEnchantment", {
      weaponID = newWeapon:getID(),
      isPositive = enchantLevel >= 0,
      damageRoll = 10,
      damageChange = 0.5,
      damageCap = 0.8,
      enchantLevel = enchantLevel,
      minDamage = minDmg,
      maxDamage = maxDmg
  })

  return "Weapon replaced with enchanted version. Min: " .. minDmg ..
         ", Max: " .. maxDmg .. ", Level: " .. enchantLevel
end

_G.DebugReplaceWeapon = DebugReplaceWeapon


_G.OpenEnchantUI = showEnchantWeaponUI

function DebugSetWeaponConditionToZero()
  local player = getSpecificPlayer(0)
  if not player then return "ERROR: No player found" end

  local weapon = player:getPrimaryHandItem()
  if not weapon or not weapon:IsWeapon() then
      return "ERROR: No weapon equipped"
  end

  -- Store original condition for reporting
  local originalCondition = weapon:getCondition()

  -- Set condition to 0
  weapon:setCondition(0)

  -- Force re-equipping to update the weapon
  local tempWeapon = weapon
  player:setPrimaryHandItem(nil)
  player:setPrimaryHandItem(tempWeapon)
  player:Say("Awh shit! I should have been more careful")
  -- Create result message
  local result = "Weapon condition changed from " .. originalCondition .. " to 0"

  print(result)
  return result
end

function requestWeaponEnchantmentDataFromServer(weapon)
  if not weapon or not weapon:IsWeapon() then return false end

  local player = getSpecificPlayer(0)
  if not player then return false end

  -- Send request to server
  sendClientCommand("EnchantWeapon", "loadEnchantmentData", {
      weaponID = weapon:getID(),
      weaponType = weapon:getFullType()
  })

  print("[ZM_EnchantWeapon] Requested enchantment data from server for weapon: " .. weapon:getName())
  return true
end

function saveWeaponEnchantmentDataToServer(weapon)
    if not weapon or not weapon:IsWeapon() then return false end

    local player = getSpecificPlayer(0)
    if not player then return false end

    -- Prepare the data to send
    local enchantLevel = 0
    local originalName = weapon:getName()

    -- Use existing ModData if available (for transition)
    if weapon:getModData().enchantmentStats then
        enchantLevel = weapon:getModData().enchantmentStats.enchantCounter or 0
        originalName = weapon:getModData().enchantmentStats.originalName or originalName
    end

    -- Send data to server
    sendClientCommand("EnchantWeapon", "saveEnchantmentData", {
        weaponID = weapon:getID(),
        weaponType = weapon:getFullType(),
        minDamage = weapon:getMinDamage(),
        maxDamage = weapon:getMaxDamage(),
        enchantLevel = enchantLevel,
        isPositive = enchantLevel >= 0,
        originalName = originalName:gsub("_.*_[+-]%d+$", "")
    })

    print("[ZM_EnchantWeapon] Sent enchantment data to server for weapon: " .. weapon:getName())
    return true
end

local function ZM_SoundServerResponse(module, command, args)

  if module ~= "ZM_Mungkah" then return end

  if command == "PlayWorldSound" then

      local sound = args.sound
      local volume = args.volume or 1.0
      local distance = args.distance or 0
      local radius = args.radius or 20

      -- Calculate volume based on distance if sent from server
      if distance > 0 then
          volume = volume * math.max(0.2, 1.0 - (distance / radius))
      end

      -- Get player instance
      local player = getSpecificPlayer(0)
      if not player then return end

      -- Play sound as music (similar to airdrop mod)
      -- getSoundManager():PlayAsMusic(sound, sound, false, volume)

      -- print("[ZM_Mungkah] Playing sound: " .. sound .. " at volume: " .. volume)
  end
end

local function onEquipPrimary(player, item)
  if not item or not item:IsWeapon() then return end

  local weaponName = item:getName() or ""
  if string.find(weaponName, "+10") then
      -- If the weapon name contains "+10", set condition to 100
      item:setCondition(100)
      print("[ZM_Mungkah] Restored condition to 100 for +10 weapon: " .. item:getName())
  end
  -- Check if this weapon has enchantment data
  if item:getModData() and item:getModData().enchantmentStats then
      -- Get the stored damage values from ModData if they exist
      if not item:getModData().savedDamageValues then return end

      local savedMinDamage = item:getModData().savedDamageValues.minDamage
      local savedMaxDamage = item:getModData().savedDamageValues.maxDamage

      -- Reapply the enchanted damage values
      if savedMinDamage and savedMaxDamage then
          item:setMinDamage(savedMinDamage)
          item:setMaxDamage(savedMaxDamage)
          print("[ZM_Mungkah] Restored enchanted damage values for: " .. item:getName())
      end
  end
end

local function handleServerEnchantmentResponse(module, command, args)
  if module ~= "EnchantWeapon" then return end

  -- Handle load result from server
  if command == "loadEnchantmentResult" then
      local player = getSpecificPlayer(0)
      if not player then return end

      local weaponID = args.weaponID

      -- Find the weapon
      local weapon = nil
      local inventory = player:getInventory()
      weapon = inventory:getItemById(weaponID)

      if not weapon and player:getPrimaryHandItem() and player:getPrimaryHandItem():getID() == weaponID then
          weapon = player:getPrimaryHandItem()
      end

      if not weapon then
          print("[ZM_EnchantWeapon] ERROR: Weapon not found for server data")
          return
      end

      -- Apply the data if we got a successful response
      if args.success and args.enchantmentData then
          print("[ZM_EnchantWeapon] Applying server enchantment data to: " .. weapon:getName())

          -- Apply stats directly to weapon
          weapon:setMinDamage(args.enchantmentData.minDamage)
          weapon:setMaxDamage(args.enchantmentData.maxDamage)

          -- Update weapon name
          local originalName = args.enchantmentData.originalName
          local enchantLevel = args.enchantmentData.enchantLevel
          local username = player:getUsername()

          if enchantLevel ~= 0 then
              local prefix = enchantLevel > 0 and "+" or "-"
              weapon:setName(originalName .. "_" .. username .. "_" .. prefix .. math.abs(enchantLevel))
          else
              weapon:setName(originalName)
          end

          -- Force refresh if this is the equipped weapon
          if player:getPrimaryHandItem() == weapon then
              local tempWeapon = weapon
              player:setPrimaryHandItem(nil)
              player:setPrimaryHandItem(tempWeapon)
          end

          print("[ZM_EnchantWeapon] Server enchantment data applied successfully")
      else
          print("[ZM_EnchantWeapon] No server data found for this weapon")
      end
  end
end
Events.OnServerCommand.Add(handleServerEnchantmentResponse)


local originalRenameFunction = ISEnchantWeaponUI.renameEnchantedWeapon
ISEnchantWeaponUI.renameEnchantedWeapon = function(self, weapon, username, isPositive)
  local counter = originalRenameFunction(self, weapon, username, isPositive)

  if not weapon:getModData().savedDamageValues then
      weapon:getModData().savedDamageValues = {}
  end

  weapon:getModData().savedDamageValues.minDamage = weapon:getMinDamage()
  weapon:getModData().savedDamageValues.maxDamage = weapon:getMaxDamage()

  print("[ZM_Mungkah] Saved enchanted damage values: Min=" ..
        weapon:getMinDamage() .. ", Max=" .. weapon:getMaxDamage())

  return counter
end

Events.OnEquipPrimary.Add(onEquipPrimary)
Events.OnGameStart.Add(function()
  local player = getSpecificPlayer(0)
  if player then
      local primaryItem = player:getPrimaryHandItem()
      if primaryItem then
          onEquipPrimary(player, primaryItem)
      end
  end
end)

Events.OnServerCommand.Remove(ZM_SoundServerResponse)
Events.OnServerCommand.Add(ZM_SoundServerResponse)
print("[ZM_Mungkah] Registered sound server command handler")

_G.OpenEnchantUI = showEnchantWeaponUI