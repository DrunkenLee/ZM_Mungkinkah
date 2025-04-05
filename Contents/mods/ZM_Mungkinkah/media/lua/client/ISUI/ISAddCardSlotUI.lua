require "ISUI/ISPanel"
require "ISUI/ISRichTextPanel"
require "globalmethods"

ISAddCardSlotUI = ISPanel:derive("ISAddCardSlotUI")

function ISAddCardSlotUI:initialise()
  ISPanel.initialise(self)

  -- Create header area
  self.header = ISPanel:new(0, 0, self.width, 40)
  self.header:initialise()
  self.header.backgroundColor = {r=0.2, g=0.2, b=0.3, a=1}
  self:addChild(self.header)

  -- Title
  local titleText = "Weapon Card Slot System"
  self.title = ISLabel:new(self.width / 2 - getTextManager():MeasureStringX(UIFont.Medium, titleText) / 2,
                           10, 30, titleText, 1, 1, 1, 1, UIFont.Medium, true)
  self.title:initialise()
  self.header:addChild(self.title)

  -- Close button
  self.closeButton = ISButton:new(self.width - 35, 7, 25, 25, "X", self, ISAddCardSlotUI.close)
  self.closeButton:initialise()
  self.closeButton.backgroundColor = {r=0.5, g=0.1, b=0.1, a=0.8}
  self.closeButton.borderColor = {r=0.7, g=0.3, b=0.3, a=1}
  self.header:addChild(self.closeButton)

  -- Main container with padding
  local padding = 20
  local contentY = self.header:getHeight() + 10
  local contentWidth = self.width - (padding * 2)
  local contentHeight = self.height - contentY - padding

  -- Weapon info section
  self.weaponPanel = ISPanel:new(padding, contentY, contentWidth, 120)
  self.weaponPanel:initialise()
  self.weaponPanel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.5}
  self.weaponPanel.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
  self:addChild(self.weaponPanel)

  -- Section title
  self.weaponPanelTitle = ISLabel:new(10, 5, contentWidth - 20, "WEAPON INFORMATION", 0.8, 0.8, 0.9, 1, UIFont.Small)
  self.weaponPanelTitle:initialise()
  self.weaponPanel:addChild(self.weaponPanelTitle)

  -- Weapon name
  self.weaponNameLabel = ISLabel:new(10, 25, 100, "Weapon:", 1, 1, 1, 1, UIFont.Small)
  self.weaponNameLabel:initialise()
  self.weaponPanel:addChild(self.weaponNameLabel)

  self.weaponNameText = ISLabel:new(110, 25, contentWidth - 120, "(none equipped)", 1, 0.9, 0.8, 1, UIFont.Small)
  self.weaponNameText:initialise()
  self.weaponPanel:addChild(self.weaponNameText)

  -- Weapon stats
  self.slotsLabel = ISLabel:new(10, 50, 100, "Card Slots:", 1, 1, 1, 1, UIFont.Small)
  self.slotsLabel:initialise()
  self.weaponPanel:addChild(self.slotsLabel)

  self.slotsValue = ISLabel:new(110, 50, 100, "0", 1, 0.8, 0.8, 1, UIFont.Small)
  self.slotsValue:initialise()
  self.weaponPanel:addChild(self.slotsValue)

  -- Player points
  self.pointsLabel = ISLabel:new(10, 75, 100, "Your Points:", 1, 1, 1, 1, UIFont.Small)
  self.pointsLabel:initialise()
  self.weaponPanel:addChild(self.pointsLabel)

  self.pointsValue = ISLabel:new(110, 75, 100, "0", 0.8, 1, 0.8, 1, UIFont.Small)
  self.pointsValue:initialise()
  self.weaponPanel:addChild(self.pointsValue)

  -- Cost and information section
  local infoY = self.weaponPanel:getY() + self.weaponPanel:getHeight() + 15
  self.infoPanel = ISRichTextPanel:new(padding, infoY, contentWidth, 100)
  self.infoPanel:initialise()
  self.infoPanel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.5}
  self.infoPanel.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
  self.infoPanel:setMargins(10, 10, 10, 10)
  self:addChild(self.infoPanel)

  -- Set info text
  self.infoPanel:setText("<CENTRE><SIZE:medium>Card Slot Information</SIZE></CENTRE>\n" ..
                         "<LINE><RGB:1,0.8,0.6>Cost: <RGB:1,1,1>1000 points per attempt\n" ..
                         "<RGB:1,0.8,0.6>Success Rate: <RGB:1,1,1>1% chance\n" ..
                         "<RGB:1,0.8,0.6>Maximum Slots: <RGB:1,1,1>" .. (ZM_CardSystem.MAX_SLOTS or 4))

  -- Status section
  local statusY = self.infoPanel:getY() + self.infoPanel:getHeight() + 15
  self.statusPanel = ISPanel:new(padding, statusY, contentWidth, 60)
  self.statusPanel:initialise()
  self.statusPanel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.5}
  self.statusPanel.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
  self:addChild(self.statusPanel)

  -- Status text (centered)
  self.statusText = "Select a weapon to add a card slot"
  self.statusColor = {r=1, g=1, b=1}
  self.statusLabel = ISLabel:new(0, 20, contentWidth, self.statusText,
                                 self.statusColor.r, self.statusColor.g, self.statusColor.b,
                                 1, UIFont.Medium, true)
  self.statusLabel:initialise()
  self.statusLabel:setX(contentWidth / 2 - self.statusLabel:getWidth() / 2)
  self.statusPanel:addChild(self.statusLabel)

  -- Action button
  local buttonY = self.statusPanel:getY() + self.statusPanel:getHeight() + 15
  self.addSlotButton = ISButton:new(padding + 50, buttonY, contentWidth - 100, 40, "ADD CARD SLOT", self, ISAddCardSlotUI.onAddSlot)
  self.addSlotButton:initialise()
  self.addSlotButton.backgroundColor = {r=0.2, g=0.3, b=0.4, a=0.8}
  self.addSlotButton.borderColor = {r=0.4, g=0.5, b=0.6, a=1}
  self.addSlotButton.enable = false
  self.addSlotButton:setFont(UIFont.Medium)
  self:addChild(self.addSlotButton)

  self:refreshUI()
