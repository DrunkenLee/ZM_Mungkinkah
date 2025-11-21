--***********************************************************
--**               AUCTION CREATE UI (CLIENT)              **
--***********************************************************
-- Simple panel to create an auction from:
-- 1) Item in primary hand
-- 2) Currently equipped item in a chosen body location
-- Provides inputs for starting price, buyout price, duration

require "ISUI/ISPanel"

ISAuctionCreateUI = ISPanel:derive("ISAuctionCreateUI")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function ISAuctionCreateUI:initialise()
    ISPanel.initialise(self)

    local pad = 10
    local lineH = FONT_HGT_SMALL + 4
    local y = pad

    self.title = ISLabel:new(pad, y, lineH, "Create Auction", 1,1,1,1, UIFont.Small, true)
    self:addChild(self.title)
    y = y + lineH + 4

    -- Starting Price
    self.startingLabel = ISLabel:new(pad, y, lineH, "Starting Price:", 1,1,1,1, UIFont.Small, true)
    self:addChild(self.startingLabel)
    self.startingEntry = ISTextEntryBox:new("100", pad+110, y-2, 80, lineH+2)
    self.startingEntry:initialise(); self.startingEntry:instantiate()
    self.startingEntry:setOnlyNumbers(true)
    self:addChild(self.startingEntry)
    y = y + lineH + 4

    -- Buyout Price
    self.buyoutLabel = ISLabel:new(pad, y, lineH, "Buyout Price:", 1,1,1,1, UIFont.Small, true)
    self:addChild(self.buyoutLabel)
    self.buyoutEntry = ISTextEntryBox:new("200", pad+110, y-2, 80, lineH+2)
    self.buyoutEntry:initialise(); self.buyoutEntry:instantiate()
    self.buyoutEntry:setOnlyNumbers(true)
    self:addChild(self.buyoutEntry)
    y = y + lineH + 4

    -- Duration Hours
    self.durationLabel = ISLabel:new(pad, y, lineH, "Duration (hrs):", 1,1,1,1, UIFont.Small, true)
    self:addChild(self.durationLabel)
    self.durationEntry = ISTextEntryBox:new("24", pad+110, y-2, 80, lineH+2)
    self.durationEntry:initialise(); self.durationEntry:instantiate()
    self.durationEntry:setOnlyNumbers(true)
    self:addChild(self.durationEntry)
    y = y + lineH + 8

    -- Body location dropdown for equipped items
    self.bodyLocLabel = ISLabel:new(pad, y, lineH, "Body Location:", 1,1,1,1, UIFont.Small, true)
    self:addChild(self.bodyLocLabel)
    self.bodyLocations = {"PrimaryHand", "SecondaryHand", "Head", "Torso", "Back", "Belt"}
    self.bodyLocCombo = ISComboBox:new(pad+110, y-2, 120, lineH+6, self, nil)
    for _,loc in ipairs(self.bodyLocations) do
        self.bodyLocCombo:addOption(loc)
    end
    self.bodyLocCombo.selected = 1
    self:addChild(self.bodyLocCombo)
    y = y + lineH + 10

    -- Buttons
    local btnH = 22
    self.btnFromHand = ISButton:new(pad, y, 110, btnH, "From Hand", self, ISAuctionCreateUI.onClick)
    self.btnFromHand.internal = "HAND"
    self:addChild(self.btnFromHand)

    self.btnFromEquipped = ISButton:new(pad+120, y, 120, btnH, "From Equipped", self, ISAuctionCreateUI.onClick)
    self.btnFromEquipped.internal = "EQUIPPED"
    self:addChild(self.btnFromEquipped)

    self.btnClose = ISButton:new(self.width - pad - 60, self.height - pad - btnH, 60, btnH, "Close", self, ISAuctionCreateUI.onClick)
    self.btnClose.internal = "CLOSE"
    self:addChild(self.btnClose)
end

