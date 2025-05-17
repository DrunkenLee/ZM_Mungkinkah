require "ISUI/ISPanel"

ISSavedNameUI = ISPanel:derive("ISSavedNameUI")

-- Constants for layout
local PADDING = 10
local LABEL_HEIGHT = 20
local TEXT_ENTRY_HEIGHT = 25
local BUTTON_HEIGHT = 25
local BUTTON_WIDTH = 100

function ISSavedNameUI:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.width = width
    o.height = height
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    -- o:setResizable(false)
    -- o:setDrawFrame(true)

    return o
end

function ISSavedNameUI:createChildren()
    ISPanel.createChildren(self)

    local y = PADDING

    -- Title as ISTextEntryBox (green, read-only)
    local titleText = "Saved Weapon Details"
    local titleFont = UIFont.Medium
    local titleWidth = getTextManager():MeasureStringX(titleFont, titleText)
    local titleX = (self.width - titleWidth) / 2
    self.title = ISTextEntryBox:new(titleText, titleX, y, titleWidth + 10, LABEL_HEIGHT + 4)
    self.title:initialise()
    self.title:instantiate()
    self.title:setEditable(false)
    -- self.title:setTextColor(0, 1, 0, 1) -- Green
    -- self:addChild(self.title)
    y = y + LABEL_HEIGHT + PADDING

    -- Saved Weapons Dropdown label as ISTextEntryBox
    local labelText = "Your Saved Weapons:"
    local labelFont = UIFont.Small
    local labelWidth = getTextManager():MeasureStringX(labelFont, labelText)
    local labelX = PADDING
    self.savedWeaponsLabel = ISTextEntryBox:new(labelText, labelX, y, labelWidth + 10, LABEL_HEIGHT)
    self.savedWeaponsLabel:initialise()
    self.savedWeaponsLabel:instantiate()
    self.savedWeaponsLabel:setEditable(false)
    self:addChild(self.savedWeaponsLabel)
    y = y + LABEL_HEIGHT

    self.savedWeaponsCombo = ISComboBox:new(PADDING, y, self.width - (PADDING * 2), TEXT_ENTRY_HEIGHT)
    self.savedWeaponsCombo:initialise()
    self.savedWeaponsCombo.onChange = function() self:onWeaponSelected() end
    self:addChild(self.savedWeaponsCombo)
    y = y + TEXT_ENTRY_HEIGHT + PADDING

    -- Save Name label as ISTextEntryBox
    local saveNameText = "Save Name:"
    local saveNameWidth = getTextManager():MeasureStringX(labelFont, saveNameText)
    self.saveNameLabel = ISTextEntryBox:new(saveNameText, PADDING, y, saveNameWidth + 10, LABEL_HEIGHT)
    self.saveNameLabel:initialise()
    self.saveNameLabel:instantiate()
    self.saveNameLabel:setEditable(false)
    self:addChild(self.saveNameLabel)
    y = y + LABEL_HEIGHT

    self.saveNameEntry = ISTextEntryBox:new("", PADDING, y, self.width - (PADDING * 2), TEXT_ENTRY_HEIGHT)
    self.saveNameEntry:initialise()
    self.saveNameEntry:instantiate()
    self.saveNameEntry:setEditable(false)
    self:addChild(self.saveNameEntry)
    y = y + TEXT_ENTRY_HEIGHT + PADDING

    -- Weapon Name label as ISTextEntryBox
    local weaponNameText = "Weapon Name:"
    local weaponNameWidth = getTextManager():MeasureStringX(labelFont, weaponNameText)
    self.weaponNameLabel = ISTextEntryBox:new(weaponNameText, PADDING, y, weaponNameWidth + 10, LABEL_HEIGHT)
    self.weaponNameLabel:initialise()
    self.weaponNameLabel:instantiate()
    self.weaponNameLabel:setEditable(false)
    self:addChild(self.weaponNameLabel)
    y = y + LABEL_HEIGHT

    self.weaponNameEntry = ISTextEntryBox:new("", PADDING, y, self.width - (PADDING * 2), TEXT_ENTRY_HEIGHT)
    self.weaponNameEntry:initialise()
    self.weaponNameEntry:instantiate()
    self.weaponNameEntry:setEditable(false)
    self:addChild(self.weaponNameEntry)
    y = y + TEXT_ENTRY_HEIGHT + PADDING

    -- Original Weapon Name label as ISTextEntryBox
    local originalNameText = "Original Name:"
    local originalNameWidth = getTextManager():MeasureStringX(labelFont, originalNameText)
    self.originalNameLabel = ISTextEntryBox:new(originalNameText, PADDING, y, originalNameWidth + 10, LABEL_HEIGHT)
    self.originalNameLabel:initialise()
    self.originalNameLabel:instantiate()
    self.originalNameLabel:setEditable(false)
    self:addChild(self.originalNameLabel)
    y = y + LABEL_HEIGHT

    self.originalNameEntry = ISTextEntryBox:new("", PADDING, y, self.width - (PADDING * 2), TEXT_ENTRY_HEIGHT)
    self.originalNameEntry:initialise()
    self.originalNameEntry:instantiate()
    self.originalNameEntry:setEditable(false)
    self:addChild(self.originalNameEntry)
    y = y + TEXT_ENTRY_HEIGHT + PADDING

    -- Weapon ID label as ISTextEntryBox
    local weaponIDText = "Weapon ID:"
    local weaponIDWidth = getTextManager():MeasureStringX(labelFont, weaponIDText)
    self.weaponIDLabel = ISTextEntryBox:new(weaponIDText, PADDING, y, weaponIDWidth + 10, LABEL_HEIGHT)
    self.weaponIDLabel:initialise()
    self.weaponIDLabel:instantiate()
    self.weaponIDLabel:setEditable(false)
    self:addChild(self.weaponIDLabel)
    y = y + LABEL_HEIGHT

    self.weaponIDEntry = ISTextEntryBox:new("", PADDING, y, self.width - (PADDING * 2), TEXT_ENTRY_HEIGHT)
    self.weaponIDEntry:initialise()
    self.weaponIDEntry:instantiate()
    self.weaponIDEntry:setEditable(false)
    self:addChild(self.weaponIDEntry)
    y = y + TEXT_ENTRY_HEIGHT + PADDING

    -- Damage label as ISTextEntryBox
    local damageText = "Damage:"
    local damageWidth = getTextManager():MeasureStringX(labelFont, damageText)
    self.damageLabel = ISTextEntryBox:new(damageText, PADDING, y, damageWidth + 10, LABEL_HEIGHT)
    self.damageLabel:initialise()
    self.damageLabel:instantiate()
    self.damageLabel:setEditable(false)
    self:addChild(self.damageLabel)
    y = y + LABEL_HEIGHT

    self.damageEntry = ISTextEntryBox:new("", PADDING, y, self.width - (PADDING * 2), TEXT_ENTRY_HEIGHT)
    self.damageEntry:initialise()
    self.damageEntry:instantiate()
    self.damageEntry:setEditable(false)
    self:addChild(self.damageEntry)
    y = y + TEXT_ENTRY_HEIGHT + PADDING

    -- Enchantment label as ISTextEntryBox
    local enchantmentText = "Enchantment Level:"
    local enchantmentWidth = getTextManager():MeasureStringX(labelFont, enchantmentText)
    self.enchantmentLabel = ISTextEntryBox:new(enchantmentText, PADDING, y, enchantmentWidth + 10, LABEL_HEIGHT)
    self.enchantmentLabel:initialise()
    self.enchantmentLabel:instantiate()
    self.enchantmentLabel:setEditable(false)
    self:addChild(self.enchantmentLabel)
    y = y + LABEL_HEIGHT

    self.enchantmentEntry = ISTextEntryBox:new("", PADDING, y, self.width - (PADDING * 2), TEXT_ENTRY_HEIGHT)
    self.enchantmentEntry:initialise()
    self.enchantmentEntry:instantiate()
    self.enchantmentEntry:setEditable(false)
    self:addChild(self.enchantmentEntry)
    y = y + TEXT_ENTRY_HEIGHT + PADDING

    -- Status label as ISTextEntryBox
    local statusLabelText = "Status:"
    local statusLabelWidth = getTextManager():MeasureStringX(labelFont, statusLabelText)
    self.statusLabel = ISTextEntryBox:new(statusLabelText, PADDING, y, statusLabelWidth + 10, LABEL_HEIGHT)
    self.statusLabel:initialise()
    self.statusLabel:instantiate()
    self.statusLabel:setEditable(false)
    self:addChild(self.statusLabel)
    y = y + LABEL_HEIGHT + 5

    local statusText = "Load your saved weapons list..."
    local statusTextWidth = getTextManager():MeasureStringX(UIFont.Medium, statusText)
    self.statusText = ISTextEntryBox:new(statusText, PADDING, y, statusTextWidth + 10, LABEL_HEIGHT)
    self.statusText:initialise()
    self.statusText:instantiate()
    self.statusText:setEditable(false)
    self:addChild(self.statusText)
    y = y + LABEL_HEIGHT + PADDING

    -- Buttons at the bottom
    local btnY = self.height - BUTTON_HEIGHT - PADDING

    -- Load Saved Weapons List
    self.loadListButton = ISButton:new(PADDING, btnY, BUTTON_WIDTH, BUTTON_HEIGHT, "Load List", self, self.onLoadListButtonClicked)
    self.loadListButton:initialise()
    self:addChild(self.loadListButton)

    -- Apply to Weapon button
    self.applyButton = ISButton:new(PADDING * 2 + BUTTON_WIDTH, btnY, BUTTON_WIDTH, BUTTON_HEIGHT, "Apply", self, self.onApplyButtonClicked)
    self.applyButton:initialise()
    self.applyButton:setEnable(false)
    self:addChild(self.applyButton)

    -- Close button
    self.closeButton = ISButton:new(self.width - BUTTON_WIDTH - PADDING, btnY, BUTTON_WIDTH, BUTTON_HEIGHT, "Close", self, self.onCloseButtonClicked)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    -- Initialize our saved weapons data
    self.savedWeapons = {}
    self.weaponsList = {}
    self.selectedWeaponIndex = nil
