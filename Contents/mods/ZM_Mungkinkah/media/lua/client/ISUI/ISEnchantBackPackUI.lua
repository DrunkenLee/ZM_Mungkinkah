--***********************************************************
--**            BACKPACK ENCHANTMENT UI                    **
--***********************************************************

ISEnchantBackpackUI = ISPanel:derive("ISEnchantBackpackUI")

-- Global variable to track UI instance
local BackpackEnchantingUI = nil

-- Callback system to track pending backpack checks
if not _G.PendingBackpackChecks then
    _G.PendingBackpackChecks = {}
end

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- Add server response handler to process backpack checks
local function handleBackpackCheckResponse(module, command, args)
    if module == "EnchantBackpack" and command == "backpackCheckResult" then
        local backpackID = args.backpackID
        local isFound = args.isFound
        local isBroken = args.isBroken or false

        -- Check if we have a pending callback for this backpack
        if _G.PendingBackpackChecks[backpackID] then
            -- Call the callback with the result
            _G.PendingBackpackChecks[backpackID](isFound, isBroken, args)
            -- Remove the pending check
            _G.PendingBackpackChecks[backpackID] = nil
        end
    end
end

-- Register the server response handler
Events.OnServerCommand.Add(handleBackpackCheckResponse)

function ISEnchantBackpackUI:initialise()
    ISPanel.initialise(self)

    -- Always reset protection flag to false on UI initialization
    if PlayerFlagHandler and PlayerFlagHandler.setFlag then
        PlayerFlagHandler.setFlag("backpackEnchantProtection", false)
    end
end

function ISEnchantBackpackUI:createChildren()
    ISPanel.createChildren(self)

    -- Button dimensions
    local btnWid = 120
    local btnHgt = FONT_HGT_MEDIUM + 6

    -- Enchant button (always start with 2500 points cost)
    self.enchantButton = ISButton:new(self.width/2 - btnWid/2, 150,
                                    btnWid, btnHgt, "Pay (2500 pts)",
                                    self, ISEnchantBackpackUI.onClick)
    self.enchantButton:initialise()
    self.enchantButton:instantiate()
    self.enchantButton.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    self.enchantButton.font = UIFont.Medium
    self:addChild(self.enchantButton)

    -- Status text - simple text display
    self.statusText = "Ready to enchant"
    self.statusColor = {r=1, g=1, b=1}

    -- Add protection checkbox (always start unchecked)
    self.protectionCheckbox = ISTickBox:new(self.width/2 - 100, 280, 200, 20, "", self, ISEnchantBackpackUI.onToggleProtection)
    self.protectionCheckbox:initialise()
    self.protectionCheckbox:instantiate()
    self.protectionCheckbox:addOption("Enable Enchant Protection (+10000 pts)")
    -- Force it to be unchecked regardless of flag state
    self.protectionCheckbox:setSelected(1, false)
    self.protectionCheckbox.tooltip = "Protection prevents backpack breakage on negative enchantment, but costs 10,000 extra points"
    self:addChild(self.protectionCheckbox)

    -- Close button
    self.closeButton = ISButton:new(self.width - btnWid - 10, self.height - btnHgt - 10,
                                  btnWid, btnHgt, "Close", self, ISEnchantBackpackUI.onClick)
    self.closeButton.internal = "CLOSE"
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self.closeButton.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    self.closeButton.font = UIFont.Medium
    self:addChild(self.closeButton)
    self.enchantResult = nil
end

function ISEnchantBackpackUI:onToggleProtection(index, selected)
    PlayerFlagHandler.giveFlag("backpackEnchantProtection", selected)
    self:updateEnchantButton()
end

function ISEnchantBackpackUI:updateEnchantButton()
    -- Remove old button if it exists
    if self.enchantButton then
        self:removeChild(self.enchantButton)
    end

    -- Button dimensions (same as in createChildren)
    local btnWid = 120
    local btnHgt = FONT_HGT_MEDIUM + 6

    -- Get current protection status and calculate cost
    local hasProtection = PlayerFlagHandler.getFlag("backpackEnchantProtection") or false
    local cost = hasProtection and 12500 or 2500

    -- Create new button with updated text
    self.enchantButton = ISButton:new(self.width/2 - btnWid/2, 150,
                                    btnWid, btnHgt, "Pay (" .. cost .. " pts)",
                                    self, ISEnchantBackpackUI.onClick)
    self.enchantButton:initialise()
    self.enchantButton:instantiate()
    self.enchantButton.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    self.enchantButton.font = UIFont.Medium
    self:addChild(self.enchantButton)
