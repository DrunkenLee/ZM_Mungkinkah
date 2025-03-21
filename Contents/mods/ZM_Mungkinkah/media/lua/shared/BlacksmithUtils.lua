--***********************************************************
--**                    BLACKSMITH UI UTILS                **
--***********************************************************

local BlacksmithUI = {}

-- Store UI instance for reference
BlacksmithUI.instance = nil
BlacksmithUI.isVisible = false

-- Utility functions
BlacksmithUI.tableSize = function(t)
    local c = 0
    for _ in pairs(t) do
        c = c + 1
    end
    return c
end

-- Get instance function to access from other files
function getBlacksmithUIInstance()
    return BlacksmithUI
end