-- ============================================================================
-- ZM_BuffMoodle.lua - Moodle Implementation for Jessica's Pills
-- ============================================================================

-- Only run on client
if isServer() then return end

require "MF_ISMoodle"

-- Check if Moodle Framework is installed
if not getActivatedMods():contains("MoodleFramework") then
    print("[ZM_BuffMoodle] Warning: Moodle Framework not installed. Buff moodles will not work.")
    return
end

ZM_BuffMoodle = ZM_BuffMoodle or {}

-- ============================================================================
-- LOCAL VARIABLES
-- ============================================================================

local isPlayerValid = false

-- ============================================================================
-- LOCAL FUNCTIONS
-- ============================================================================

local function isMoodleFrameworkAvailable()
    return MF and MF.createMoodle and MF.getMoodle
end

local function setThresholds()
    -- GiantOx moodle - one level only at 0.5 (50%)
    MF.getMoodle("GiantOx"):setThresholds(nil, nil, nil, nil, 0.5, nil, nil, nil)

    -- OakRemedy moodle - one level only at 0.5 (50%)
    MF.getMoodle("OakRemedy"):setThresholds(nil, nil, nil, nil, 0.5, nil, nil, nil)

    print("[ZM_BuffMoodle] Moodle thresholds set")
end

local function validPlayer(playerIndex, player)
    if player == getPlayer() then
        isPlayerValid = true
        setThresholds()
        print("[ZM_BuffMoodle] Buff moodles initialized for player")
    end
end

-- ============================================================================
-- MOODLE CREATION (MUST be at top level)
-- ============================================================================

MF.createMoodle("GiantOx")
MF.createMoodle("OakRemedy")

-- ============================================================================
-- PUBLIC FUNCTIONS
-- ============================================================================

function ZM_BuffMoodle.initializeMoodles()
    print("[ZM_BuffMoodle] Initializing buff moodles...")
    if not isMoodleFrameworkAvailable() then
        print("[ZM_BuffMoodle] Warning: Moodle Framework not available.")
        return false
    end

    setThresholds()

    -- Set chevron direction (up = good, down = bad)
    MF.getMoodle("GiantOx"):setChevronIsUp(true)
    MF.getMoodle("OakRemedy"):setChevronIsUp(true)

    print("[ZM_BuffMoodle] Buff moodles initialized successfully")
    return true
end

function ZM_BuffMoodle.activateGiantOx(player, durationMinutes)
    if not player or not isPlayerValid then
        print("[ZM_BuffMoodle] ERROR: Invalid player")
        return false
    end

    if not isMoodleFrameworkAvailable() then
        print("[ZM_BuffMoodle] ERROR: Moodle Framework not available")
        return false
    end

    local moodle = MF.getMoodle("GiantOx")
    if moodle then
        -- Set to 1.0 to show the moodle at level 1
        moodle:setValue(1.0)

        -- Store duration in player mod data
        local modData = player:getModData()
        modData.ZM_GiantOxEndTime = os.time() + (durationMinutes * 60)

        print("[ZM_BuffMoodle] Giant Ox moodle activated for " .. durationMinutes .. " minutes")
        return true
    end

    return false
end

function ZM_BuffMoodle.deactivateGiantOx(player)
    if not isMoodleFrameworkAvailable() then return end
    local moodle = MF.getMoodle("GiantOx")
    if moodle then
        moodle:setValue(0)
    end
    if player then
        local modData = player:getModData()
        modData.ZM_GiantOxEndTime = nil
    end
    print("[ZM_BuffMoodle] Giant Ox moodle deactivated")
end

function ZM_BuffMoodle.activateOakRemedy(player)
    if not player or not isPlayerValid then
        print("[ZM_BuffMoodle] ERROR: Invalid player")
        return false
    end

    if not isMoodleFrameworkAvailable() then
        print("[ZM_BuffMoodle] ERROR: Moodle Framework not available")
        return false
    end

    local moodle = MF.getMoodle("OakRemedy")
    if moodle then
        -- Set to 1.0 to show the moodle at level 1
        moodle:setValue(1.0)

        -- Store activation time (show for 5 minutes)
        local modData = player:getModData()
        modData.ZM_OakRemedyEndTime = os.time() + (5)

        print("[ZM_BuffMoodle] Oak Remedy moodle activated")
        return true
    end

    return false
end

-- Throttled updater for timely moodle expiry
local nextCheckMs = 0
function ZM_BuffMoodle.updateMoodles()
    -- Called frequently; throttle internally to ~0.5s
    local nowMs = (getTimestampMs and getTimestampMs() or 0)
    if nowMs < nextCheckMs then return end
    nextCheckMs = nowMs + 500
    local player = getPlayer()
    if not player or not isPlayerValid then
        return
    end

    if not isMoodleFrameworkAvailable() then
        return
    end

    local modData = player:getModData()
    local currentTime = os.time()

    -- Update Giant Ox moodle
    if modData.ZM_GiantOxEndTime then
        if currentTime >= modData.ZM_GiantOxEndTime then
            ZM_BuffMoodle.deactivateGiantOx(player)
            print("[ZM_BuffMoodle] Giant Ox buff expired")
        end
    end

    -- Update Oak Remedy moodle
    if modData.ZM_OakRemedyEndTime then
        if currentTime >= modData.ZM_OakRemedyEndTime then
            -- Duration expired, remove moodle
            local moodle = MF.getMoodle("OakRemedy")
            if moodle then
                moodle:setValue(0)
            end
            modData.ZM_OakRemedyEndTime = nil
            print("[ZM_BuffMoodle] Oak Remedy indicator expired")
        end
    end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

Events.OnCreatePlayer.Add(validPlayer)
-- Use OnPlayerUpdate and throttle inside updateMoodles for responsiveness
Events.EveryOneMinute.Add(ZM_BuffMoodle.updateMoodles)

print("[ZM_BuffMoodle] Module loaded successfully")

return ZM_BuffMoodle