end

-- Helper function to rename backpacks after enchantment
function ISEnchantBackpackUI:renameEnchantedBackpack(backpack, username, isPositive)
    if not backpack then return end

    -- Initialize ModData for enchantment tracking if needed
    if not backpack:getModData().enchantmentStats then
        backpack:getModData().enchantmentStats = {
            enchantCounter = 0,
            originalName = backpack:getName(),
            originalCapacity = backpack:getCapacity(),
            originalWeightReduction = backpack:getWeightReduction()
        }
    end

    -- Get original name or current base name
    local baseName = backpack:getModData().enchantmentStats.originalName

    -- Update enchant counter (increment for positive, decrement for negative)
    -- Respect the +10/-10 limits
    if isPositive then
        if backpack:getModData().enchantmentStats.enchantCounter < 10 then
            backpack:getModData().enchantmentStats.enchantCounter = backpack:getModData().enchantmentStats.enchantCounter + 1
        end
    else
        if backpack:getModData().enchantmentStats.enchantCounter > -10 then
            backpack:getModData().enchantmentStats.enchantCounter = backpack:getModData().enchantmentStats.enchantCounter - 1
        end
    end

    -- Get current counter value
    local counter = backpack:getModData().enchantmentStats.enchantCounter

    -- Rename based on counter value
    if counter > 0 then
        -- Positive enchantment level
        backpack:setName(baseName .. "_" .. username .. "_+" .. counter)
    elseif counter < 0 then
        -- Negative enchantment level (use absolute value for display)
        backpack:setName(baseName .. "_" .. username .. "_-" .. math.abs(counter))
    else
        -- Counter is zero - reset to original name
        backpack:setName(baseName)
    end

    print("DEBUG: Backpack renamed to: " .. backpack:getName())
    return counter
end

-------------------------------------------- ON CLICK FUNCTION --------------------------------------------

function ISEnchantBackpackUI:onClick(button)
    local backpackIDExists = false
    local serverEnchantLevel = 20
    if button.internal == "CLOSE" then
        self:close()
        return
    end

    -- Get player and backpack with proper validation
    local player = getSpecificPlayer(0)
    if not player then
        self.statusText = "Error: Player not found"
        self.statusColor = {r=1, g=0.3, b=0.3}
        return
    end

    -- Get the backpack from player's equipped location or inventory
    local backpack = self:getEquippedBackpack(player)
    if not backpack then
        self.statusText = "No backpack equipped!"
        self.statusColor = {r=1, g=0.3, b=0.3}
        return
    end

    local backpackID = backpack:getID()
    local backpackName = backpack:getName() or ""

    -- Set UI status to "checking"
    self.statusText = "Checking backpack database..."
    self.statusColor = {r=0.7, g=0.7, b=0.7}

    -- Send request to server to check if this backpack exists in the database
    sendClientCommand("EnchantBackpack", "checkEnchantedBackpack", {
        backpackID = backpackID,
        backpackName = backpackName
    })

    -- Store callback for when server responds
    _G.PendingBackpackChecks[backpackID] = function(isFound, isBroken, data)
        -- If the backpack is found and is broken, update UI and backpack
        print("DEBUG: Backpack check result - Found: " .. tostring(isFound) .. ", Broken: " .. tostring(isBroken))

        if data then
            backpackIDExists = true
            if data.metadata and data.metadata.enchantLevel then
                serverEnchantLevel = data.metadata.enchantLevel or 20
            end
            print("DEBUG: Backpack check data - " .. tostring(data))
        end

        if isFound and isBroken then
            print("DEBUG: Backpack is Found and Broken")
            self.statusText = "Found broken backpack in database with the same ID!"
            self.statusColor = {r=1, g=0.3, b=0.3}

            -- Set condition to 0 if not already
            if backpack:getCondition() > 0 then
                backpack:setCondition(0)
                player:Say("Awh no! My backpack tore apart!")
            end
            return
        end

        -- Continue with normal enchantment flow if the backpack isn't broken
        self:continueEnchantment(backpack, player, backpackIDExists, serverEnchantLevel)
    end