end

-- Load the list of weapons saved by the current player
function ISSavedNameUI:onLoadListButtonClicked()
    local username = getPlayer():getUsername()
    -- self.statusText:setName("Loading weapons for " .. username .. "...")

    -- Clear and repopulate the combo box
    self.savedWeaponsCombo:clear()
    self.savedWeapons = {}
    self.weaponsList = {}

    -- Use the new ZM_GetWeaponData function
    ZM_GetWeaponData.RequestUserWeaponData(username, function(weaponsData)
        if weaponsData then
            local count = 0

            -- Create an ordered list of weapons for the dropdown
            for id, weapon in pairs(weaponsData) do
                -- Only process numeric IDs to avoid duplicates (since weapons are indexed by both ID and saveName)
                if type(id) ~= "string" or id:match("^%d+$") then
                    count = count + 1
                    table.insert(self.weaponsList, weapon)

                    -- Add to the dropdown
                    local displayName = weapon.saveName .. " - " .. (weapon.customName or "Unknown")
                    self.savedWeaponsCombo:addOption(displayName)
                end
            end

            -- Store the full data structure for reference
            self.savedWeapons = weaponsData

            -- Update status and enable buttons
            -- self.statusText:setName("Found " .. count .. " saved weapons.")
            if count > 0 then
                self.savedWeaponsCombo.selected = 1
                self:onWeaponSelected()
                self.applyButton:setEnable(true)
            else
                self.applyButton:setEnable(false)
            end
        else
            -- self.statusText:setName("Failed to load saved weapons.")
            self.applyButton:setEnable(false)
        end
    end)
