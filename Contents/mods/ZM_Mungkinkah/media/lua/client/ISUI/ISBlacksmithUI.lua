--***********************************************************
--**                    BLACKSMITH UI                      **
--***********************************************************

ISBlacksmithUI = ISPanel:derive("ISBlacksmithUI")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

if not getBlacksmithUIInstance then
    require('shared/BlacksmithUtils')
end

BlacksmithUI = getBlacksmithUIInstance()

function ISBlacksmithUI:initialise()
    ISPanel.initialise(self)
end

function ISBlacksmithUI:createChildren()
    ISPanel.createChildren(self)

    -- Close button
    local btnWid = 100
    local btnHgt = FONT_HGT_MEDIUM + 6 -- Larger button height

    -- Add items list with LARGER size
    self.itemList = ISScrollingListBox:new(20, 70, self.width - 40, self.height - 120) -- Increased margins and taller list
    self.itemList:initialise()
    self.itemList:instantiate()
    self.itemList.itemheight = 50 -- Much taller items for better readability
    self.itemList.selected = 0
    self.itemList.joypadParent = self
    self.itemList.font = UIFont.Medium -- Larger font
    self.itemList.drawBorder = true
    self.itemList.doDrawItem = self.drawItemEntry -- Custom drawing function
    self:addChild(self.itemList)

    -- Add items with enhanced details
    self.itemList:addItem("Iron Axe", {
        name = "Iron Axe",
        level = 3,
        mainMaterials = "Iron ×10, Wood ×2",
        tools = {"Hammer", "Anvil"},
        skills = {{"Metalworking", 3}},
        timeNeeded = 300,
        resultCount = 1,
        description = "A sturdy axe made of iron. Useful for chopping wood and self-defense."
    })

    self.itemList:addItem("Iron Pipe", {
        name = "Iron Pipe",
        level = 1,
        mainMaterials = "Iron ×5",
        tools = {"Hammer", "Anvil"},
        skills = {{"Metalworking", 1}},
        timeNeeded = 150,
        resultCount = 1,
        description = "A simple iron pipe. Can be used as a weapon or in other crafting recipes."
    })

    self.itemList:addItem("Metal Sheet", {
        name = "Metal Sheet",
        level = 2,
        mainMaterials = "Iron ×8",
        tools = {"Hammer", "Anvil"},
        skills = {{"Metalworking", 2}},
        timeNeeded = 200,
        resultCount = 1,
        description = "A flat sheet of metal. Essential in building and crafting sturdier structures."
    })

    self.itemList:addItem("Metal Door", {
        name = "Metal Door",
        level = 5,
        mainMaterials = "Iron ×20, Hinge ×2",
        tools = {"Hammer", "Anvil", "Welding Mask"},
        skills = {{"Metalworking", 5}, {"Carpentry", 2}},
        timeNeeded = 600,
        resultCount = 1,
        description = "A sturdy metal door that provides excellent protection against zombies."
    })

    -- Close button (larger)
    self.closeButton = ISButton:new(self.itemList.x + self.itemList.width - btnWid - 10, self.itemList.y + self.itemList.height + 10, btnWid, btnHgt, "Close", self, ISBlacksmithUI.onClick)
    self.closeButton.internal = "CLOSE"
    self.closeButton.anchorTop = false
    self.closeButton.anchorBottom = true
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self.closeButton.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    self.closeButton.font = UIFont.Medium -- Larger font
    self:addChild(self.closeButton)

    -- Craft button (larger)
    self.craftButton = ISButton:new(self.itemList.x, self.itemList.y + self.itemList.height + 10, btnWid, btnHgt, "Craft", self, ISBlacksmithUI.onClick)
    self.craftButton.internal = "CRAFT"
    self.craftButton.anchorTop = false
    self.craftButton.anchorBottom = true
    self.craftButton:initialise()
    self.craftButton:instantiate()
    self.craftButton.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    self.craftButton.font = UIFont.Medium -- Larger font
    self:addChild(self.craftButton)
end

