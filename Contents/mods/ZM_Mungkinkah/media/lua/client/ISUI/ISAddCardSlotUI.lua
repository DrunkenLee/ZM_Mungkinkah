require "ISUI/ISPanel"
require "globalmethods" -- Require the ServerPointx mod's GlobalMethods

ISAddCardSlotUI = ISPanel:derive("ISAddCardSlotUI")

function ISAddCardSlotUI:initialise()
    ISPanel.initialise(self)

    -- Create title (centered properly)
    local titleText = "Weapon Card Slot System"
    self.titleLabel = ISLabel:new(self.width/2 - getTextManager():MeasureStringX(UIFont.Medium, titleText)/2, 10, 30, titleText, 1, 1, 1, 1, UIFont.Medium, true)
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)

    -- Create weapon info panel (slightly taller)
    self.weaponPanel = ISPanel:new(20, 40, self.width - 40, 90)
    self.weaponPanel:initialise()
    self.weaponPanel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8}
    self.weaponPanel.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    self:addChild(self.weaponPanel)

    -- Weapon name (with more space)
    self.weaponName = ISLabel:new(10, 10, self.weaponPanel.width - 20, "Select a weapon", 1, 1, 1, 1, UIFont.Small)
    self.weaponName:initialise()
    self.weaponPanel:addChild(self.weaponName)

    -- Weapon slots (positioned lower)
    self.slotsLabel = ISLabel:new(10, 35, 100, "Slots: 0", 1, 1, 1, 1, UIFont.Small)
    self.slotsLabel:initialise()
    self.weaponPanel:addChild(self.slotsLabel)

    -- Current points display (right aligned properly)
    self.pointsLabel = ISLabel:new(self.weaponPanel.width - 110, 35, 100, "Points: 0", 1, 1, 1, 1, UIFont.Small)
    self.pointsLabel:initialise()
    self.weaponPanel:addChild(self.pointsLabel)

    -- Vertical positioning with more spacing
    local infoY = self.weaponPanel:getY() + self.weaponPanel:getHeight() + 20

    -- Cost and chance info (properly sized and positioned)
    self.costLabel = ISLabel:new(20, infoY, self.width - 40, "Cost: 1000 points per attempt", 1, 1, 1, 1, UIFont.Small)
    self.costLabel:initialise()
    self:addChild(self.costLabel)

    self.chanceLabel = ISLabel:new(20, infoY + 20, self.width - 40, "Success Chance: 1%", 1, 1, 1, 1, UIFont.Small)
    self.chanceLabel:initialise()
    self:addChild(self.chanceLabel)

    -- Status text
    self.statusText = "Select a weapon to add a card slot"
    self.statusColor = {r=1, g=1, b=1}

    -- Add slot button (positioned based on height)
    local buttonY = infoY + 60
    self.addSlotButton = ISButton:new(self.width/2 - 75, buttonY, 150, 25, "Add Slot", self, ISAddCardSlotUI.onAddSlot)
    self.addSlotButton:initialise()
    self.addSlotButton.backgroundColor = {r=0.2, g=0.2, b=0.2, a=0.8}
    self.addSlotButton.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    self.addSlotButton.enable = false
    self:addChild(self.addSlotButton)

    -- Close button
    self.closeButton = ISButton:new(self.width - 30, 5, 20, 20, "X", self, ISAddCardSlotUI.close)
    self.closeButton:initialise()
    self.closeButton.backgroundColor = {r=0.5, g=0.1, b=0.1, a=0.8}
    self.closeButton.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    self:addChild(self.closeButton)

    self:refreshUI()
end

function ISAddCardSlotUI:prerender()
    ISPanel.prerender(self)

    -- Draw status text with proper positioning
    local statusY = self.addSlotButton:getY() + self.addSlotButton:getHeight() + 15
    self:drawText(self.statusText,
                 self.width/2 - getTextManager():MeasureStringX(UIFont.Medium, self.statusText)/2,
                 statusY,
                 self.statusColor.r, self.statusColor.g, self.statusColor.b,
                 1, UIFont.Medium)
end

