-- -- Custom function to spawn a bandit with specific properties
-- function SpawnCustomBandit(x, y, z, options)
--     -- Default options
--     options = options or {}
--     local player = getSpecificPlayer(0)

--     -- Create spawn arguments
--     local args = {
--         x = x,
--         y = y,
--         z = z,
--         cid = options.clanId or 1,  -- Default to clan 1
--         bid = options.banditId,     -- Specific bandit type from clan
--         program = options.program or "Bandit", -- Default program
--         hostile = options.hostile,  -- If bandit should be hostile
--         hostileP = options.hostileP, -- If bandit should be hostile to players
--         permanent = options.permanent or false, -- If bandit should persist
--         occupation = options.occupation,  -- Occupation for specific behaviors
--         loyal = options.loyal or false,   -- If bandit is loyal (for companions)
--         pid = BanditUtils.GetCharacterID(player) -- Set spawner as master
--     }

--     -- Send command to server to spawn the bandit
--     sendClientCommand(player, 'Spawner', 'Type', args)

--     -- Optionally add a marker on map if specified
--     if options.addMarker then
--         local color = options.hostile and {r=1, g=0.5, b=0.5} or {r=0.5, g=1, b=0.5}
--         local desc = options.markerDesc or (options.hostile and "Hostile Bandit" or "Friendly Bandit")
--         local icon = "media/ui/BanditMarker.png" -- Make sure this texture exists

--         local markerArgs = {
--             icon = icon,
--             time = 60, -- Duration in minutes
--             x = x,
--             y = y,
--             color = color,
--             desc = desc
--         }

--         -- Set marker on map
--         BanditEventMarkerHandler.set(getRandomUUID(), markerArgs.icon, markerArgs.time,
--                                     markerArgs.x, markerArgs.y, markerArgs.color, markerArgs.desc)
--     end

--     return true
-- end