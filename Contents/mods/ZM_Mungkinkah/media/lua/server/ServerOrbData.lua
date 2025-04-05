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

-- Define where the data file will be stored
ServerOrbData.getDataFilePath = function()
    return "MysticOrbBindings.lua"  -- Changed extension to .lua
end

-- Save bindings to disk
ServerOrbData.saveData = function()
    -- Convert table to string using our serialization function
    local dataToSave = ServerOrbData.bindings

    -- Check if data is valid
    if not dataToSave then
        print("ERROR: No data to save")
        return false
    end

    -- Serialize the table to string instead of using JSON
    local serializedData = serializeTable(dataToSave)

    -- Save to file
    local fileWriter = getFileWriter(ServerOrbData.getDataFilePath(), true, false)
    if not fileWriter then
        print("ERROR: Failed to open file for writing: " .. ServerOrbData.getDataFilePath())
        return false
    end

    fileWriter:write(serializedData)
    fileWriter:close()

    print("DEBUG: Saved Mystic Orb binding data to disk")
    return true
end

-- Load bindings from disk
ServerOrbData.loadData = function()
    -- Check if file exists
    local file = getFileReader(ServerOrbData.getDataFilePath(), false)
    if not file then
        print("DEBUG: No existing Mystic Orb binding data file found, using empty table")
        ServerOrbData.bindings = {}
        ServerOrbData.loaded = true
        return
    end

    -- Read serialized data
    local serializedData = ""
    local line = file:readLine()
    while line do
        serializedData = serializedData .. line
        line = file:readLine()
    end
    file:close()

    -- Deserialize data
    if serializedData and serializedData ~= "" then
        local loadedData = deserializeTable(serializedData)
        if loadedData then
            ServerOrbData.bindings = loadedData
            print("DEBUG: Loaded Mystic Orb binding data from disk with " .. tostring(tableSize(loadedData)) .. " entries")
        end
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

-- Check if a weapon is bound
ServerOrbData.isWeaponBound = function(weaponFullType)
    if not ServerOrbData.loaded then
        ServerOrbData.loadData()
    end

    -- Make sure bindings exists
    if not ServerOrbData.bindings then
        ServerOrbData.bindings = {}
        return false, nil
    end

    print("DEBUG: Checking if weapon is bound: " .. tostring(weaponFullType))

    -- Check all bindings - exact match on weaponID
    for orbID, weaponID in pairs(ServerOrbData.bindings) do
        print("DEBUG: Comparing weapon ID: '" .. tostring(weaponID) .. "' with '" .. tostring(weaponFullType) .. "'")

        -- Try exact match first (most reliable)
        if weaponID == weaponFullType then
            print("DEBUG: Found exact match for weapon")
            return true, orbID
        end

        -- If needed, try substring match too
        if string.find(tostring(weaponID), tostring(weaponFullType)) then
            print("DEBUG: Found substring match for weapon")
            return true, orbID
        end
    end

    print("DEBUG: No binding found for weapon: " .. tostring(weaponFullType))
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

return ServerOrbData