end

-- When a weapon is selected from the dropdown
function ISSavedNameUI:onWeaponSelected()
    local selectedIndex = self.savedWeaponsCombo.selected
    if not selectedIndex or selectedIndex <= 0 or not self.weaponsList[selectedIndex] then
        return
    end

    self.selectedWeaponIndex = selectedIndex
    local weapon = self.weaponsList[selectedIndex]

    -- Fill in the form with the selected weapon's data
    self.saveNameEntry:setText(weapon.saveName or "")
    self.weaponNameEntry:setText(weapon.customName or "")
    self.originalNameEntry:setText(weapon.originalName or "")
    self.weaponIDEntry:setText(weapon.weaponID or "")
    self.damageEntry:setText(string.format("%.2f-%.2f", weapon.minDamage or 0, weapon.maxDamage or 0))
    self.enchantmentEntry:setText(tostring(weapon.enchantLevel or "0"))

    -- self.statusText:setName("Selected: " .. (weapon.saveName or "Unknown"))
    self.applyButton:setEnable(true)
end

-- Apply the selected weapon data to the equipped weapon
function ISSavedNameUI:onApplyButtonClicked()
    -- Make sure we have a weapon selected
    if not self.selectedWeaponIndex or not self.weaponsList[self.selectedWeaponIndex] then
        -- self.statusText:setName("No weapon selected!")
        return
    end

    -- Check if player has a weapon equipped
    local player = getSpecificPlayer(self.player)
    local equippedWeapon = player:getPrimaryHandItem()

    if not equippedWeapon or not equippedWeapon:IsWeapon() then
        -- self.statusText:setName("You must have a weapon equipped!")
        return
    end

    -- Get the selected weapon data
    local weapon = self.weaponsList[self.selectedWeaponIndex]

    -- Apply the data to the equipped weapon (assuming ZM_SaveWeaponData.ApplyWeaponDataBySaveName exists)
    if ZM_SaveWeaponData and ZM_SaveWeaponData.ApplyWeaponDataBySaveName then
        ZM_SaveWeaponData.ApplyWeaponDataBySaveName(weapon.saveName, function(success)
            if success then
                -- self.statusText:setName("Applied " .. weapon.saveName .. " to your weapon!")
            else
                -- self.statusText:setName("Failed to apply weapon data!")
            end
        end)
    else
        -- Fallback if the apply function doesn't exist
        sendClientCommand("EnchantWeapon", "applyEnchantment", {
            saveName = weapon.saveName,
            targetID = equippedWeapon:getID()
        })
        -- self.statusText:setName("Sent request to apply " .. weapon.saveName)
    end
end

function ISSavedNameUI:onCloseButtonClicked()
    self:removeFromUIManager()
end

function ISSavedNameUI:prerender()
    ISPanel.prerender(self)
end

function ISSavedNameUI:render()
    ISPanel.render(self)
end

-- Function to create and show the UI
function ISSavedNameUI.ShowUI(playerNum)
    local player = getSpecificPlayer(playerNum or 0)
    if not player then return end

    -- Create the UI
    local width = 400
    local height = 550 -- Made slightly taller to accommodate the original name field
    local x = (getCore():getScreenWidth() / 2) - (width / 2)
    local y = (getCore():getScreenHeight() / 2) - (height / 2)

    local ui = ISSavedNameUI:new(x, y, width, height, playerNum or 0)
    ui:initialise()
    ui:addToUIManager()
    return ui
end

function ISSavedNameUI.OnKeyPressed(key)
    if key == 83 and isKeyDown(29) then
        ISSavedNameUI.ShowUI(0)
    end
end

-- Register key binding
Events.OnKeyPressed.Add(ISSavedNameUI.OnKeyPressed)