end

function ISAddCardSlotUI:refreshUI()
    -- Get player's equipped weapon
    local player = getSpecificPlayer(0)
    if not player then return end

    local weapon = player:getPrimaryHandItem()
    if weapon and weapon:IsWeapon() then
        self.weapon = weapon

        -- Set weapon name (no truncation needed with this layout)
        self.weaponNameText:setName(weapon:getName())

        -- Color weapon name based on rarity/quality
        local condition = weapon:getCondition() / weapon:getConditionMax()
        if condition > 0.8 then
            self.weaponNameText:setColor(0.6, 1, 0.6) -- Green for good condition
        elseif condition > 0.4 then
            self.weaponNameText:setColor(1, 1, 0.6) -- Yellow for medium condition
        else
            self.weaponNameText:setColor(1, 0.7, 0.7) -- Red for poor condition
        end

        -- Show slots
        local slots = ZM_CardSystem.getWeaponSlots(weapon)
        self.slotsValue:setName(tostring(slots))

        -- Color slots based on max
        if slots >= ZM_CardSystem.MAX_SLOTS then
            self.slotsValue:setColor(1, 0.5, 0.5)
        elseif slots > 0 then
            self.slotsValue:setColor(0.5, 1, 0.5)
        else
            self.slotsValue:setColor(1, 1, 1)
        end

        -- Show current points
        local points = self:getPlayerPoints()
        self.pointsValue:setName(tostring(points))

        -- Color points based on if enough for slot
        if points >= 1000 then
            self.pointsValue:setColor(0.5, 1, 0.5)
        else
            self.pointsValue:setColor(1, 0.7, 0.7)
        end

        -- Enable/disable button only based on max slots
        if slots >= ZM_CardSystem.MAX_SLOTS then
            self.addSlotButton.enable = false
            self.statusText = "This weapon has reached maximum slots"
            self.statusColor = {r=1, g=0.5, b=0.5}
            self.addSlotButton.backgroundColor = {r=0.3, g=0.3, b=0.3, a=0.8}
        else
            self.addSlotButton.enable = true
            self.statusText = "Ready to add a slot (1% chance)"
            self.statusColor = {r=1, g=1, b=1}
            self.addSlotButton.backgroundColor = {r=0.2, g=0.3, b=0.4, a=0.8}
        end
    else
        self.weapon = nil
        self.weaponNameText:setName("(none equipped)")
        self.weaponNameText:setColor(0.7, 0.7, 0.7)
        self.slotsValue:setName("0")
        self.slotsValue:setColor(0.7, 0.7, 0.7)

        -- Still show points
        local points = self:getPlayerPoints()
        self.pointsValue:setName(tostring(points))
        if points >= 1000 then
            self.pointsValue:setColor(0.5, 1, 0.5)
        else
            self.pointsValue:setColor(1, 0.7, 0.7)
        end

        self.addSlotButton.enable = false
        self.statusText = "Equip a weapon first"
        self.statusColor = {r=1, g=0.8, b=0.5}
        self.addSlotButton.backgroundColor = {r=0.3, g=0.3, b=0.3, a=0.8}
    end

    -- Update status text
    self.statusLabel:setName(self.statusText)
    self.statusLabel:setColor(self.statusColor.r, self.statusColor.g, self.statusColor.b)
    self.statusLabel:setX(self.statusPanel:getWidth()/2 - self.statusLabel:getWidth()/2)