function ISAddCardSlotUI:refreshUI()
    -- Get player's equipped weapon
    local player = getSpecificPlayer(0)
    if not player then return end

    local weapon = player:getPrimaryHandItem()
    if weapon and weapon:IsWeapon() then
        self.weapon = weapon

        -- Truncate long weapon names
        local weaponName = weapon:getName()
        if string.len(weaponName) > 40 then
            weaponName = string.sub(weaponName, 1, 37) .. "..."
        end
        self.weaponName:setName(weaponName)

        -- Show slots
        local slots = ZM_CardSystem.getWeaponSlots(weapon)
        self.slotsLabel:setName("Slots: " .. slots)

        -- Show current points
        local points = self:getPlayerPoints()
        self.pointsLabel:setName("Points: " .. points)

        -- Enable/disable button only based on max slots
        if slots >= ZM_CardSystem.MAX_SLOTS then
            self.addSlotButton.enable = false
            self.statusText = "This weapon already has maximum slots"
            self.statusColor = {r=1, g=0.5, b=0.5}
        else
            self.addSlotButton.enable = true
            self.statusText = "Ready to add a slot (1% chance)"
            self.statusColor = {r=1, g=1, b=1}
        end
    else
        self.weapon = nil
        self.weaponName:setName("Equip a weapon")
        self.slotsLabel:setName("Slots: 0")
        self.addSlotButton.enable = false
        self.statusText = "Select a weapon to add a card slot"
        self.statusColor = {r=1, g=1, b=1}
    end
end

function ISAddCardSlotUI:getPlayerPoints()
    -- Use the GlobalMethods to get player points
    local player = getSpecificPlayer(0)
    if not player then return 0 end

    -- Get points from GlobalMethods
    return GlobalMethods.getPlayerPoints(player:getUsername()) or 0
end

function ISAddCardSlotUI:onAddSlot()
    if not self.weapon then return end

    local player = getSpecificPlayer(0)
    if not player then return end

    -- Check if player has enough points ONLY when they try to add a slot
    local points = self:getPlayerPoints()
    if points < 1000 then
        self.statusText = "Not enough points (1000 required)"
        self.statusColor = {r=1, g=0.5, b=0.5}
        return
    end

    -- Deduct points using GlobalMethods
    GlobalMethods.takePlayerPoints(player:getUsername(), 1000)

    -- Send request to server
    sendClientCommand(player, "CardSystem", "addSlot", {
        weaponID = self.weapon:getID()
    })

    -- Show processing status
    self.statusText = "Processing request..."
    self.statusColor = {r=0.8, g=0.8, b=0.8}
    self.addSlotButton.enable = false

    -- Play sound effect
    getSoundManager():PlayWorldSound("rganvil", player:getSquare(), 0, 10, 1, false)
end

function ISAddCardSlotUI:onSlotResult(success)
  -- Get player properly
  local player = getSpecificPlayer(0)

  if success then
      self.statusText = "Success! Added a card slot"
      self.statusColor = {r=0.2, g=1, b=0.2}

      -- Play success sound
      if player then
          getSoundManager():PlayWorldSound("lightswitch", player:getSquare(), 0, 10, 1, false)
      end
  else
      self.statusText = "Failed to add a card slot (try again?)"
      self.statusColor = {r=1, g=0.5, b=0.5}

      -- Play failure sound
      if player then
          getSoundManager():PlayWorldSound("PZ_Cloth_Rip", player:getSquare(), 0, 10, 1, false)
      end
  end

  -- Re-enable the button
  self.addSlotButton.enable = true

  -- Refresh the UI
  self:refreshUI()
end

function ISAddCardSlotUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    _G.CardSlotUI = nil
end

function ISAddCardSlotUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.variableColor={r=0.9, g=0.9, b=0.9, a=1}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.width = width
    o.height = height
    o.moveWithMouse = true
    o.weapon = nil
    o.statusText = "Select a weapon to add a card slot"
    o.statusColor = {r=1, g=1, b=1}
    return o
end

-- Handle server response
local function onServerCommand(module, command, args)
    print("[ZM_CardSystem Client] Received server command: " .. module .. "/" .. command)

    if module ~= "CardSystem" then return end

    if command == "slotResult" then
        print("[ZM_CardSystem Client] Got slot result: " .. tostring(args.success))

        if _G.CardSlotUI and _G.CardSlotUI:isVisible() then
            _G.CardSlotUI:onSlotResult(args.success)
        else
            print("[ZM_CardSystem Client] WARNING: UI not visible to receive result")
        end
    end
end

-- Make sure we're properly registering the handler
Events.OnServerCommand.Remove(onServerCommand)
Events.OnServerCommand.Add(onServerCommand)
print("[ZM_CardSystem Client] Registered server command handler")

-- Function to show UI with increased height
function showAddCardSlotUI()
    if _G.CardSlotUI and _G.CardSlotUI:isVisible() then
        return _G.CardSlotUI
    end

    -- 450px wide and increased height to 280px
    local ui = ISAddCardSlotUI:new(
        (getCore():getScreenWidth() / 2) - 225,
        (getCore():getScreenHeight() / 2) - 140,
        450,
        280
    )

    ui:initialise()
    ui:addToUIManager()
    _G.CardSlotUI = ui

    return ui
end

-- Register command
if not _G.ZM_Commands then _G.ZM_Commands = {} end
_G.ZM_Commands.ShowAddCardSlotUI = showAddCardSlotUI

