--***********************************************************
--**                 BOOT REFINE UI                       **
--**           Detailed Equipment Refinement System       **
--***********************************************************

require "ISUI/ISPanel"

-- Import GlobalMethods for ServerPoints integration
local GlobalMethods = require "globalmethods"

ISBootRefineUI = ISPanel:derive("ISBootRefineUI")

-- Global UI instance tracker
_G.ZM_BootRefineUI = _G.ZM_BootRefineUI or nil

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function ISBootRefineUI:initialise()
    ISPanel.initialise(self)
    self.refineResult = nil
    self.lastUpdateTime = 0
end

function ISBootRefineUI:createChildren()
    ISPanel.createChildren(self)

    local btnWid = 140
    local btnHgt = FONT_HGT_MEDIUM + 8
    local padding = 10

    -- Equipment selection tabs (for future expansion)
    local tabY = 40
    self.bootTab = ISButton:new(20, tabY, 80, 25, "Boots", self, ISBootRefineUI.onTabClick)
    self.bootTab.internal = "BOOTS"
    self.bootTab:initialise()
    self.bootTab:instantiate()
    self.bootTab.backgroundColor = {r=0.2, g=0.4, b=0.6, a=0.8}
    self.bootTab.backgroundColorMouseOver = {r=0.3, g=0.5, b=0.7, a=0.9}
    self.bootTab.font = UIFont.Small
    self:addChild(self.bootTab)

    -- Vest tab
    self.vestTab = ISButton:new(105, tabY, 80, 25, "Vest", self, ISBootRefineUI.onTabClick)
    self.vestTab.internal = "VEST"
    self.vestTab:initialise()
    self.vestTab:instantiate()
    self.vestTab.backgroundColor = {r=0.3, g=0.3, b=0.3, a=0.6}
    self.vestTab.backgroundColorMouseOver = {r=0.4, g=0.4, b=0.4, a=0.7}
    self.vestTab.font = UIFont.Small
    self:addChild(self.vestTab)

    -- Bag tab
    self.bagTab = ISButton:new(190, tabY, 80, 25, "Bag", self, ISBootRefineUI.onTabClick)
    self.bagTab.internal = "BAG"
    self.bagTab:initialise()
    self.bagTab:instantiate()
    self.bagTab.backgroundColor = {r=0.3, g=0.3, b=0.3, a=0.6}
    self.bagTab.backgroundColorMouseOver = {r=0.4, g=0.4, b=0.4, a=0.7}
    self.bagTab.font = UIFont.Small
    self:addChild(self.bagTab)

    -- Future tabs (greyed out for now)
    self.armorTab = ISButton:new(275, tabY, 80, 25, "Armor", self, ISBootRefineUI.onTabClick)
    self.armorTab.internal = "ARMOR"
    self.armorTab:initialise()
    self.armorTab:instantiate()
    self.armorTab.backgroundColor = {r=0.3, g=0.3, b=0.3, a=0.6}
    self.armorTab.backgroundColorMouseOver = {r=0.4, g=0.4, b=0.4, a=0.7}
    self.armorTab.font = UIFont.Small
    self.armorTab.enable = false
    self:addChild(self.armorTab)

    -- Current selection
    self.currentTab = "BOOTS"

    -- Refresh button
    self.refreshButton = ISButton:new(self.width - 80, tabY, 60, 25, "Refresh", self, ISBootRefineUI.onRefresh)
    self.refreshButton.internal = "REFRESH"
    self.refreshButton:initialise()
    self.refreshButton:instantiate()
    self.refreshButton.backgroundColor = {r=0.2, g=0.6, b=0.2, a=0.8}
    self.refreshButton.font = UIFont.Small
    self:addChild(self.refreshButton)

    -- Equipment info panel
    self.equipInfoY = tabY + 40
    self.equipInfoHeight = 270

    -- Stats comparison panel
    self.statsY = self.equipInfoY + self.equipInfoHeight + 20
    self.statsHeight = 290

    -- Refine controls
    self.refineY = self.statsY + self.statsHeight + 20

    -- Success rate slider
    self.successLabel = ISLabel:new(20, self.refineY, FONT_HGT_SMALL, "Success Rate:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.successLabel)

    self.successValue = ISLabel:new(120, self.refineY, FONT_HGT_SMALL, "50%", 1, 1, 0, 1, UIFont.Small, true)
    self:addChild(self.successValue)

    -- Refine button
    self.refineButton = ISButton:new(self.width/2 - btnWid/2, self.refineY + 40, btnWid, btnHgt,
                                   "Refine Equipment", self, ISBootRefineUI.onRefineClick)
    self.refineButton.internal = "REFINE"
    self.refineButton:initialise()
    self.refineButton:instantiate()
    self.refineButton.backgroundColor = {r=0.6, g=0.3, b=0.1, a=0.9}
    self.refineButton.backgroundColorMouseOver = {r=0.8, g=0.4, b=0.2, a=1.0}
    self.refineButton.font = UIFont.Medium
    self:addChild(self.refineButton)

    -- Result display
    self.resultY = self.refineY + 150

    -- Close button
    self.closeButton = ISButton:new(self.width - btnWid - 10, self.height - btnHgt - 10,
                                  btnWid, btnHgt, "Close", self, ISBootRefineUI.onClick)
    self.closeButton.internal = "CLOSE"
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self.closeButton.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0.8}
    self.closeButton.font = UIFont.Medium
    self:addChild(self.closeButton)

    -- Initialize data
    self:refreshEquipmentData()
