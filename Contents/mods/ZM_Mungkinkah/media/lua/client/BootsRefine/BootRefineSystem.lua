--***********************************************************
--**          BOOT REFINE SYSTEM INITIALIZATION           **
--**              Ties UI and Handler together            **
--***********************************************************

-- Ensure required modules are loaded
require "BootsRefine/BootRefineHandler"
require "ISUI/ISBootRefineUI"

-- Initialize the refinement system
local BootRefineSystem = {}

-- System initialization
function BootRefineSystem.initialize()
    print("[BootRefineSystem] Initializing equipment refinement system...")

    -- Verify handler is loaded
    if not BootRefineHandler then
        print("[BootRefineSystem] ERROR: BootRefineHandler not found!")
        return false
    end

    -- Verify UI is loaded
    if not ISBootRefineUI then
        print("[BootRefineSystem] ERROR: ISBootRefineUI not found!")
        return false
    end

    print("[BootRefineSystem] System initialized successfully")
    return true
end

-- Keybind for opening UI
function BootRefineSystem.openRefinementUI()
    if showBootRefineUI then
        showBootRefineUI()
        print("[BootRefineSystem] Refinement UI opened")
    else
        print("[BootRefineSystem] ERROR: showBootRefineUI function not found")
    end
end

-- Console commands for testing
function BootRefineSystem.testSystem()
    print("=== Boot Refinement System Test ===")

    -- Test handler
    if BootRefineHandler and BootRefineHandler.testUIIntegration then
        BootRefineHandler.testUIIntegration()
    end

    -- Test UI
    BootRefineSystem.openRefinementUI()

    print("=== Test Complete ===")
end

-- Initialize on game start
Events.OnGameStart.Add(function()
    BootRefineSystem.initialize()
end)

-- Global access for console
_G.BootRefineSystem = BootRefineSystem
_G.OpenBootRefine = BootRefineSystem.openRefinementUI
_G.TestBootRefine = BootRefineSystem.testSystem

print("[BootRefineSystem] System loader initialized")