end

-- Helper function to get equipped backpack
function ISEnchantBackpackUI:getEquippedBackpack(player)
    local backpack = player:getClothingItem_Back()
    if backpack and self:isBackpack(backpack) then
        return backpack
    end

    -- Check inventory for backpacks if none equipped
    local inventory = player:getInventory()
    local items = inventory:getItems()
    for i = 0, items:size()-1 do
        local item = items:get(i)
        if item and self:isBackpack(item) then
            return item
        end
    end

    return nil
end

-- Helper function to check if an item is a backpack
function ISEnchantBackpackUI:isBackpack(item)
    if not item then return false end

    -- Check if it's a container
    if item:getCategory() ~= "Container" then return false end

    -- Check capacity - backpacks typically have capacity > 5
    if item:getCapacity() <= 5 then return false end

    -- Exclude items that shouldn't be considered backpacks
    local excludedTypes = {
        "Toolbox", "FirstAidKit", "PillBox", "Lunchbox", "Cooler"
    }

    for _, excludedType in ipairs(excludedTypes) do
        if string.find(item:getType(), excludedType) then
            return false
        end
    end

    return true
end

-- Extract the rest of the enchantment logic to a separate function
function ISEnchantBackpackUI:continueEnchantment(backpack, player, backpackIDExists, serverEnchantLevel)
    local backpackName = backpack:getName() or ""
    if string.find(backpackName, "Broken") then
        self.statusText = "Backpack is broken!"
        self.statusColor = {r=1, g=0.3, b=0.3}
        return
    end

    -- Check if backpack exists
    if not self:isBackpack(backpack) then
        self.statusText = "No valid backpack selected!"
        self.statusColor = {r=1, g=0.3, b=0.3}
        return
    end

    -- Check if backpack is already at maximum enchantment level (+10)
    if backpack:getModData() and backpack:getModData().enchantmentStats and
       backpack:getModData().enchantmentStats.enchantCounter == 10 then
        self.statusText = "Backpack is too fragile for further enchantment (+10)!"
        self.statusColor = {r=1, g=0.6, b=0.1}
        return
    end

    -- Get username for points check and payment
    local username = player:getUsername() or "Player"
    local hasProtection = PlayerFlagHandler.getFlag("backpackEnchantProtection") or false
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
    if backpack:getModData() and backpack:getModData().enchantmentStats then
        enchantLevel = backpack:getModData().enchantmentStats.enchantCounter or 0
    end
    local absLevel = math.abs(enchantLevel)

    -- Determine enchantment cap based on absolute enchantment level
    local enchantCap = 0.05 -- Base cap is 5%
    if absLevel >= 3 and absLevel < 5 then
        enchantCap = 0.10 -- 10% for +3 to +4
    elseif absLevel >= 5 and absLevel < 7 then
        enchantCap = 0.15 -- 15% for +5 to +6
    elseif absLevel >= 7 then
        enchantCap = 0.20 -- 20% for +7 and beyond
    end

    print(tostring(backpackIDExists) .. " ---- " .. tostring(serverEnchantLevel) .. " ---- " .. tostring(absLevel))
    if backpackIDExists and serverEnchantLevel ~= enchantLevel and serverEnchantLevel ~= 20 then
        print("DEBUG: Backpack ID exists on server, but enchantment level differs")
        return
    end

    -- Deduct points
    GlobalMethods.takePlayerPoints(username, pointCost)

    -- Perform enchantment logic on the client
    local isPositive = ZombRand(10) < 6 -- 60% chance of positive outcome

    ---- ENCHANTMENT BREAKAGE CHECKS BASED ON LEVEL ----
    if enchantLevel == 6 then
        isPositive = ZombRand(10) < 4 -- 40% chance at +6
    elseif enchantLevel == 7 then
        isPositive = ZombRand(10) <= 3 -- 30% chance at +7
    elseif enchantLevel == 8 then
        isPositive = ZombRand(10) <= 2 -- 20% chance at +8
    elseif enchantLevel == 9 then
        isPositive = ZombRand(10) <= 1 -- 10% chance at +9
    end

    -- Get the random enhancement amount (1-20)
    local enchantRoll = ZombRand(1, 21) / 100 -- Convert to percentage (0.01 to 0.20)

    -- Apply the dynamic cap based on enchantment level
    local enchantChange = math.min(enchantRoll, enchantCap)

    -- Store original values for UI display
    local origCapacity = backpack:getCapacity()
    local origWeightReduction = backpack:getWeightReduction()

    -- Apply changes to capacity and weight reduction
    if isPositive then
        -- Positive outcome: increase both stats
        local newCapacity = origCapacity * (1 + enchantChange)
        local newWeightReduction = math.min(origWeightReduction + (enchantChange * 100), 95) -- Cap at 95%
        backpack:setCapacity(newCapacity)
        backpack:setWeightReduction(newWeightReduction)
    else
        -- Negative outcome: decrease both stats and check for enchant protection
        if absLevel >= 7 then
            local isEnchantProtection = PlayerFlagHandler.getFlag("backpackEnchantProtection")
            if not isEnchantProtection then
                -- Break the backpack if no protection
                self:breakBackpack(backpack)

                sendClientCommand("EnchantBackpack", "trackEnchantedBackpack", {
                    backpackID = backpackID,
                    backpackName = backpackName,
                    enchantLevel = enchantLevel,
                    isBroken = true
                })
            else
                -- Just decrease stats if protected
                local newCapacity = origCapacity * (1 - enchantChange)
                local newWeightReduction = math.max(origWeightReduction - (enchantChange * 100), 0)
                backpack:setCapacity(newCapacity)
                backpack:setWeightReduction(newWeightReduction)
            end
        else
            -- Normal negative enchantment
            sendClientCommand("EnchantBackpack", "trackEnchantedBackpack", {
                backpackID = backpackID,
                backpackName = backpackName,
                enchantLevel = enchantLevel,
                isBroken = false
            })

            local newCapacity = origCapacity * (1 - enchantChange)
            local newWeightReduction = math.max(origWeightReduction - (enchantChange * 100), 0)
            backpack:setCapacity(newCapacity)
            backpack:setWeightReduction(newWeightReduction)
        end
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

    -- Rename backpack based on enchantment outcome
    local newLevel = self:renameEnchantedBackpack(backpack, username, isPositive)

    -- Store enchantment result for UI
    self.enchantResult = {
        isPositive = isPositive,
        enchantRoll = enchantRoll * 100, -- Convert to percentage for display
        enchantChange = enchantChange * 100, -- Convert to percentage for display
        enchantCap = enchantCap * 100, -- Convert to percentage for display
        enchantLevel = newLevel,
        newCapacity = math.floor(backpack:getCapacity() * 100) / 100,
        newWeightReduction = math.floor(backpack:getWeightReduction() * 100) / 100,
        origCapacity = math.floor(origCapacity * 100) / 100,
        origWeightReduction = math.floor(origWeightReduction * 100) / 100
    }

    -- Update status text showing changes
    if isPositive then
        self.statusText = "Success! Backpack capacity increased (Cap: " .. (enchantCap * 100) .. "%)"
        self.statusColor = {r=0.3, g=1, b=0.3}
    else
        self.statusText = "Caution! Backpack capacity decreased (Cap: " .. (enchantCap * 100) .. "%)"
        self.statusColor = {r=1, g=0.5, b=0.2}
    end

    -- Save values for persistence
    if not backpack:getModData().savedBackpackValues then
        backpack:getModData().savedBackpackValues = {}
    end
    backpack:getModData().savedBackpackValues.capacity = backpack:getCapacity()
    backpack:getModData().savedBackpackValues.weightReduction = backpack:getWeightReduction()

    -- Sync changes to the server
    sendClientCommand("EnchantBackpack", "syncEnchantment", {
        backpackID = backpack:getID(),
        isPositive = isPositive,
        enchantRoll = enchantRoll,
        enchantChange = enchantChange,
        enchantCap = enchantCap,
        enchantLevel = newLevel,
        capacity = backpack:getCapacity(),
        weightReduction = backpack:getWeightReduction()
    })

    print("DEBUG: Backpack enchantment applied and synced to server")
