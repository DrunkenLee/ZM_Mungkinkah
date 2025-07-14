-- Context Menu for Mystic Orb Binding
local ZM_MysticOrb = {}

-- Global counter for orb IDs - simpler than using getGameTime()
ZM_MysticOrb.orbCounter = 0

-- Function to handle the "Bind it to my weapon" action
function ZM_MysticOrb.BindToWeapon(playerObj, item)
    -- Fix the player parameter - convert from index to object if needed
    local player = playerObj
    if type(playerObj) == "number" then
        player = getSpecificPlayer(playerObj)
    end

    if not player then
        print("ERROR: Player is nil in BindToWeapon.")
        return
    end

    if not item then
        print("ERROR: Item is nil in BindToWeapon.")
        return
    end

    print("DEBUG: Starting orb binding process...")

    player:Say("Attempting to bind orb...")

    local orbID = "ZM_MysticOrb"

    -- If the item has a unique ID already, use it
    if item:getModData().orbUniqueID then
        orbID = orbID .. "_" .. item:getModData().orbUniqueID
    else
        -- If no unique ID exists, create one based on item properties and add it to the orb
        -- Use condition and other properties to create a unique fingerprint
        local uniquePart = tostring(item:getCondition() or 0) .. "_" .. tostring(item:getID() or "0")
        item:getModData().orbUniqueID = uniquePart
        orbID = orbID .. "_" .. uniquePart
    end

    print("DEBUG: Generated orbID: " .. tostring(orbID))

    -- Send command to handle binding process
    print("DEBUG: Sending client command: BindOrbToWeapon")
    sendClientCommand(player, "ZM_MysticOrb", "BindOrbToWeapon", {
        orbID = orbID,
        itemID = item:getID(),  -- Send the actual item ID so server can verify
        inventoryIndex = item:getContainer():getItems():indexOf(item) -- For later removal
    })
end

-- Function to add the custom context menu option
local function addMysticOrbContextMenu(player, context, items)
    if not context or not items then return end

    -- Get the local player for the context menu
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return end

    for _, v in ipairs(items) do
        local item = v
        if not instanceof(v, "InventoryItem") and v.items and v.items[1] then
            item = v.items[1]
        end

        -- Check if the item is the Mystic Orb
        if item and instanceof(item, "InventoryItem") and item:getType() == "ZM_MysticOrb" then
            -- Check if this orb is already bound (server will double-check)
            if not item:getModData().isUsed then
                -- Pass the player index (0) - our function will convert it to an object
                context:addOption("Bind it to my weapon", 0, ZM_MysticOrb.BindToWeapon, item)
            else
                local option = context:addOption("Already Bound", nil)
                option.notAvailable = true
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addMysticOrbContextMenu)

return ZM_MysticOrb