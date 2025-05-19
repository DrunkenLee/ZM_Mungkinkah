-- Add to NightSprintersv2.lua
function clientToggleNS(enable)
    if enable then
        NSenable()
    else
        NSdisable()
    end
end

-- Listen for a client-side event
Events.OnKeyPressed.Add(function(key)
    -- Example: F5 enables, F6 disables
    print("Key pressed: " .. key)
    if key == 116 then -- F5
        clientToggleNS(true)
    elseif key == 117 then -- F6
        clientToggleNS(false)
    end
end)