function ISAuctionCreateUI:prerender()
    ISPanel.prerender(self)
    self:drawRect(0,0,self.width,self.height,0.8,0,0,0)
    self:drawRectBorder(1,1,self.width-2,self.height-2,0.9,1,1,1)
end

function ISAuctionCreateUI:onClick(button)
    if button.internal == "CLOSE" then
        self:close()
        return
    end

    local startingPrice = tonumber(self.startingEntry:getText()) or 1
    local buyoutPrice = tonumber(self.buyoutEntry:getText()) or (startingPrice * 2)
    local duration = tonumber(self.durationEntry:getText()) or 24

    if buyoutPrice < startingPrice then
        getPlayer():Say("Buyout must be >= starting price")
        return
    end

    if button.internal == "HAND" then
        if AuctionHandler then
            local ok = AuctionHandler.createAuctionFromHand(startingPrice, buyoutPrice, duration)
            if ok then self:close() end
        end
    elseif button.internal == "EQUIPPED" then
        local loc = self.bodyLocCombo.options[self.bodyLocCombo.selected].text
        if AuctionHandler then
            -- Map generic locations to actual body slots if needed
            local mapped = loc
            if loc == "PrimaryHand" then
                -- we use the currently primary hand item
                local player = getPlayer()
                local item = player and player:getPrimaryHandItem()
                if not item then
                    player:Say("Nothing in primary hand")
                    return
                end
                print("[DEBUG] PrimaryHand item: " .. tostring(item:getDisplayName()) .. ", Starting: " .. tostring(startingPrice) .. ", Buyout: " .. tostring(buyoutPrice) .. ", Duration: " .. tostring(duration))
                local ok = AuctionHandler.createAuctionListing(item, startingPrice, buyoutPrice, duration)
                print("[DEBUG] Auction from primary hand result: " .. tostring(ok))
                if ok then self:close() end
                return
            elseif loc == "SecondaryHand" then
                -- we use the currently secondary hand item
                local player = getPlayer()
                local item = player and player:getSecondaryHandItem()
                if not item then
                    player:Say("Nothing in secondary hand")
                    return
                end
                print("[DEBUG] SecondaryHand item: " .. tostring(item:getDisplayName()) .. ", Starting: " .. tostring(startingPrice) .. ", Buyout: " .. tostring(buyoutPrice) .. ", Duration: " .. tostring(duration))
                local ok = AuctionHandler.createAuctionListing(item, startingPrice, buyoutPrice, duration)
                print("[DEBUG] Auction from secondary hand result: " .. tostring(ok))
                if ok then self:close() end
                return
            end
            -- For other body locations attempt direct fetch

            print("[DEBUG] Mapped location: " .. tostring(mapped) .. ", Starting: " .. tostring(startingPrice) .. ", Buyout: " .. tostring(buyoutPrice) .. ", Duration: " .. tostring(duration))
            local ok = AuctionHandler.createAuctionFromEquipped(mapped, startingPrice, buyoutPrice, duration)
            print("[DEBUG] Auction from equipped result: " .. tostring(ok))
            if ok then self:close() end
        end
    end
end

function ISAuctionCreateUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    ISAuctionCreateUI.instance = nil
end

function ISAuctionCreateUI.open()
    if ISAuctionCreateUI.instance then
        ISAuctionCreateUI.instance:setVisible(true)
        return ISAuctionCreateUI.instance
    end

    local w,h = 320, 260
    local x = getCore():getScreenWidth() / 2 - w/2
    local y = getCore():getScreenHeight() / 2 - h/2
    local o = ISAuctionCreateUI:new(x,y,w,h)
    o:initialise()
    o:addToUIManager()
    ISAuctionCreateUI.instance = o
    return o
end

function ISAuctionCreateUI:new(x,y,w,h)
    local o = ISPanel:new(x,y,w,h)
    setmetatable(o, self)
    self.__index = self
    o.moveWithMouse = true
    return o
end

return ISAuctionCreateUI