end

function ISBootRefineUI:onTabClick(button)
    if button.internal then
        self.currentTab = button.internal
        -- Update tab appearances
        self:updateTabAppearance()
        self:refreshEquipmentData()
    end
end

function ISBootRefineUI:updateTabAppearance()
    -- Reset all tab colors
    self.bootTab.backgroundColor = {r=0.3, g=0.3, b=0.3, a=0.6}
    self.vestTab.backgroundColor = {r=0.3, g=0.3, b=0.3, a=0.6}
    self.bagTab.backgroundColor = {r=0.3, g=0.3, b=0.3, a=0.6}
    self.armorTab.backgroundColor = {r=0.3, g=0.3, b=0.3, a=0.6}

    -- Highlight active tab
    if self.currentTab == "BOOTS" then
        self.bootTab.backgroundColor = {r=0.2, g=0.4, b=0.6, a=0.8}
    elseif self.currentTab == "VEST" then
        self.vestTab.backgroundColor = {r=0.2, g=0.4, b=0.6, a=0.8}
    elseif self.currentTab == "BAG" then
        self.bagTab.backgroundColor = {r=0.2, g=0.4, b=0.6, a=0.8}
    elseif self.currentTab == "ARMOR" then
        self.armorTab.backgroundColor = {r=0.2, g=0.4, b=0.6, a=0.8}
    end
end

function ISBootRefineUI:onRefresh(button)
    self:refreshEquipmentData()
    print("[BootRefineUI] Equipment data refreshed")
end

function ISBootRefineUI:onSuccessRateChange(value)
    -- self.successValue:setName(value .. "%")
end

function ISBootRefineUI:refreshEquipmentData()
    if self.currentTab == "BOOTS" then
        -- Get boot data using the handler
        if BootRefineHandler and BootRefineHandler.getPlayerBoot then
            self.currentBoots = BootRefineHandler.getPlayerBoot()
            if self.currentBoots then
                self.bootStats = BootRefineHandler.getBootModifiers()
            else
                self.bootStats = nil
            end
        end
    elseif self.currentTab == "VEST" then
        -- Get vest data using the handler
        if BootRefineHandler and BootRefineHandler.getPlayerVest then
            self.currentVest = BootRefineHandler.getPlayerVest()
            if self.currentVest then
                self.vestStats = BootRefineHandler.getVestModifiers()
            else
                self.vestStats = nil
            end
        end
    elseif self.currentTab == "BAG" then
        -- Get bag data using the handler
        if BootRefineHandler and BootRefineHandler.getPlayerBag then
            self.currentBag = BootRefineHandler.getPlayerBag()
            if self.currentBag then
                self.bagStats = BootRefineHandler.getBagModifiers()
            else
                self.bagStats = nil
            end
        end
    end
    self.lastUpdateTime = getTimestamp()