end

function ISAddCardSlotUI:getPlayerPoints()
    local player = getSpecificPlayer(0)
    if not player then return 0 end
    return GlobalMethods.getPlayerPoints(player:getUsername()) or 0
end

function ISAddCardSlotUI:onAddSlot()
    if not self.weapon then return end

    local player = getSpecificPlayer(0)
    if not player then return end

    -- Check if player has enough points
    local points = self:getPlayerPoints()
    if points < 1000 then
        self.statusText = "Not enough points (1000 required)"
        self.statusColor = {r=1, g=0.5, b=0.5}
        self.statusLabel:setName(self.statusText)
        self.statusLabel:setColor(self.statusColor.r, self.statusColor.g, self.statusColor.b)
        self.statusLabel:setX(self.statusPanel:getWidth()/2 - self.statusLabel:getWidth()/2)
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
    self.statusColor = {r=0.8, g=0.8, b=1}
    self.statusLabel:setName(self.statusText)
    self.statusLabel:setColor(self.statusColor.r, self.statusColor.g, self.statusColor.b)
    self.statusLabel:setX(self.statusPanel:getWidth()/2 - self.statusLabel:getWidth()/2)

    self.addSlotButton.enable = false
    self.addSlotButton.backgroundColor = {r=0.3, g=0.3, b=0.3, a=0.8}

    -- Play sound effect
    getSoundManager():PlayWorldSound("rganvil", player:getSquare(), 0, 10, 1, false)
end

function ISAddCardSlotUI:onSlotResult(success)
    local player = getSpecificPlayer(0)

    if success then
        self.statusText = "Success! Added a card slot"
        self.statusColor = {r=0.2, g=1, b=0.2}

        if player then
            getSoundManager():PlayWorldSound("lightswitch", player:getSquare(), 0, 10, 1, false)
        end
    else
        self.statusText = "Failed to add a card slot"
        self.statusColor = {r=1, g=0.5, b=0.5}

        if player then
            getSoundManager():PlayWorldSound("PZ_Cloth_Rip", player:getSquare(), 0, 10, 1, false)
        end
    end

    -- Update status display
    self.statusLabel:setName(self.statusText)
    self.statusLabel:setColor(self.statusColor.r, self.statusColor.g, self.statusColor.b)
    self.statusLabel:setX(self.statusPanel:getWidth()/2 - self.statusLabel:getWidth()/2)

    -- Refresh UI (re-enables button if appropriate)
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
    o.variableColor = {r=0.9, g=0.9, b=0.9, a=1}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.95}
    o.width = width
    o.height = height
    o.moveWithMouse = true
    o.weapon = nil
    o.statusText = "Select a weapon to add a card slot"
    o.statusColor = {r=1, g=1, b=1}
    return o
end

-- Server response handler
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

-- Register command handler
Events.OnServerCommand.Remove(onServerCommand)
Events.OnServerCommand.Add(onServerCommand)
print("[ZM_CardSystem Client] Registered server command handler")

-- Show UI function
function showAddCardSlotUI()
    if _G.CardSlotUI and _G.CardSlotUI:isVisible() then
        return _G.CardSlotUI
    end

    -- Create a larger UI with better proportions (500x400)
    local ui = ISAddCardSlotUI:new(
        (getCore():getScreenWidth() / 2) - 250,
        (getCore():getScreenHeight() / 2) - 200,
        500,
        400
    )

    ui:initialise()
    ui:addToUIManager()
    _G.CardSlotUI = ui

    return ui
end

-- Register command
if not _G.ZM_Commands then _G.ZM_Commands = {} end
_G.ZM_Commands.ShowAddCardSlotUI = showAddCardSlotUI