-- Custom function to draw each item entry with more details (LARGER)
function ISBlacksmithUI:drawItemEntry(y, item, alt)
    local a = 0.9
    local height = self.itemheight

    -- Draw background and selection highlight
    self:drawRectBorder(0, y, self:getWidth(), height, a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), height, 0.3, 0.7, 0.35, 0.15)
    end

    -- Draw item name (larger font and position)
    self:drawText(item.item.name, 15, y + 6, 1, 1, 1, a, UIFont.Medium)

    -- Draw required level with larger font and better position
    local levelText = "Level: " .. item.item.level
    local player = getSpecificPlayer(0)
    local playerSkillLevel = 0

    -- Check if we can get the player's skill level
    if player then
        -- Try to get metalworking skill if perk exists
        local metalworkingPerk = Perks.MetalWelding or Perks.Metalworking
        if metalworkingPerk then
            playerSkillLevel = player:getPerkLevel(metalworkingPerk)
        end
    end

    local levelColor = {r=1, g=0.3, b=0.3} -- Red by default (not enough skill)

    if playerSkillLevel >= item.item.level then
        levelColor = {r=0.3, g=1, b=0.3} -- Green (sufficient skill)
    elseif playerSkillLevel >= item.item.level - 1 then
        levelColor = {r=1, g=1, b=0.3} -- Yellow (close to required skill)
    end

    self:drawText(levelText, self:getWidth() - 120, y + 6, levelColor.r, levelColor.g, levelColor.b, a, UIFont.Medium)

    -- Draw materials (second line)
    self:drawText("Materials: " .. item.item.mainMaterials, 15, y + 28, 0.8, 0.8, 0.8, a, UIFont.Small)

    -- Create enhanced tooltip with full details (will show on hover) - LARGER
    local tooltip = "<SIZE:large><RGB:1,1,1>" .. item.item.name .. "</RGB></SIZE>\n\n"

    -- Level with proper color
    local levelColor = "1,0.3,0.3" -- Red by default
    if playerSkillLevel >= item.item.level then
        levelColor = "0.3,1,0.3" -- Green
    elseif playerSkillLevel >= item.item.level - 1 then
        levelColor = "1,1,0.3" -- Yellow
    end
    tooltip = tooltip .. "<SIZE:medium><RGB:1,1,1>Required Level: </RGB><RGB:" .. levelColor .. ">" .. item.item.level .. "</RGB></SIZE>\n"

    -- Materials
    tooltip = tooltip .. "<SIZE:medium><RGB:1,1,1>Required Materials: </RGB><RGB:0.8,0.8,0.8>" .. item.item.mainMaterials .. "</RGB></SIZE>\n"

    -- Tools
    if item.item.tools and #item.item.tools > 0 then
        tooltip = tooltip .. "<SIZE:medium><RGB:1,1,1>Required Tools: </RGB><RGB:0.8,0.8,0.8>" .. table.concat(item.item.tools, ", ") .. "</RGB></SIZE>\n"
    end

    -- Skills
    if item.item.skills and #item.item.skills > 0 then
        tooltip = tooltip .. "<SIZE:medium><RGB:1,1,1>Required Skills: </RGB><RGB:0.8,0.8,0.8>"
        for i, skill in ipairs(item.item.skills) do
            tooltip = tooltip .. skill[1] .. " (" .. skill[2] .. ")"
            if i < #item.item.skills then tooltip = tooltip .. ", " end
        end
        tooltip = tooltip .. "</RGB></SIZE>\n"
    end

    -- Time
    if item.item.timeNeeded then
        local minutes = math.floor(item.item.timeNeeded / 60)
        tooltip = tooltip .. "<SIZE:medium><RGB:1,1,1>Crafting Time: </RGB><RGB:0.8,0.8,0.8>" .. minutes .. " minutes</RGB></SIZE>\n"
    end

    -- Description
    if item.item.description then
        tooltip = tooltip .. "\n<SIZE:medium><RGB:0.9,0.9,0.7>" .. item.item.description .. "</RGB></SIZE>"
    end

    item.tooltip = tooltip

    return y + height
end

function ISBlacksmithUI:prerender()
    local z = 20
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self:drawText("Blacksmith Recipes", self.width / 2 - (getTextManager():MeasureStringX(UIFont.Large, "Blacksmith Recipes") / 2), z, 1, 1, 1, 1, UIFont.Large)
end

function ISBlacksmithUI:onClick(button)
    if button.internal == "CLOSE" then
        self:close()
    elseif button.internal == "CRAFT" then
        local selected = self.itemList.items[self.itemList.selected]
        if selected then
            -- Here you would implement the crafting logic
            print("Crafting " .. selected.item.name)
        end
    end
end

function ISBlacksmithUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    BlacksmithUI.isVisible = false
    ISBlacksmithUI.instance = nil
    if self.onClose then
        self:onClose()
    end
end

function ISBlacksmithUI:new(x, y, width, height, onClose)
    local o = {}
    -- Create a MUCH larger UI window
    o = ISPanel:new(x, y, width * 1.5, height * 1.5) -- 50% larger in both dimensions
    setmetatable(o, self)
    self.__index = self
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.width = width * 1.5
    o.height = height * 1.5
    o.player = getSpecificPlayer(0)
    o.moveWithMouse = true
    o.onClose = onClose
    ISBlacksmithUI.instance = o
    return o
end

return BlacksmithUI