end

function ISBootRefineUI:onRefineClick(button)
    local result = nil
    local successRate = "50"

    if self.currentTab == "BOOTS" and self.currentBoots then
        -- Call boot refine function directly (synchronous)
        result = BootRefineHandler.refineBootMods({
            successRate = successRate
        })
        print("[BootRefineUI] Boot refinement attempted with " .. successRate .. "% success rate")
    elseif self.currentTab == "VEST" and self.currentVest then
        -- Call vest refine function directly (synchronous)
        result = BootRefineHandler.refineVestMods({
            successRate = successRate
        })
        print("[BootRefineUI] Vest refinement attempted with " .. successRate .. "% success rate")
    elseif self.currentTab == "BAG" and self.currentBag then
        -- Call bag refine function directly (synchronous)
        result = BootRefineHandler.refineBagMods({
            successRate = successRate
        })
        print("[BootRefineUI] Bag refinement attempted with " .. successRate .. "% success rate")
    else
        print("[BootRefineUI] No equipment equipped for refinement")
        return
    end

    self.refineResult = result

    -- Refresh data to show changes
    self:refreshEquipmentData()
end

function ISBootRefineUI:onClick(button)
    if button.internal == "CLOSE" then
        self:close()
    end
end

function ISBootRefineUI:debugPrintStats(stats, equipmentType)
    if not stats then
        print("[DEBUG] No stats available for " .. (equipmentType or "unknown"))
        return
    end

    print("========== DEBUG STATS for " .. string.upper(equipmentType or "UNKNOWN") .. " ==========")

    -- Print all available stats with their values and types
    local statCount = 0
    for key, value in pairs(stats) do
        statCount = statCount + 1
        local valueType = type(value)
        local valueStr = ""

        if valueType == "nil" then
            valueStr = "nil"
        elseif valueType == "boolean" then
            valueStr = tostring(value)
        elseif valueType == "number" then
            valueStr = string.format("%.3f", value)
        elseif valueType == "string" then
            valueStr = '"' .. value .. '"'
        else
            valueStr = tostring(value) .. " (" .. valueType .. ")"
        end

        print(string.format("[DEBUG] %s = %s", key, valueStr))
    end

    print("[DEBUG] Total stats found: " .. statCount)
    print("========== END DEBUG STATS ==========")
end

