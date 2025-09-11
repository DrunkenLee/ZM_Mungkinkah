BootRefineHandler = BootRefineHandler or {}

-- Import GlobalMethods for ServerPoints management
local GlobalMethods = require "globalmethods"

-- Base costs for refinement attempts
local REFINEMENT_COSTS = {
    boots = 1000,
    vest = 1000,
    bag = 2500
}

-- =========================
-- Cost Management Functions
-- =========================

-- Get refinement cost for equipment type
function BootRefineHandler.getRefinementCost(equipmentType)
    return REFINEMENT_COSTS[equipmentType] or REFINEMENT_COSTS.boots
end

-- Check if player has enough points for refinement
function BootRefineHandler.checkPlayerPoints(equipmentType)
    local player = getPlayer()
    if not player then
        return false, 0, "No player found"
    end

    local username = player:getUsername()
    local requiredCost = BootRefineHandler.getRefinementCost(equipmentType)
    local currentPoints = GlobalMethods.getPlayerPoints(username) or 0

    return currentPoints >= requiredCost, currentPoints, nil, requiredCost
end

-- Deduct points after successful refinement
function BootRefineHandler.deductRefinementCost(equipmentType)
    local player = getPlayer()
    if not player then
        print("[BootRefine] No player found for cost deduction")
        return false
    end

    local username = player:getUsername()
    local cost = BootRefineHandler.getRefinementCost(equipmentType)

    GlobalMethods.takePlayerPoints(username, cost)
    sendClientCommand(player, "ZonaMerahCore", "ZMServerCoreLogger", { logType = "[BOOT REFINE]", message = "Deducted " .. cost .. " points for " .. equipmentType .. " refinement" })
    -- print("[BootRefine] Deducted " .. cost .. " points for " .. equipmentType .. " refinement")
    return true
end

-- =========================
-- Equipment Functions
-- =========================

-- --- Ambil sepatu/boots yang sedang dipakai
function BootRefineHandler.getPlayerBoot()
    local player = getPlayer()
    if not player then
        print("[BootRefine] No player found")
        return nil
    end
    local boots = player:getWornItem("Shoes")
    if not boots then
        boots = player:getWornItem("Feet")
    end
    return boots
end