end

-- Helper function to break a backpack
function ISEnchantBackpackUI:breakBackpack(backpack)
    if not backpack then return end

    -- Set condition to 0
    backpack:setCondition(0)

    -- Drastically reduce capacity and weight reduction
    backpack:setCapacity(backpack:getCapacity() * 0.1) -- Reduce to 10%
    backpack:setWeightReduction(0) -- No weight reduction

    -- Rename to indicate it's broken
    local currentName = backpack:getName()
    if not string.find(currentName, "Broken") then
        backpack:setName("Broken " .. currentName)
    end

    -- Get player to say something
    local player = getSpecificPlayer(0)
    if player then
        player:Say("My backpack tore apart!")
    end
end

-- Draw UI with enhanced backpack status info
function ISEnchantBackpackUI:prerender()
    local hasProtection = PlayerFlagHandler.getFlag("backpackEnchantProtection") or false
    -- Draw background
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    -- Draw title
    local title = "MangEwok's Backpack Enchanting"
    self:drawText(title, self.width/2 - getTextManager():MeasureStringX(UIFont.Medium, title)/2, 10, 1, 1, 1, 1, UIFont.Medium)

    -- Adjusted backpack info panel position
    self:drawRectBorder(20, 40, self.width - 40, 110, 0.5, 0.4, 0.4, 0.4)
    self:drawRect(21, 41, self.width - 42, 108, 0.3, 0.05, 0.05, 0.05)

    -- Draw backpack info
    local player = getSpecificPlayer(0)
    if player then
        local backpack = self:getEquippedBackpack(player)
        if backpack and self:isBackpack(backpack) then
            local name = backpack:getName() or "Unknown Backpack"

            -- Adjusted backpack info positions
            local backpackInfoY = 50
            self:drawText(name, self.width/2 - getTextManager():MeasureStringX(UIFont.Medium, name)/2, backpackInfoY, 1, 0.9, 0.7, 1, UIFont.Medium)

            -- Get backpack stats
            local capacity = backpack:getCapacity() or 0
            local weightReduction = backpack:getWeightReduction() or 0
            local condition = backpack:getCondition() or 0
            local maxCondition = backpack:getConditionMax() or 100
            local conditionPercent = math.floor((condition / maxCondition) * 100)
            local backpackType = backpack:getType() or "Unknown Type"

            -- Format values to one decimal place
            capacity = math.floor(capacity * 10) / 10
            weightReduction = math.floor(weightReduction * 10) / 10

            -- Left column stats
            -- Highlight capacity if it was changed in the last enchantment
            local capacityColor = {r=0.9, g=0.9, b=0.9}
            if self.enchantResult then
                if self.enchantResult.isPositive then
                    capacityColor = {r=0.3, g=1, b=0.3} -- Green for positive
                else
                    capacityColor = {r=1, g=0.3, b=0.3} -- Red for negative
                end
            end
            backpackInfoY = backpackInfoY + FONT_HGT_SMALL + 10
            self:drawText("Capacity: " .. capacity, 30, backpackInfoY, capacityColor.r, capacityColor.g, capacityColor.b, 1, UIFont.Small)

            -- Highlight weight reduction if it was changed in the last enchantment
            local weightColor = {r=0.9, g=0.9, b=0.9}
            if self.enchantResult then
                if self.enchantResult.isPositive then
                    weightColor = {r=0.3, g=1, b=0.3} -- Green for positive
                else
                    weightColor = {r=1, g=0.3, b=0.3} -- Red for negative
                end
            end
            backpackInfoY = backpackInfoY + FONT_HGT_SMALL + 2
            self:drawText("Weight Reduction: " .. weightReduction .. "%", 30, backpackInfoY, weightColor.r, weightColor.g, weightColor.b, 1, UIFont.Small)

            backpackInfoY = backpackInfoY + FONT_HGT_SMALL + 2
            self:drawText("Type: " .. backpackType, 30, backpackInfoY, 0.9, 0.9, 0.9, 1, UIFont.Small)

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
            local enchanted = backpack:getModData() and backpack:getModData().enchantmentStats and
                             backpack:getModData().enchantmentStats.enchantCounter ~= 0
            if enchanted then
                local enchantLevel = backpack:getModData().enchantmentStats.enchantCounter
                local enchantText = "Enchantment Level: " .. (enchantLevel > 0 and "+" or "") .. enchantLevel
                local enchantTextWidth = getTextManager():MeasureStringX(UIFont.Small, enchantText)
                self:drawText(enchantText, self.width - enchantTextWidth - 30, rightColumnY, 0.5, 0.7, 1, 1, UIFont.Small)
            else
                local notEnchantedText = "Not Enchanted"
                local notEnchantedWidth = getTextManager():MeasureStringX(UIFont.Small, notEnchantedText)
                self:drawText(notEnchantedText, self.width - notEnchantedWidth - 30, rightColumnY, 0.6, 0.6, 0.6, 1, UIFont.Small)
            end

        else
            self:drawText("No backpack equipped", self.width/2 - getTextManager():MeasureStringX(UIFont.Medium, "No backpack equipped")/2, 70, 0.7, 0.7, 0.7, 1, UIFont.Medium)
            self:drawText("Equip a backpack or have one in inventory", self.width/2 - getTextManager():MeasureStringX(UIFont.Small, "Equip a backpack or have one in inventory")/2, 90, 0.6, 0.6, 0.6, 1, UIFont.Small)
        end
    end

    -- Adjusted enchantment info position
    local enchantInfoY = 180
    self:drawText("Enchant your backpack - roll the dice!",
                self.width/2 - getTextManager():MeasureStringX(UIFont.Small, "Enchant your backpack - roll the dice!")/2,
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
    self:drawText("Improves Capacity & Weight Reduction - 60% Success Chance",
                self.width/2 - getTextManager():MeasureStringX(UIFont.Small, "Improves Capacity & Weight Reduction - 60% Success Chance")/2,
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
    if self.enchantResult then
        local resultY = priceInfoY + 50
        local changeText = self.enchantResult.isPositive and "increased" or "decreased"
        local changeAmount = math.floor(self.enchantResult.enchantChange * 100) / 100

        local resultText = "Last roll: Capacity " .. changeText .. " by " .. changeAmount .. "%"
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
function ISEnchantBackpackUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    _G.BackpackEnchantingUI = nil
end

function ISEnchantBackpackUI:new(x, y, width, height)
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

-- Function to restore saved backpack values (call on equip)
function onEquipBackpack(player, item)
    if not item then return end

    -- Check if it's a backpack by our definition
    if not ISEnchantBackpackUI:isBackpack(item) then return end

    -- Check if this backpack has enchantment data
    if item:getModData() and item:getModData().savedBackpackValues then
        -- Get the stored values from ModData if they exist
        local savedCapacity = item:getModData().savedBackpackValues.capacity
        local savedWeightReduction = item:getModData().savedBackpackValues.weightReduction

        -- Reapply the enchanted values
        if savedCapacity and savedWeightReduction then
            item:setCapacity(savedCapacity)
            item:setWeightReduction(savedWeightReduction)
            print("[ZM_Mungkah] Restored enchanted backpack values for: " .. item:getName())
        end
    end
end

-- Register equip event
Events.OnClothingUpdated.Add(function(player)
    local backpack = player:getClothingItem_Back()
    if backpack then
        onEquipBackpack(player, backpack)
    end
end)

-- Register game start event to restore values
Events.OnGameStart.Add(function()
    local player = getSpecificPlayer(0)
    if player then
        local backpack = player:getClothingItem_Back()
        if backpack then
            onEquipBackpack(player, backpack)
        end
    end
end)

_G.BackpackEnchantingUI = _G.BackpackEnchantingUI or nil

function showEnchantBackpackUI()
    if _G.BackpackEnchantingUI and _G.BackpackEnchantingUI:isVisible() then
        return _G.BackpackEnchantingUI
    end

    local ui = ISEnchantBackpackUI:new(
        (getCore():getScreenWidth() / 2) - 250,
        (getCore():getScreenHeight() / 2) - 150,
        500,
        370
    )

    ui:initialise()
    ui:addToUIManager()
    _G.BackpackEnchantingUI = ui

    return ui
end

if not _G.ZM_Commands then _G.ZM_Commands = {} end
_G.ZM_Commands.ShowEnchantBackpackUI = showEnchantBackpackUI

-- For console/debug access
_G.OpenEnchantBackpackUI = showEnchantBackpackUI

print("[ZM_Mungkah] Backpack Enchantment UI loaded")