function ISBootRefineUI:drawEquipmentInfo()
    local panelX = 20
    local panelW = self.width - 40
    local panelH = self.equipInfoHeight

    -- Draw equipment info panel background
    self:drawRectBorder(panelX, self.equipInfoY, panelW, panelH, 0.8, 0.4, 0.4, 0.4)
    self:drawRect(panelX + 1, self.equipInfoY + 1, panelW - 2, panelH - 2, 0.3, 0.05, 0.05, 0.1)

    -- Title
    local title = "Equipment Details"
    self:drawText(title, panelX + 10, self.equipInfoY + 10, 1, 1, 0.8, 1, UIFont.Medium)

    local textY = self.equipInfoY + 35
    local lineHeight = FONT_HGT_SMALL + 2

    -- Get current equipment data based on active tab
    local currentItem = nil
    local currentStats = nil
    local equipmentType = ""

    if self.currentTab == "BOOTS" then
        currentItem = self.currentBoots
        currentStats = self.bootStats
        equipmentType = "boots"
    elseif self.currentTab == "VEST" then
        currentItem = self.currentVest
        currentStats = self.vestStats
        equipmentType = "vest"
    elseif self.currentTab == "BAG" then
        currentItem = self.currentBag
        currentStats = self.bagStats
        equipmentType = "bag"
    end

    if currentItem and currentStats then
        -- Equipment name and type
        self:drawText("Item: " .. (currentStats.DisplayName or "Unknown"), panelX + 10, textY, 1, 1, 1, 1, UIFont.Small)
        textY = textY + lineHeight
        self:drawText("Type: " .. (currentStats.FullType or "Unknown"), panelX + 10, textY, 0.8, 0.8, 0.8, 1, UIFont.Small)
        textY = textY + lineHeight + 5

        -- Physical properties
        self:drawText("Physical Properties:", panelX + 10, textY, 0.9, 0.9, 0.6, 1, UIFont.Small)
        textY = textY + lineHeight

        local condition = currentStats.Condition or 0
        local conditionMax = currentStats.ConditionMax or 100
        local conditionPercent = conditionMax > 0 and math.floor((condition / conditionMax) * 100) or 0
        local conditionColor = {r = 1, g = 1, b = 1}
        if conditionPercent < 30 then
            conditionColor = {r = 1, g = 0.3, b = 0.3}
        elseif conditionPercent < 60 then
            conditionColor = {r = 1, g = 0.8, b = 0.3}
        else
            conditionColor = {r = 0.3, g = 1, b = 0.3}
        end

        self:drawText(string.format("  Condition: %.1f/%.1f (%d%%)", condition, conditionMax, conditionPercent),
                     panelX + 20, textY, conditionColor.r, conditionColor.g, conditionColor.b, 1, UIFont.Small)
        textY = textY + lineHeight

        self:drawText(string.format("  Weight: %.2f kg", currentStats.Weight or 0), panelX + 20, textY, 1, 1, 1, 1, UIFont.Small)
        textY = textY + lineHeight + 5

        -- Performance stats
        self:drawText("Performance:", panelX + 10, textY, 0.9, 0.9, 0.6, 1, UIFont.Small)
        textY = textY + lineHeight

        -- Equipment-specific performance stats
        if equipmentType == "boots" then
            local runSpeed = currentStats.RunSpeedModifier or 1.0
            local runSpeedPercent = math.floor((runSpeed - 1.0) * 100)
            local runSpeedText = runSpeedPercent >= 0 and ("+" .. runSpeedPercent .. "%") or (runSpeedPercent .. "%")
            local runSpeedColor = runSpeedPercent >= 0 and {r = 0.3, g = 1, b = 0.3} or {r = 1, g = 0.5, b = 0.3}

            self:drawText("  Run Speed: " .. runSpeedText, panelX + 20, textY, runSpeedColor.r, runSpeedColor.g, runSpeedColor.b, 1, UIFont.Small)
            textY = textY + lineHeight

        elseif equipmentType == "vest" then
            -- Vest specific stats - show run speed and combat speed
            local runSpeed = currentStats.RunSpeedModifier or 1.0
            local runSpeedPercent = math.floor((runSpeed - 1.0) * 100)
            local runSpeedText = runSpeedPercent >= 0 and ("+" .. runSpeedPercent .. "%") or (runSpeedPercent .. "%")
            local runSpeedColor = runSpeedPercent >= 0 and {r = 0.3, g = 1, b = 0.3} or {r = 1, g = 0.5, b = 0.3}

            self:drawText("  Run Speed: " .. runSpeedText, panelX + 20, textY, runSpeedColor.r, runSpeedColor.g, runSpeedColor.b, 1, UIFont.Small)
            textY = textY + lineHeight

            if currentStats.CombatSpeedMod then
                local combatSpeed = currentStats.CombatSpeedMod or 1.0
                local combatSpeedPercent = math.floor((combatSpeed - 1.0) * 100)
                local combatSpeedText = combatSpeedPercent >= 0 and ("+" .. combatSpeedPercent .. "%") or (combatSpeedPercent .. "%")
                local combatSpeedColor = combatSpeedPercent >= 0 and {r = 0.3, g = 1, b = 0.3} or {r = 1, g = 0.5, b = 0.3}

                self:drawText("  Combat Speed: " .. combatSpeedText, panelX + 20, textY, combatSpeedColor.r, combatSpeedColor.g, combatSpeedColor.b, 1, UIFont.Small)
                textY = textY + lineHeight
            end

            -- Vest specific protection stats
            if currentStats.BulletDefense then
                self:drawText(string.format("  Bullet Defense: %d", currentStats.BulletDefense), panelX + 20, textY, 1, 0.8, 0.3, 1, UIFont.Small)
                textY = textY + lineHeight
            end
            if currentStats.Thickness then
                self:drawText(string.format("  Thickness: %.2f", currentStats.Thickness), panelX + 20, textY, 0.9, 0.9, 0.7, 1, UIFont.Small)
                textY = textY + lineHeight
            end

            -- Show wind and water resistance if available
            if currentStats.WindResistance then
                self:drawText(string.format("  Wind Resistance: %.1f", currentStats.WindResistance), panelX + 20, textY, 0.7, 0.9, 1, 1, UIFont.Small)
                textY = textY + lineHeight
            end
            if currentStats.WaterResistance then
                self:drawText(string.format("  Water Resistance: %.1f", currentStats.WaterResistance), panelX + 20, textY, 0.7, 0.9, 1, 1, UIFont.Small)
                textY = textY + lineHeight
            end        elseif equipmentType == "bag" then
            -- Bag specific stats - show weight reduction and capacity
            if currentStats.WeightReduction then
                local weightReduction = currentStats.WeightReduction or 0
                local weightReductionPercent = math.floor(weightReduction * 1)
                self:drawText(string.format("  Weight Reduction: %d%%", weightReductionPercent), panelX + 20, textY, 0.3, 1, 0.7, 1, UIFont.Small)
                textY = textY + lineHeight
            end
            if currentStats.Capacity then
                self:drawText(string.format("  Capacity: %.1f", currentStats.Capacity), panelX + 20, textY, 0.7, 0.9, 1, 1, UIFont.Small)
                textY = textY + lineHeight
            end
            if not currentStats.WeightReduction and not currentStats.Capacity then
                self:drawText("  Bags can be refined for durability only", panelX + 20, textY, 0.7, 0.7, 0.7, 1, UIFont.Small)
                textY = textY + lineHeight
                self:drawText("  (Some bags may have weight reduction)", panelX + 20, textY, 0.6, 0.6, 0.6, 1, UIFont.Small)
                textY = textY + lineHeight
            end
        end

        -- Show insulation only for equipment that has it
        if currentStats.Insulation and equipmentType ~= "bag" then
            self:drawText(string.format("  Insulation: %.1f", currentStats.Insulation), panelX + 20, textY, 1, 1, 1, 1, UIFont.Small)
            textY = textY + lineHeight
        end
        textY = textY + 5

        -- Debug print to check all stats in detail
        -- self:debugPrintStats(currentStats, equipmentType)

        -- Defense stats (only for boots and vests)
        if equipmentType ~= "bag" then
            self:drawText("Defense:", panelX + 10, textY, 0.9, 0.9, 0.6, 1, UIFont.Small)
            textY = textY + lineHeight

            -- Draw both defense stats on the same line
            self:drawText(string.format("  Scratch: %d", currentStats.ScratchDefense or 0), panelX + 20, textY, 0.8, 1, 0.8, 1, UIFont.Small)
            self:drawText(string.format("Bite: %d", currentStats.BiteDefense or 0), panelX + 150, textY, 0.8, 1, 0.8, 1, UIFont.Small)
            textY = textY + lineHeight + 5
        end

        -- Equipment-specific stats
        if equipmentType == "vest" and currentStats.Category then
            self:drawText("Category: " .. currentStats.Category, panelX + 20, textY, 0.7, 0.7, 0.7, 1, UIFont.Small)
            textY = textY + lineHeight
        elseif equipmentType == "bag" then
            -- Show bag-specific info
            if currentStats.Category then
                self:drawText("Category: " .. currentStats.Category, panelX + 20, textY, 0.7, 0.7, 0.7, 1, UIFont.Small)
                textY = textY + lineHeight
            end
            self:drawText("Refineable: Durability, Weight Reduction, Capacity", panelX + 20, textY, 0.6, 0.8, 0.6, 1, UIFont.Small)
            textY = textY + lineHeight
        end

    else
        local equipmentName = string.lower(equipmentType)
        self:drawText("No " .. equipmentName .. " equipped", panelX + 10, textY, 1, 0.5, 0.5, 1, UIFont.Small)
        textY = textY + lineHeight + 10
        self:drawText("Please equip " .. equipmentName .. " to view stats and refine them.", panelX + 10, textY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end

    if self.currentTab == "ARMOR" then
        self:drawText("Feature coming soon!", panelX + 10, textY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
end

function ISBootRefineUI:drawStatsComparison()
    local panelX = 20
    local panelW = self.width - 40
    local panelH = self.statsHeight

    -- Draw stats comparison panel background
    self:drawRectBorder(panelX, self.statsY, panelW, panelH, 0.8, 0.4, 0.4, 0.4)
    self:drawRect(panelX + 1, self.statsY + 1, panelW - 2, panelH - 2, 0.3, 0.1, 0.05, 0.05)

    -- Title
    local title = "Ewok's Refinement Information"
    self:drawText(title, panelX + 10, self.statsY + 10, 1, 0.8, 1, 1, UIFont.Medium)

    local textY = self.statsY + 35
    local lineHeight = FONT_HGT_SMALL + 2

    -- Refinement info
    self:drawText("Refinement System:", panelX + 10, textY, 0.9, 0.9, 0.6, 1, UIFont.Small)
    textY = textY + lineHeight

    self:drawText("Two-roll system: Success/Fail + Random stat selection", panelX + 20, textY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    textY = textY + lineHeight

    -- Boots & Vest info
    self:drawText("Boots & Vest:", panelX + 20, textY, 0.9, 0.9, 0.6, 1, UIFont.Small)
    textY = textY + lineHeight
    self:drawText("  - FAIL = 1 random stat REDUCES!", panelX + 30, textY, 1, 0.6, 0.6, 1, UIFont.Small)
    textY = textY + lineHeight

    -- Bag info
    self:drawText("Bags:", panelX + 20, textY, 0.9, 0.9, 0.6, 1, UIFont.Small)
    textY = textY + lineHeight
    self:drawText("  - FAIL = 1 random stat REDUCES!", panelX + 30, textY, 1, 0.6, 0.6, 1, UIFont.Small)
    textY = textY + lineHeight + 5

    self:drawText("IMPORTANT: Random degradation on failure!", panelX + 20, textY, 1, 0.9, 0.4, 1, UIFont.Small)
    textY = textY + lineHeight

    self:drawText("Random Selection:", panelX + 20, textY, 0.9, 0.9, 0.6, 1, UIFont.Small)
    textY = textY + lineHeight
    self:drawText("  - Normal: 1 random stat improved", panelX + 30, textY, 0.7, 0.7, 0.7, 1, UIFont.Small)
    textY = textY + lineHeight
    self:drawText("  - Special Roll -> (7,17): 2 random stats", panelX + 30, textY, 1, 0.8, 0.3, 1, UIFont.Small)
    textY = textY + lineHeight
    self:drawText("  - Special Roll -> (14): ALL stats", panelX + 30, textY, 1, 0.8, 0.3, 1, UIFont.Small)
    textY = textY + lineHeight
    self:drawText("  - Special Roll -> (27): 3 random stats", panelX + 30, textY, 1, 0.8, 0.3, 1, UIFont.Small)
    textY = textY + lineHeight
    self:drawText("Special rolls point: 2x base point improvement!", panelX + 20, textY, 1, 0.8, 0.3, 1, UIFont.Small)
    textY = textY + lineHeight + 10

    -- Show current refinement costs
    self:drawText("Refinement Costs:", panelX + 10, textY, 1, 1, 0.8, 1, UIFont.Small)
    textY = textY + lineHeight

    local currentCost = 0
    if self.currentTab == "BOOTS" then
        currentCost = 2000
        self:drawText("Boots: 2,000 ServerPoints -> No Discount Applied 0%", panelX + 20, textY, 0.9, 0.9, 0.6, 1, UIFont.Small)
    elseif self.currentTab == "VEST" then
        currentCost = 2000
        self:drawText("Vest: 2,000 ServerPoints -> No Discount Applied 0%", panelX + 20, textY, 0.9, 0.9, 0.6, 1, UIFont.Small)
    elseif self.currentTab == "BAG" then
        currentCost = 5000
        self:drawText("Bag: 5,000 ServerPoints -> No Discount Applied 0%", panelX + 20, textY, 0.9, 0.9, 0.6, 1, UIFont.Small)
    end
    textY = textY + lineHeight

    -- Show current player points
    local player = getPlayer()
    if player and GlobalMethods then
        local username = player:getUsername()
        local currentPoints = GlobalMethods.getPlayerPoints(username) or 0
        local hasEnough = currentPoints >= currentCost
        local color = hasEnough and {r=0.3, g=1, b=0.3} or {r=1, g=0.6, b=0.6}
        -- self:drawText("Current Points: " .. currentPoints, panelX + 20, textY, color.r, color.g, color.b, 1, UIFont.Small)
    else
        -- self:drawText("Current Points: Loading...", panelX + 20, textY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
end

function ISBootRefineUI:drawRefineResult()
    if not self.refineResult then return end

    local panelX = 20
    local panelW = self.width - 40
    local textY = self.resultY
    local lineHeight = FONT_HGT_SMALL + 2

    -- Draw result background
    local resultH = 60
    if self.refineResult.success and self.refineResult.stats then
        resultH = 60 + (#self.refineResult.stats * lineHeight)
    end

    self:drawRectBorder(panelX, textY, panelW, resultH, 0.8, 0.4, 0.4, 0.4)

    local bgColor = self.refineResult.success and {r = 0.05, g = 0.1, b = 0.05} or {r = 0.1, g = 0.05, b = 0.05}
    self:drawRect(panelX + 1, textY + 1, panelW - 2, resultH - 2, 0.3, bgColor.r, bgColor.g, bgColor.b)

    textY = textY + 10

    if self.refineResult.success then
        local resultText = "Refinement SUCCESS!"
        if self.refineResult.isSpecialRoll then
            resultText = "SPECIAL REFINEMENT SUCCESS! (Roll " .. self.refineResult.rollPercent .. ")"
        end
        self:drawText(resultText, panelX + 10, textY, 0.3, 1, 0.3, 1, UIFont.Small)
        textY = textY + lineHeight

        -- Show roll information
        local rollInfo = string.format("Roll: %d | Success Rate: %d%%",
            self.refineResult.rollPercent, self.refineResult.successRate)
        if self.refineResult.isSpecialRoll then
            rollInfo = rollInfo .. " | SPECIAL ROLL (2x improvement!)"
        end
        self:drawText(rollInfo, panelX + 10, textY, 0.8, 0.8, 1, 1, UIFont.Small)
        textY = textY + lineHeight

        -- Show cost information
        if self.refineResult.cost then
            local costText = "Cost: " .. self.refineResult.cost .. " ServerPoints"
            if self.refineResult.costDeducted then
                costText = costText .. " (Deducted)"
            end
            self:drawText(costText, panelX + 10, textY, 1, 0.8, 0.3, 1, UIFont.Small)
            textY = textY + lineHeight
        end
        textY = textY + 5

        if self.refineResult.stats then
            self:drawText("Stats improved:", panelX + 10, textY, 1, 1, 0.8, 1, UIFont.Small)
            textY = textY + lineHeight

            for _, stat in ipairs(self.refineResult.stats) do
                if stat.ok then
                    local changeText = string.format("%s: %.2f → %.2f (+%.2f)",
                        stat.stat, stat.oldValue or 0, stat.newValue or 0, stat.increase or 0)
                    if stat.isSpecial then
                        changeText = changeText .. " [SPECIAL x2]"
                    end
                    self:drawText("  " .. changeText, panelX + 20, textY, 0.8, 1, 0.8, 1, UIFont.Small)
                else
                    self:drawText("  " .. stat.stat .. ": Failed to update", panelX + 20, textY, 1, 0.5, 0.5, 1, UIFont.Small)
                end
                textY = textY + lineHeight
            end
        end
    else
        -- Handle failure cases, including bag degradation
        if self.refineResult.isDegradation then
            self:drawText("Refinement FAILED - Equipment Degraded!", panelX + 10, textY, 1, 0.3, 0.3, 1, UIFont.Small)
            textY = textY + lineHeight

            -- Show degradation info for bags
            local rollInfo = string.format("Roll: %d | Success Rate: %d%% | Equipment: %s",
                self.refineResult.roll1 or 0, self.refineResult.successRate or 0,
                self.refineResult.equipmentType or "unknown")
            self:drawText(rollInfo, panelX + 10, textY, 0.8, 0.6, 0.6, 1, UIFont.Small)
            textY = textY + lineHeight

            -- Show cost information
            if self.refineResult.cost then
                local costText = "Cost: " .. self.refineResult.cost .. " ServerPoints"
                if self.refineResult.costDeducted then
                    costText = costText .. " (Deducted)"
                end
                self:drawText(costText, panelX + 10, textY, 1, 0.8, 0.3, 1, UIFont.Small)
                textY = textY + lineHeight
            end
            textY = textY + 5

            if self.refineResult.stats then
                self:drawText("Stats degraded:", panelX + 10, textY, 1, 0.7, 0.7, 1, UIFont.Small)
                textY = textY + lineHeight

                for _, stat in ipairs(self.refineResult.stats) do
                    if stat.ok then
                        local changeText = string.format("%s: %.2f → %.2f (%+.2f)",
                            stat.stat, stat.oldValue or 0, stat.newValue or 0, stat.change or 0)
                        self:drawText("  " .. changeText, panelX + 20, textY, 1, 0.5, 0.5, 1, UIFont.Small)
                    else
                        self:drawText("  " .. stat.stat .. ": Failed to degrade", panelX + 20, textY, 0.8, 0.4, 0.4, 1, UIFont.Small)
                    end
                    textY = textY + lineHeight
                end
            end
        else
            self:drawText("Refinement FAILED", panelX + 10, textY, 1, 0.5, 0.5, 1, UIFont.Small)
            textY = textY + lineHeight

            local failReason = "Better luck next time!"
            if self.refineResult.reason == "no_boots" then
                failReason = "No equipment to refine"
            elseif self.refineResult.reason == "no_bag" then
                failReason = "No bag to refine"
            elseif self.refineResult.reason == "no_vest" then
                failReason = "No vest to refine"
            elseif self.refineResult.reason == "insufficient_points" then
                failReason = string.format("Insufficient ServerPoints! Need %d, have %d",
                    self.refineResult.required or 0, self.refineResult.current or 0)
            elseif self.refineResult.reason == "points_check_error" then
                failReason = "Error checking ServerPoints"
            end
            self:drawText(failReason, panelX + 10, textY, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
    end
end

function ISBootRefineUI:prerender()
    -- Auto-refresh equipment data periodically
    if getTimestamp() - self.lastUpdateTime > 5 then
        self:refreshEquipmentData()
    end

    -- Draw background
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    -- Draw title
    local title = "Equipment Refinement System"
    local titleX = self.width/2 - getTextManager():MeasureStringX(UIFont.Medium, title)/2
    self:drawText(title, titleX, 10, 1, 1, 0.8, 1, UIFont.Medium)

    -- Draw main content panels
    self:drawEquipmentInfo()
    self:drawStatsComparison()
    self:drawRefineResult()
end

function ISBootRefineUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    _G.ZM_BootRefineUI = nil
end

function ISBootRefineUI:new(x, y, width, height)
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

-- Global function to show the UI
function showBootRefineUI()
    if _G.ZM_BootRefineUI and _G.ZM_BootRefineUI:isVisible() then
        _G.ZM_BootRefineUI:close()
        return nil
    end

    local ui = ISBootRefineUI:new(200, 100, 500, 800)
    ui:initialise()
    ui:addToUIManager()
    _G.ZM_BootRefineUI = ui

    return ui
end

-- Register global command
if not _G.ZM_Commands then _G.ZM_Commands = {} end
_G.ZM_Commands.ShowBootRefineUI = showBootRefineUI

-- Make it easily accessible
_G.OpenBootRefineUI = showBootRefineUI

print("[ISBootRefineUI] Boot Refinement UI loaded successfully")