function BootRefineHandler.wornItemsToString(wornItems)
    if not wornItems then return "nil" end
    local parts = {}
    for i = 0, wornItems:size() - 1 do
        local wi = wornItems:get(i)
        if wi then
            local loc  = wi:getLocation()
            local item = wi:getItem()
            local name = item and (item:getDisplayName() or item:getFullType() or tostring(item)) or "nil"
            parts[#parts+1] = string.format("%s=%s", tostring(loc), name)
        end
    end
    return "[" .. table.concat(parts, ", ") .. "]"
end

-- --- Ambil vest yang sedang dipakai
function BootRefineHandler.getPlayerVest()
    local player = getPlayer()
    if not player then
        print("[BootRefine] No player found")
        return nil
    end

    -- local wornItems = player:getWornItems()
    -- cetak isi wornItems sebagai string
    -- print("[BootRefine] wornItems: " .. BootRefineHandler.wornItemsToString(wornItems))

    local vest = player:getWornItem("TorsoExtraVest") or player:getWornItem("TorsoExtra") or {}
    return vest
end

-- --- Ambil bag yang sedang dipakai
function BootRefineHandler.getPlayerBag()
    local player = getPlayer()
    if not player then
        print("[BootRefine] No player found")
        return nil
    end
    local bag = player:getWornItem("Back") or {}
    return bag
end

-- (opsional) Helper baca semua modifier boot saat ini
function BootRefineHandler.getBootModifiers()
    local boots = BootRefineHandler.getPlayerBoot()
    if not boots then
        print("[BootRefine] No boots equipped")
        return nil
    end
    local t = {
        DisplayName      = boots.getDisplayName and boots:getDisplayName() or nil,
        FullType         = boots.getFullType and boots:getFullType() or nil,
        Condition        = boots.getCondition and boots:getCondition() or nil,
        ConditionMax     = boots.getConditionMax and boots:getConditionMax() or nil,
        Insulation       = boots.getInsulation and boots:getInsulation() or nil,
        WindResistance   = boots.getWindresist and boots:getWindresist() or nil,
        WaterResistance  = boots.getWaterresist and boots:getWaterresist() or nil,
        RunSpeedModifier = boots.getRunSpeedModifier and boots:getRunSpeedModifier() or nil,
        CombatSpeedMod   = boots.getCombatSpeedModifier and boots:getCombatSpeedModifier() or nil,
        Weight           = boots.getWeight and boots:getWeight() or nil,
        ScratchDefense   = boots.getScratchDefense and boots:getScratchDefense() or nil,
        BiteDefense      = boots.getBiteDefense and boots:getBiteDefense() or nil,
        Category         = boots.getCategory and boots:getCategory() or nil,
    }

    return t
end

function BootRefineHandler.getVestModifiers()
    local vest = BootRefineHandler.getPlayerVest()
    if not vest then
        print("[BootRefine] No vest equipped")
        return nil
    end
    local t = {
        DisplayName      = vest.getDisplayName and vest:getDisplayName() or nil,
        FullType         = vest.getFullType and vest:getFullType() or nil,
        Condition        = vest.getCondition and vest:getCondition() or nil,
        ConditionMax     = vest.getConditionMax and vest:getConditionMax() or nil,
        Insulation       = vest.getInsulation and vest:getInsulation() or nil,
        WindResistance   = vest.getWindresist and vest:getWindresist() or nil,
        WaterResistance  = vest.getWaterresist and vest:getWaterresist() or nil,
        RunSpeedModifier = vest.getRunSpeedModifier and vest:getRunSpeedModifier() or nil,
        CombatSpeedMod   = vest.getCombatSpeedModifier and vest:getCombatSpeedModifier() or nil,
        Weight           = vest.getWeight and vest:getWeight() or nil,
        ScratchDefense   = vest.getScratchDefense and vest:getScratchDefense() or nil,
        BiteDefense      = vest.getBiteDefense and vest:getBiteDefense() or nil,
        BulletDefense    = vest.getBulletDefense and vest:getBulletDefense() or nil,
        Thickness        = vest.getThickness and vest:getThickness() or nil,
        Category         = vest.getCategory and vest:getCategory() or nil,
    }
    return t
end

function BootRefineHandler.getBagModifiers()
    local bag = BootRefineHandler.getPlayerBag()
    if not bag then
        print("[BootRefine] No bag equipped")
        return nil
    end
    local t = {
        DisplayName      = bag.getDisplayName and bag:getDisplayName() or nil,
        FullType         = bag.getFullType and bag:getFullType() or nil,
        Condition        = bag.getCondition and bag:getCondition() or nil,
        ConditionMax     = bag.getConditionMax and bag:getConditionMax() or nil,
        Insulation       = bag.getInsulation and bag:getInsulation() or nil,
        WindResistance   = bag.getWindresist and bag:getWindresist() or nil,
        WaterResistance  = bag.getWaterresist and bag:getWaterresist() or nil,
        RunSpeedModifier = bag.getRunSpeedModifier and bag:getRunSpeedModifier() or nil,
        CombatSpeedMod   = bag.getCombatSpeedModifier and bag:getCombatSpeedModifier() or nil,
        Weight           = bag.getWeight and bag:getWeight() or nil,
        ScratchDefense   = bag.getScratchDefense and bag:getScratchDefense() or nil,
        BiteDefense      = bag.getBiteDefense and bag:getBiteDefense() or nil,
        WeightReduction  = bag.getWeightReduction and bag:getWeightReduction() or nil,
        Capacity         = bag.getCapacity and bag:getCapacity() or nil,
        Category         = bag.getCategory and bag:getCategory() or nil,
    }
    return t
end

-- =========================
-- Helpers (fixed)
-- =========================
local function _brh_rng(minIncl, maxIncl, forced)
    if forced then
        local f = math.floor(tonumber(forced) or minIncl)
        if f < minIncl then f = minIncl end
        if f > maxIncl then f = maxIncl end
        return f
    end
    if ZombRand then
        -- ZombRand(a, b) -> [a, b)
        return ZombRand(minIncl, maxIncl + 1)
    end
    return math.random(minIncl, maxIncl)
end

local function _brh_clamp(v, minv, maxv)
    if minv and v < minv then v = minv end
    if maxv and v > maxv then v = maxv end
    return v
end

-- Setter & Getter aman untuk Build 41
local function _brh_set_boot_value(boots, key, value)
    if key == "ConditionMax" then
        if boots.setConditionMax then boots:setConditionMax(value); return true end
        if boots.setMaxCondition  then boots:setMaxCondition(value); return true end
        return false
    elseif key == "Condition" then
        if boots.setCondition then boots:setCondition(value); return true end
        return false
    elseif key == "RunSpeedModifier" then
        if boots.setRunSpeedModifier then boots:setRunSpeedModifier(value); return true end
        return false
    elseif key == "Insulation" then
        if boots.setInsulation then boots:setInsulation(value); return true end
        return false
    elseif key == "ScratchDefense" then
        if boots.setScratchDefense then boots:setScratchDefense(value); return true end
        return false
    elseif key == "BiteDefense" then
        if boots.setBiteDefense then boots:setBiteDefense(value); return true end
        return false
    elseif key == "WindResistance" then
        if boots.setWindresist then boots:setWindresist(value); return true end
        return false
    elseif key == "WaterResistance" then
        if boots.setWaterresist then boots:setWaterresist(value); return true end
        return false
    elseif key == "CombatSpeedMod" then
        if boots.setCombatSpeedModifier then boots:setCombatSpeedModifier(value); return true end
        return false
    elseif key == "BulletDefense" then
        if boots.setBulletDefense then boots:setBulletDefense(value); return true end
        return false
    elseif key == "Thickness" then
        if boots.setThickness then boots:setThickness(value); return true end
        return false
    elseif key == "WeightReduction" then
        if boots.setWeightReduction then boots:setWeightReduction(value); return true end
        return false
    elseif key == "Capacity" then
        if boots.setCapacity then boots:setCapacity(value); return true end
        return false
    end
    return false
end

local function _brh_get_boot_value(boots, key)
    if key == "ConditionMax" then
        return boots.getConditionMax and boots:getConditionMax() or nil
    elseif key == "Condition" then
        return boots.getCondition and boots:getCondition() or nil
    elseif key == "RunSpeedModifier" then
        return boots.getRunSpeedModifier and boots:getRunSpeedModifier() or nil
    elseif key == "Insulation" then
        return boots.getInsulation and boots:getInsulation() or nil
    elseif key == "ScratchDefense" then
        return boots.getScratchDefense and boots:getScratchDefense() or nil
    elseif key == "BiteDefense" then
        return boots.getBiteDefense and boots:getBiteDefense() or nil
    elseif key == "WindResistance" then
        return boots.getWindresist and boots:getWindresist() or nil
    elseif key == "WaterResistance" then
        return boots.getWaterresist and boots:getWaterresist() or nil
    elseif key == "CombatSpeedMod" then
        return boots.getCombatSpeedModifier and boots:getCombatSpeedModifier() or nil
    elseif key == "BulletDefense" then
        return boots.getBulletDefense and boots:getBulletDefense() or nil
    elseif key == "Thickness" then
        return boots.getThickness and boots:getThickness() or nil
    elseif key == "WeightReduction" then
        return boots.getWeightReduction and boots:getWeightReduction() or nil
    elseif key == "Capacity" then
        return boots.getCapacity and boots:getCapacity() or nil
    end
    return nil
end

local function _brh_has_setter(boots, key)
    if key == "ConditionMax"     then return (boots.setConditionMax ~= nil) or (boots.setMaxCondition ~= nil) end
    if key == "Condition"        then return (boots.setCondition ~= nil) end
    if key == "RunSpeedModifier" then return (boots.setRunSpeedModifier ~= nil) end
    if key == "Insulation"       then return (boots.setInsulation ~= nil) end
    if key == "ScratchDefense"   then return (boots.setScratchDefense ~= nil) end
    if key == "BiteDefense"      then return (boots.setBiteDefense ~= nil) end
    if key == "WindResistance"   then return (boots.setWindresist ~= nil) end
    if key == "WaterResistance"  then return (boots.setWaterresist ~= nil) end
    if key == "CombatSpeedMod"   then return (boots.setCombatSpeedModifier ~= nil) end
    if key == "BulletDefense"    then return (boots.setBulletDefense ~= nil) end
    if key == "Thickness"        then return (boots.setThickness ~= nil) end
    if key == "WeightReduction"  then return (boots.setWeightReduction ~= nil) end
    if key == "Capacity"         then return (boots.setCapacity ~= nil) end
    return false
end

-- Caps per stat & integer/float
local _BRH_CAPS = {
    Condition        = { cap = 100, integer = true  },
    ConditionMax     = { cap = 100, integer = true  },
    Insulation       = { cap = 100, integer = false },
    RunSpeedModifier = { cap = 1.5, integer = false },
    ScratchDefense   = { cap = 150, integer = true  },
    BiteDefense      = { cap = 150, integer = true  },
    BulletDefense    = { cap = 300, integer = true  },
    Thickness        = { cap = 10, integer = false  },
    WindResistance   = { cap = 100, integer = false },
    WaterResistance  = { cap = 100, integer = false },
    WeightReduction  = { cap = 100.0, integer = false },
    Capacity         = { cap = 65, integer = false },
    CombatSpeedMod   = { cap = 1.5, integer = false },
}

-- Equipment-specific stat filters
local _EQUIPMENT_STATS = {
    boots = {
        "Condition", "ConditionMax", "Insulation", "RunSpeedModifier", "CombatSpeedMod",
        "ScratchDefense", "BiteDefense"
    },
    vest = {
        "Condition", "ConditionMax", "Insulation", "RunSpeedModifier", "CombatSpeedMod",
        "ScratchDefense", "BiteDefense", "BulletDefense", "Thickness",
        "WindResistance", "WaterResistance"
    },
    bag = {
       "WeightReduction", "Capacity"
    }
}-- =========================
-- Generic Refinement Functions
-- =========================

-- Generic refinement function that works for any equipment type
function BootRefineHandler.refineEquipmentMods(equipmentItem, opts)
    opts = opts or {}
    local successRate = tonumber(opts.successRate) or 50 -- 50/50 default
    local equipmentType = opts.equipmentType or "boots" -- default to boots for compatibility

    if not equipmentItem then
        print("[BootRefine] No equipment item provided")
        return { success = false, reason = "no_equipment" }
    end

    -- Check if this is a cost-bypassed call (for internal use)
    if not opts.bypassCost then
        -- Check player points first (synchronous check for immediate feedback)
        local player = getPlayer()
        if player then
            local hasEnough, currentPoints, error, requiredCost = BootRefineHandler.checkPlayerPoints(equipmentType)

            if not hasEnough then
                print("[BootRefine] Insufficient points for " .. equipmentType .. " refinement")
                player:Say("Not enough ServerPoints! Need " .. requiredCost .. ", have " .. currentPoints)
                return { success = false, reason = "insufficient_points", required = requiredCost, current = currentPoints }
            end

            print("[BootRefine] Points check passed: " .. currentPoints .. "/" .. requiredCost .. " for " .. equipmentType)
        end
    end

    local md = equipmentItem:getModData()
    md.BootRefine = md.BootRefine or {}

    -- Get allowed stats for this equipment type
    local allowedStats = _EQUIPMENT_STATS[equipmentType] or _EQUIPMENT_STATS.boots

    -- Simpan nilai original sekali (only for allowed stats)
    if not md.BootRefine.__orig then
        md.BootRefine.__orig = {}
        for _, key in ipairs(allowedStats) do
            if _BRH_CAPS[key] then
                md.BootRefine.__orig[key] = _brh_get_boot_value(equipmentItem, key)
            end
        end
    end
    local orig = md.BootRefine.__orig

    -- ROLL 1: Success / Fail
    local r1 = _brh_rng(1, 100, opts.roll1)
    local success = (r1 <= successRate)

    -- Special handling for all equipment types - they can have negative effects on failure
    if not success then
        print(string.format("[BootRefine] %s FAIL (roll1=%d, successRate=%d%%). Degradation occurs!",
            string.upper(equipmentType), r1, successRate))
        local player = getPlayer()
        if player and player.Say then
            if equipmentType == "bag" then
                player:Say("Oh no! My bag refinement failed and it got worse!")
            elseif equipmentType == "boots" then
                player:Say("Damn! My boots got damaged from the failed refinement!")
            elseif equipmentType == "vest" then
                player:Say("Argh! My vest is now worse after the failed refinement!")
            else
                player:Say("Ahh .. I failed to refine my equipment.")
            end
        end

        -- Apply negative effects based on equipment type (1 random stat only)
        local degradationResults = {}
        local availableDegradationStats = {}

        -- Collect available stats for degradation based on equipment type
        if equipmentType == "bag" then
            if _brh_has_setter(equipmentItem, "WeightReduction") then
                table.insert(availableDegradationStats, {stat = "WeightReduction", reduction = 2})
            end
            if _brh_has_setter(equipmentItem, "Capacity") then
                table.insert(availableDegradationStats, {stat = "Capacity", reduction = 5})
            end
        elseif equipmentType == "boots" then
            if _brh_has_setter(equipmentItem, "CombatSpeedMod") then
                table.insert(availableDegradationStats, {stat = "CombatSpeedMod", reduction = 0.01})
            end
            if _brh_has_setter(equipmentItem, "RunSpeedModifier") then
                table.insert(availableDegradationStats, {stat = "RunSpeedModifier", reduction = 0.01})
            end
            if _brh_has_setter(equipmentItem, "ScratchDefense") then
                table.insert(availableDegradationStats, {stat = "ScratchDefense", reduction = 5})
            end
            if _brh_has_setter(equipmentItem, "BiteDefense") then
                table.insert(availableDegradationStats, {stat = "BiteDefense", reduction = 5})
            end
        elseif equipmentType == "vest" then
            if _brh_has_setter(equipmentItem, "CombatSpeedMod") then
                table.insert(availableDegradationStats, {stat = "CombatSpeedMod", reduction = 0.01})
            end
            if _brh_has_setter(equipmentItem, "RunSpeedModifier") then
                table.insert(availableDegradationStats, {stat = "RunSpeedModifier", reduction = 0.01})
            end
            if _brh_has_setter(equipmentItem, "ScratchDefense") then
                table.insert(availableDegradationStats, {stat = "ScratchDefense", reduction = 5})
            end
            if _brh_has_setter(equipmentItem, "BiteDefense") then
                table.insert(availableDegradationStats, {stat = "BiteDefense", reduction = 5})
            end
        end

        -- Randomly select 1 stat to degrade
        if #availableDegradationStats > 0 then
            local randomIndex = _brh_rng(1, #availableDegradationStats, nil)
            local selectedStat = availableDegradationStats[randomIndex]

            local currentValue = _brh_get_boot_value(equipmentItem, selectedStat.stat) or 0
            local newValue = math.max(0, currentValue - selectedStat.reduction)
            local degradationSuccess = _brh_set_boot_value(equipmentItem, selectedStat.stat, newValue)

            table.insert(degradationResults, {
                stat = selectedStat.stat,
                ok = degradationSuccess,
                oldValue = currentValue,
                newValue = newValue,
                change = -selectedStat.reduction,
                isDegradation = true
            })

            if degradationSuccess then
                print(string.format("[BootRefine] DEGRADATION: %s: %.3f -> %.3f (-%3f) [RANDOM SELECTION]",
                    selectedStat.stat, currentValue, newValue, selectedStat.reduction))
            else
                print(string.format("[BootRefine] Failed to degrade %s", selectedStat.stat))
            end
        end

        -- Store current stat values in modData (degradation)
        md.BootRefine.currentValues = md.BootRefine.currentValues or {}
        for _, result in ipairs(degradationResults) do
            if result.ok then
                md.BootRefine.currentValues[result.stat] = result.newValue
            end
        end

        -- Deduct refinement cost even on failure (only if not bypassed)
        if not opts.bypassCost then
            BootRefineHandler.deductRefinementCost(equipmentType)
        end

        return {
            success = false,
            roll1 = r1,
            successRate = successRate,
            equipmentType = equipmentType,
            stats = degradationResults,
            isDegradation = true,
            costDeducted = not opts.bypassCost
        }
    end    -- ROLL 2: Special roll check (for all equipment types)
    local r2p = _brh_rng(1, 100, opts.rollPercent) -- 1-100 roll
    local isSpecialRoll = (r2p == 7 or r2p == 14 or r2p == 17 or r2p == 27)
    local multiplier = isSpecialRoll and 2 or 1 -- 2x for special rolls, 1x for normal

    local player = getPlayer()
    if player and player.Say then
        if isSpecialRoll then
            player:Say(string.format("SPECIAL REFINEMENT! Roll %d! Double improvement!", r2p))
        else
            player:Say(string.format("Equipment improved! Roll %d", r2p))
        end
    end

    -- Define the stats to improve and their base increases for each equipment type
    local availableStats = {}
    if equipmentType == "boots" then
        -- For boots: CombatSpeedMod, RunSpeedModifier, ScratchDefense, BiteDefense
        if _brh_has_setter(equipmentItem, "CombatSpeedMod") then
            table.insert(availableStats, {stat = "CombatSpeedMod", baseIncrease = 0.018})
        end
        if _brh_has_setter(equipmentItem, "RunSpeedModifier") then
            table.insert(availableStats, {stat = "RunSpeedModifier", baseIncrease = 0.018})
        end
        if _brh_has_setter(equipmentItem, "ScratchDefense") then
            table.insert(availableStats, {stat = "ScratchDefense", baseIncrease = 6})
        end
        if _brh_has_setter(equipmentItem, "BiteDefense") then
            table.insert(availableStats, {stat = "BiteDefense", baseIncrease = 6})
        end
    elseif equipmentType == "vest" then
        -- For vest: CombatSpeedMod, RunSpeedModifier, ScratchDefense, BiteDefense
        if _brh_has_setter(equipmentItem, "CombatSpeedMod") then
            table.insert(availableStats, {stat = "CombatSpeedMod", baseIncrease = 0.018})
        end
        if _brh_has_setter(equipmentItem, "RunSpeedModifier") then
            table.insert(availableStats, {stat = "RunSpeedModifier", baseIncrease = 0.018})
        end
        if _brh_has_setter(equipmentItem, "ScratchDefense") then
            table.insert(availableStats, {stat = "ScratchDefense", baseIncrease = 6})
        end
        if _brh_has_setter(equipmentItem, "BiteDefense") then
            table.insert(availableStats, {stat = "BiteDefense", baseIncrease = 6})
        end
        if _brh_has_setter(equipmentItem, "BulletDefense") then
            table.insert(availableStats, {stat = "BulletDefense", baseIncrease = 6})
        end
    elseif equipmentType == "bag" then
        -- For bag: WeightReduction, Capacity (only these 2 stats)
        if _brh_has_setter(equipmentItem, "WeightReduction") then
            table.insert(availableStats, {stat = "WeightReduction", baseIncrease = 2.5})
        end
        if _brh_has_setter(equipmentItem, "Capacity") then
            table.insert(availableStats, {stat = "Capacity", baseIncrease = 5.5})
        end
    else
        -- For other equipment types, use fallback
        print("[BootRefine] Unsupported equipment type: " .. equipmentType)
        return { success = false, roll1 = r1, rollPercent = r2p, reason = "unsupported_equipment_type" }
    end

    if #availableStats == 0 then
        print("[BootRefine] No eligible stats found for refinement on " .. equipmentType)
        return { success = false, roll1 = r1, rollPercent = r2p, reason = "no_eligible_stat" }
    end

    -- Randomly select which stats to improve based on special roll logic
    local statsToImprove = {}
    local numStatsToImprove = 1 -- Default: improve 1 random stat

    -- Special roll logic: improve more stats
    if isSpecialRoll then
        if r2p == 7 then
            numStatsToImprove = 2 -- Improve 2 random stats
        elseif r2p == 14 then
            numStatsToImprove = #availableStats -- Improve all available stats
        elseif r2p == 17 then
            numStatsToImprove = 2 -- Improve 2 random stats
        elseif r2p == 27 then
            numStatsToImprove = 3 -- Improve 3 random stats (or all if less than 3)
        end
    end

    -- Cap the number of stats to improve to available stats
    numStatsToImprove = math.min(numStatsToImprove, #availableStats)

    -- Randomly select stats to improve (without replacement)
    local selectedIndices = {}
    for i = 1, numStatsToImprove do
        local availableIndices = {}
        for j = 1, #availableStats do
            if not selectedIndices[j] then
                table.insert(availableIndices, j)
            end
        end

        if #availableIndices > 0 then
            local randomIndex = availableIndices[_brh_rng(1, #availableIndices)]
            selectedIndices[randomIndex] = true
            table.insert(statsToImprove, availableStats[randomIndex])
        end
    end

    -- Calculate new values for each stat
    local results = {}
    local function compute_new_value(statKey, baseIncrease)
        local currentValue = _brh_get_boot_value(equipmentItem, statKey)
        if currentValue == nil then
            currentValue = 0 -- Default to 0 if stat doesn't exist
        end

        local actualIncrease = baseIncrease * multiplier
        local newValue = currentValue + actualIncrease

        -- Apply caps if they exist
        local capInfo = _BRH_CAPS[statKey]
        if capInfo then
            if capInfo.integer then
                newValue = math.floor(newValue + 0.5)
            end
            newValue = _brh_clamp(newValue, nil, capInfo.cap)
        end

        return newValue, currentValue, actualIncrease
    end

    -- Apply the improvements to each stat
    for _, statInfo in ipairs(statsToImprove) do
        local statKey = statInfo.stat
        local baseIncrease = statInfo.baseIncrease

        local newValue, currentValue, actualIncrease = compute_new_value(statKey, baseIncrease)

        -- Apply the new value
        local success = _brh_set_boot_value(equipmentItem, statKey, newValue)

        table.insert(results, {
            stat = statKey,
            ok = success,
            oldValue = currentValue,
            newValue = newValue,
            increase = actualIncrease,
            isSpecial = isSpecialRoll
        })

        if success then
            print(string.format("[BootRefine] %s: %.3f -> %.3f (+%.3f) %s",
                statKey, currentValue, newValue, actualIncrease,
                isSpecialRoll and "[SPECIAL x2]" or ""))
        else
            print(string.format("[BootRefine] Failed to set %s", statKey))
        end
    end

    -- Logging summary
    local successCount = 0
    for _, r in ipairs(results) do
        if r.ok then successCount = successCount + 1 end
    end

    local selectionInfo = ""
    if isSpecialRoll then
        if r2p == 14 then
            selectionInfo = " | ALL STATS"
        else
            selectionInfo = string.format(" | %d RANDOM STATS", numStatsToImprove)
        end
    else
        selectionInfo = " | 1 RANDOM STAT"
    end

    print(string.format("[BootRefine] SUCCESS roll1=%d/%d%% | roll2=%d%s | %d/%d stats improved | Equipment: %s%s",
        r1, successRate, r2p, isSpecialRoll and " (SPECIAL)" or "", successCount, #results, equipmentType, selectionInfo))

    -- Store current values after refinement
    md.BootRefine.currentValues = md.BootRefine.currentValues or {}
    for _, result in ipairs(results) do
        if result.ok then
            md.BootRefine.currentValues[result.stat] = result.newValue
        end
    end

    -- Deduct refinement cost on successful completion (only if not bypassed)
    if not opts.bypassCost then
        BootRefineHandler.deductRefinementCost(equipmentType)
    end

    return {
        success = true,
        roll1 = r1,
        successRate = successRate,
        rollPercent = r2p,
        isSpecialRoll = isSpecialRoll,
        multiplier = multiplier,
        equipmentType = equipmentType,
        stats = results,
        costDeducted = not opts.bypassCost
    }
end

-- =========================
-- Backward Compatibility Wrappers (with cost checking enabled)
-- =========================-- Vest refinement function
function BootRefineHandler.refineVestMods(opts)
    local vest = BootRefineHandler.getPlayerVest()
    local vestDisplayName = vest and (vest.getDisplayName and vest:getDisplayName() or "None") or "None"
    if vest and vestDisplayName == "None" then
        print("[BootRefine] Tidak ada vest yang dipakai")
        return { success = false, reason = "no_vest" }
    end
    opts = opts or {}
    opts.equipmentType = "vest"
    if vest:getDisplayName() and string.find(string.upper(vest:getDisplayName()), "U.S.S", 1, true) then
        getPlayer():Say("USS Property detected, skipping refinement.")
        return { success = false, reason = "USS_Forbiden" }
    end
    -- Use cost checking by default for backward compatibility
    return BootRefineHandler.refineEquipmentMods(vest, opts)
end

-- Bag refinement function
function BootRefineHandler.refineBagMods(opts)
    local bag = BootRefineHandler.getPlayerBag()
    local bagDisplayName = bag and (bag.getDisplayName and bag:getDisplayName() or "None") or "None"
    if bag and bagDisplayName == "None" then
        print("[BootRefine] Tidak ada bag yang dipakai")
        return { success = false, reason = "no_bag" }
    end
    if bag:getDisplayName() and string.find(string.upper(bag:getDisplayName()), "U.S.S", 1, true) then
        getPlayer():Say("USS Property detected, skipping refinement.")
        return { success = false, reason = "USS_Forbiden" }
    end
    opts = opts or {}
    opts.equipmentType = "bag"
    -- Use cost checking by default for backward compatibility
    return BootRefineHandler.refineEquipmentMods(bag, opts)
end

-- =========================
-- 2-Roll Gacha (boots - keeping for compatibility)
-- =========================
function BootRefineHandler.refineBootMods(opts)
    local boots = BootRefineHandler.getPlayerBoot()
    local bootsDisplayName = boots and (boots.getDisplayName and boots:getDisplayName() or "None") or "None"
    if boots and bootsDisplayName == "None" then
        print("[BootRefine] Tidak ada sepatu/boots yang dipakai")
        return { success = false, reason = "no_boots" }
    end
    print("[BootRefine] Found boots: " .. (boots.getDisplayName and boots:getDisplayName() or "Unknown"))
    if boots:getDisplayName() and string.find(string.upper(boots:getDisplayName()), "COS", 1, true) then
        getPlayer():Say("Cosmetic boots detected, skipping refinement.")
        return { success = false, reason = "cosmetic_item" }
    end

    if boots:getDisplayName() and string.find(string.upper(boots:getDisplayName()), "U.S.S", 1, true) then
        getPlayer():Say("USS Property detected, skipping refinement.")
        return { success = false, reason = "USS_Forbiden" }
    end

    opts = opts or {}
    opts.equipmentType = "boots"
    -- Use cost checking by default for backward compatibility
    return BootRefineHandler.refineEquipmentMods(boots, opts)
end

-- Backward-compat: tetap sediakan nama lama
BootRefineHandler.scaleBootMods = function(opts)
    return BootRefineHandler.refineBootMods(opts)
end

-- =========================
-- UI Integration Functions
-- =========================

-- Get detailed equipment info for UI display
function BootRefineHandler.getEquipmentInfo(equipType)
    equipType = equipType or "boots"

    if equipType == "boots" then
        local boots = BootRefineHandler.getPlayerBoot()
        if not boots then
            return {
                equipped = false,
                message = "No boots/shoes equipped",
                item = nil,
                stats = nil
            }
        end

        local stats = BootRefineHandler.getBootModifiers()
        return {
            equipped = true,
            message = "Boots equipped and ready for refinement",
            item = boots,
            stats = stats,
            refinable = true
        }
    elseif equipType == "vest" then
        local vest = BootRefineHandler.getPlayerVest()
        if not vest then
            return {
                equipped = false,
                message = "No vest equipped",
                item = nil,
                stats = nil
            }
        end

        local stats = BootRefineHandler.getVestModifiers()
        return {
            equipped = true,
            message = "Vest equipped and ready for refinement",
            item = vest,
            stats = stats,
            refinable = true
        }
    elseif equipType == "bag" then
        local bag = BootRefineHandler.getPlayerBag()
        if not bag then
            return {
                equipped = false,
                message = "No bag equipped",
                item = nil,
                stats = nil
            }
        end

        local stats = BootRefineHandler.getBagModifiers()
        return {
            equipped = true,
            message = "Bag equipped and ready for refinement",
            item = bag,
            stats = stats,
            refinable = true
        }
    end

    -- Future equipment types
    return {
        equipped = false,
        message = "Equipment type not yet supported",
        item = nil,
        stats = nil,
        refinable = false
    }
end

-- Enhanced refine function with UI callbacks
function BootRefineHandler.refineWithCallback(opts, onComplete)
    opts = opts or {}

    -- Set default callback if none provided
    if not onComplete then
        onComplete = function(result)
            print("[BootRefine] Refinement completed: " .. (result.success and "SUCCESS" or "FAILED"))
        end
    end

    -- Perform refinement
    local result = BootRefineHandler.refineBootMods(opts)

    -- Add UI-specific data
    result.timestamp = getTimestamp()
    result.player = getPlayer():getUsername()

    -- Sync with server if needed
    if result.success then
        BootRefineHandler.syncRefinementToServer(result)
    end

    -- Call the completion callback
    onComplete(result)

    return result
end

-- Sync refinement results to server
function BootRefineHandler.syncRefinementToServer(result)
    if not result then return end

    local player = getPlayer()
    if not player then return end

    -- Send refinement data to server for logging/validation
    sendClientCommand(player, "BootRefine", "syncRefinement", {
        success = result.success,
        stats = result.stats,
        rollPercent = result.rollPercent,
        successRate = result.successRate,
        timestamp = result.timestamp
    })

    print("[BootRefine] Refinement synced to server")
end

-- Play refinement sounds
function BootRefineHandler.playRefinementSound(isSuccess)
    local player = getPlayer()
    if not player then return end

    local soundName = isSuccess and "rganvilsuccess" or "rganvil"

    -- Play locally
    getSoundManager():PlaySound(soundName, false, 1.0)

    -- Request server to broadcast to nearby players
    sendClientCommand(player, "BootRefine", "broadcastSound", {
        sound = soundName,
        success = isSuccess
    })
end

-- Server command handler for boot refinement
local function onBootRefineServerCommand(module, command, args)
    if module ~= "BootRefine" then return end

    if command == "bootDataResponse" then
        print("[BootRefine] Received boot data from server")
        -- Handle server boot data response

    elseif command == "syncAcknowledged" then
        print("[BootRefine] Server acknowledged refinement sync")

    elseif command == "nearbyRefinement" then
        -- Handle nearby player refinement notifications
        if args and args.playerName then
            local message = args.success and "succeeded" or "failed"
            print(string.format("[BootRefine] %s's refinement %s", args.playerName, message))

            -- You could show a UI notification here
            local player = getPlayer()
            if player and player.Say then
                player:Say(string.format("I hear %s working on equipment nearby...", args.playerName))
            end
        end

    elseif command == "playRefinementSound" then
        -- Play refinement sound from nearby players
        if args and args.sound then
            getSoundManager():PlaySound(args.sound, false, 0.5) -- Lower volume for distant sounds
        end

    elseif command == "playerStatsResponse" then
        -- Handle player stats response (for future currency systems)
        if args then
            print(string.format("[BootRefine] Player stats: Points=%d, Total Refinements=%d",
                  args.refinementPoints or 0, args.totalRefinements or 0))
        end
    end
end

-- Register server command handler
Events.OnServerCommand.Add(onBootRefineServerCommand)

-- =========================
-- Equipment Update Event Handler
-- =========================

-- Apply refined stats when equipment is equipped
local function onClothingUpdated(player)
    if not player then return end

    -- Safely handle boots
    local boots = nil
    if player and player.getWornItem then
        local success, result = pcall(function()
            return player:getWornItem("Shoes")
        end)
        if success then
            boots = result
        end

        if not boots then
            local success2, result2 = pcall(function()
                return player:getWornItem("Feet")
            end)
            if success2 then
                boots = result2
            end
        end
    end

    if boots and boots.getModData then
        local md = boots:getModData()
        if md and md.BootRefine and md.BootRefine.currentValues then
            for stat, value in pairs(md.BootRefine.currentValues) do
                if stat and value and _brh_has_setter(boots, stat) then
                    local success = _brh_set_boot_value(boots, stat, value)
                    if not success then
                        print("[BootRefine] Failed to apply refined stat " .. tostring(stat) .. " to boots")
                    end
                end
            end
        end
    end

    -- Safely handle vest
    local vest = nil
    if player and player.getWornItem then
        local success, result = pcall(function()
            return player:getWornItem("TorsoExtraVest") or player:getWornItem("TorsoExtra")
        end)
        if success then
            vest = result
        end
    end

    if vest and vest.getModData then
        local md = vest:getModData()
        if md and md.BootRefine and md.BootRefine.currentValues then
            for stat, value in pairs(md.BootRefine.currentValues) do
                if stat and value and _brh_has_setter(vest, stat) then
                    local success = _brh_set_boot_value(vest, stat, value)
                    if not success then
                        print("[BootRefine] Failed to apply refined stat " .. tostring(stat) .. " to vest")
                    end
                end
            end
        end
    end

    -- Safely handle bag
    local bag = nil
    if player and player.getWornItem then
        local success, result = pcall(function()
            return player:getWornItem("Back")
        end)
        if success then
            bag = result
        end
    end

    if bag and bag.getModData then
        local md = bag:getModData()
        if md and md.BootRefine and md.BootRefine.currentValues then
            for stat, value in pairs(md.BootRefine.currentValues) do
                if stat and value and _brh_has_setter(bag, stat) then
                    local success = _brh_set_boot_value(bag, stat, value)
                    if not success then
                        print("[BootRefine] Failed to apply refined stat " .. tostring(stat) .. " to bag")
                    end
                end
            end
        end
    end
end

-- Register clothing update event with error handling
local function safeOnClothingUpdated(player)
    local success, error = pcall(onClothingUpdated, player)
    if not success then
        print("[BootRefine] Error in OnClothingUpdated: " .. tostring(error))
    end
end

Events.OnClothingUpdated.Add(safeOnClothingUpdated)

-- =========================
-- Public API Functions
-- =========================

-- Get all refinement costs
function BootRefineHandler.getAllRefinementCosts()
    return {
        boots = REFINEMENT_COSTS.boots,
        vest = REFINEMENT_COSTS.vest,
        bag = REFINEMENT_COSTS.bag
    }
end

-- Check if player can afford any refinement
function BootRefineHandler.canAffordAnyRefinement()
    local player = getPlayer()
    if not player then return false end

    local username = player:getUsername()
    local currentPoints = GlobalMethods.getPlayerPoints(username) or 0
    local minCost = math.min(REFINEMENT_COSTS.boots, REFINEMENT_COSTS.vest, REFINEMENT_COSTS.bag)

    return currentPoints >= minCost
end

-- =========================
-- Debug/Testing Functions
-- =========================

-- Test function for UI
function BootRefineHandler.testUIIntegration()
    print("=== Boot Refine UI Integration Test ===")

    local equipInfo = BootRefineHandler.getEquipmentInfo("boots")
    print("Equipment Info:")
    print("  Equipped: " .. tostring(equipInfo.equipped))
    print("  Message: " .. equipInfo.message)

    if equipInfo.equipped and equipInfo.stats then
        print("  Boot Stats:")
        for k, v in pairs(equipInfo.stats) do
            print("    " .. k .. " = " .. tostring(v))
        end
    end

    print("=== Test Complete ===")

    return equipInfo
end

-- Global access for console testing
_G.TestBootRefineUI = BootRefineHandler.testUIIntegration

print("[BootRefineHandler] UI integration functions loaded successfully")
