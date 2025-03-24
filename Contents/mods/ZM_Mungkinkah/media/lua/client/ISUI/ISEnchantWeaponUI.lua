--***********************************************************
--**            SIMPLE WEAPON ENCHANT UI                   **
--***********************************************************

ISEnchantWeaponUI = ISPanel:derive("ISEnchantWeaponUI")

-- Global variable to track UI instance
local EnchantingUI = nil

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function ISEnchantWeaponUI:initialise()
    ISPanel.initialise(self)
end

function ISEnchantWeaponUI:createChildren()
    ISPanel.createChildren(self)

    -- Button dimensions
    local btnWid = 120
    local btnHgt = FONT_HGT_MEDIUM + 6

    -- Enchant button
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

    -- Close button
    self.closeButton = ISButton:new(self.width - btnWid - 10, self.height - btnHgt - 10,
                                  btnWid, btnHgt, "Close", self, ISEnchantWeaponUI.onClick)
    self.closeButton.internal = "CLOSE"
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self.closeButton.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    self.closeButton.font = UIFont.Medium
    self:addChild(self.closeButton)

    -- Initialize enchant results display
    self.enchantResult = nil
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

function ISEnchantWeaponUI:onClick(button)
  if button.internal == "CLOSE" then
      self:close()
      return
  end

  -- Get current enchantment level
  local enchantLevel = 0
  if weapon:getModData().enchantmentStats then
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

  -- Deduct points
  if not GlobalMethods.takePlayerPoints(username, pointCost) then
      self.statusText = "Failed to deduct points. Try again."
      self.statusColor = {r=1, g=0.3, b=0.3}
      return
  end

  -- Perform enchantment logic on the client - now affecting both damage values
  local isPositive = ZombRand(2) == 0 -- 50% chance of positive outcome
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
      -- Negative outcome: decrease both damages
      minDamage = minDamage - damageChange
      -- Ensure minimum damage doesn't go negative
      if minDamage < 0 then minDamage = 0 end
      maxDamage = maxDamage - damageChange
      -- Ensure maximum damage doesn't go negative
      if maxDamage < 0 then maxDamage = 0 end
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

local function ZM_EnchantWeaponServerResponse(module, command, args)
  -- Debug output with unique identifier
  print("[ZM_EnchantWeapon] Received server command: " .. tostring(module) .. " / " .. tostring(command))

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
      local resultY = priceInfoY + 30
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

-- Changed from local variable to global namespace
_G.ZM_EnchantingUI = _G.ZM_EnchantingUI or nil

-- Updated function to display the UI - simplified approach
function showEnchantWeaponUI()
    -- Check if UI is already open using the global variable
    if _G.ZM_EnchantingUI and _G.ZM_EnchantingUI:isVisible() then
        return _G.ZM_EnchantingUI
    end

    -- Create the UI directly without pcall for simpler debugging
    local ui = ISEnchantWeaponUI:new(
        (getCore():getScreenWidth() / 2) - 250,
        (getCore():getScreenHeight() / 2) - 150,
        500,
        370
    )

    -- Initialize and show
    ui:initialise()
    ui:addToUIManager()
    _G.ZM_EnchantingUI = ui

    return ui
end

-- Register with a different namespace to avoid conflicts
-- Use ZM_Commands instead of the global Commands table
if not _G.ZM_Commands then _G.ZM_Commands = {} end
_G.ZM_Commands.ShowEnchantUI = showEnchantWeaponUI

-- Add a keypress handler as an alternative way to open UI
-- local function onKeyPressed(key)
--     -- Open UI when Shift+E is pressed
--     if key == Keyboard.KEY_E and isKeyDown(Keyboard.KEY_LSHIFT) then
--         showEnchantWeaponUI()
--     end
-- end

-- Register the key handler
Events.OnKeyPressed.Add(onKeyPressed)

-- Create a direct function to call from the console
_G.OpenEnchantUI = showEnchantWeaponUI

-- Add this to the end of your file, before the last line

-- Sound handler for multiplayer - receives sound commands broadcasted from server
local function ZM_SoundServerResponse(module, command, args)
  -- Only process our module's commands
  if module ~= "ZM_Mungkinkah" then return end

  if command == "PlayWorldSound" then
      print("[ZM_Mungkinkah] Received sound command: " .. tostring(args.sound))

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

      print("[ZM_Mungkinkah] Playing sound: " .. sound .. " at volume: " .. volume)
  end
end

-- Register the sound handler
Events.OnServerCommand.Remove(ZM_SoundServerResponse)
Events.OnServerCommand.Add(ZM_SoundServerResponse)
print("[ZM_Mungkinkah] Registered sound server command handler")

-- Keep this line at the end of your file
_G.OpenEnchantUI = showEnchantWeaponUI