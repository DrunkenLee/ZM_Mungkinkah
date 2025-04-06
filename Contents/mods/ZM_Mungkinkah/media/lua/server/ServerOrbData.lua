-- Server-side data manager for Mystic Orb bindings
local ServerOrbData = {}
ServerOrbData.MOD_ID = "ZM_MysticOrb"
ServerOrbData.bindings = {}  -- Initialize this immediately
ServerOrbData.loaded = true  -- Set to true by default to avoid issues

-- Helper function to serialize a table to string (replacement for JSON)
local function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[" .. type(val) .. "]\""
    end

    return tmp
end

-- Helper function to deserialize a string back to table
local function deserializeTable(str)
    local result, err = loadstring("return " .. str)
    if result then
        result = result()
        return result
    else
        print("ERROR: Failed to deserialize table: " .. tostring(err))
        return {}
    end
end

-- Replace the problematic getDataFilePath function with this simpler version
ServerOrbData.getDataFilePath = function()
    -- Avoid all external function calls - just return a fixed filename
    return "MysticOrbBindings.lua"
end

-- Also replace the saveData function with a more robust version
ServerOrbData.saveData = function()
    -- Use ModData API instead of file I/O for better reliability
    if not ServerOrbData.bindings then
        ServerOrbData.bindings = {}
    end

    -- Store data in global ModData which persists across saves
    ModData.add("ZM_MysticOrb_Bindings", ServerOrbData.bindings)
    ModData.transmit("ZM_MysticOrb_Bindings") -- Ensure it's transmitted in multiplayer

    print("DEBUG: Saved Mystic Orb binding data to ModData")
    return true
end

-- Replace loadData with ModData version too
ServerOrbData.loadData = function()
    -- Load from ModData instead of file
    if ModData.exists("ZM_MysticOrb_Bindings") then
        ServerOrbData.bindings = ModData.get("ZM_MysticOrb_Bindings") or {}
    else
        ServerOrbData.bindings = {}
        -- Initialize the ModData
        ModData.add("ZM_MysticOrb_Bindings", ServerOrbData.bindings)
    end

    ServerOrbData.loaded = true
end

-- Helper function to count table entries
function tableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- Add a binding
ServerOrbData.addBinding = function(orbID, weaponID)
    if not ServerOrbData.loaded then
        ServerOrbData.loadData()
    end

    -- Make sure bindings exists
    if not ServerOrbData.bindings then
        ServerOrbData.bindings = {}
    end

    ServerOrbData.bindings[orbID] = weaponID
    ServerOrbData.saveData()

    return true
end

-- Update the isWeaponBound function to ONLY match exact weapon IDs
ServerOrbData.isWeaponBound = function(weaponFullType)
    if not ServerOrbData.loaded then
        ServerOrbData.loadData()
    end

    -- Make sure bindings exists
    if not ServerOrbData.bindings then
        ServerOrbData.bindings = {}
        return false, nil
    end

    -- IMPORTANT: ONLY check for exact matches
    for orbID, weaponID in pairs(ServerOrbData.bindings) do
        if weaponID == weaponFullType then
            print("DEBUG: Found exact match for weapon ID")
            return true, orbID
        end
    end
    return false, nil
end

-- Remove a binding
ServerOrbData.removeBinding = function(orbID)
    if not ServerOrbData.loaded then
        ServerOrbData.loadData()
    end

    -- Make sure bindings exists
    if not ServerOrbData.bindings then
        ServerOrbData.bindings = {}
        return false
    end

    if ServerOrbData.bindings[orbID] then
        ServerOrbData.bindings[orbID] = nil
        ServerOrbData.saveData()
        return true
    end

    return false
end

-- Initialize immediately
ServerOrbData.loaded = true
ServerOrbData.bindings = ServerOrbData.bindings or {}

-- Ensure data is loaded when server starts and reloads
Events.OnServerStarted.Add(function()
    ServerOrbData.loadData()
end)

-- Also load on game start
Events.OnGameStart.Add(function()
    ServerOrbData.loadData()
end)

-- Also make sure to periodically save the data
Events.EveryTenMinutes.Add(function()
    if ServerOrbData.bindings and tableSize(ServerOrbData.bindings) > 0 then
        ServerOrbData.saveData()
    end
end)

return ServerOrbData