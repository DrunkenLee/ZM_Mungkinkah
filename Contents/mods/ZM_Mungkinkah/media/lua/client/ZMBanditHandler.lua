-- ZMBanditHandler = {}

-- function ZMBanditHandler.spawnMultipleBandits(count, x, y, player)
--   -- Validate parameters
--   count = count or 1
--   if not player then
--     player = getSpecificPlayer(0)
--     if not player then
--       print("ERROR: Player not found")
--       return nil
--     end
--   end

--   -- Create event configuration
--   local event = {}
--   event.hostile = true -- determines if the spawned bandits will be hostile towards any player

--   event.program = {}
--   event.program.name = "Bandit" -- determines name of the behavioral program
--   event.program.stage = "Prepare" -- determines name of the initial stage of behavioral program

--   -- Use provided coordinates or player position if not specified
--   if x and y then
--     event.x = x -- coordinates of the spawn point
--     event.y = y
--   elseif player then
--     event.x = player:getX()
--     event.y = player:getY()
--   else
--     event.x = 10000 -- fallback coordinates
--     event.y = 10000
--   end

--   event.bandits = {}

--   -- Create specified number of bandits
--   for i = 1, count do
--     local bandit = {} -- Use local to avoid global variable
--     bandit.clan = 1 -- any integer here
--     bandit.health = 2.0 -- float, dont use smaller than 1 and higher than 8
--     bandit.femaleChance = 50 -- integers from 0 - 100
--     bandit.eatBody = false -- boolean
--     bandit.accuracyBoost = 1.0 -- float value, 1.5 is actually a big boost
--     bandit.outfit = "Police" -- name of the outfit (check clothing.xml)

--     bandit.weapons = {}
--     bandit.melee = "Base.Axe" -- item fullType

--     bandit.primary = {}
--     bandit.primary.name = "Base.AssaultRifle2" -- itemType
--     bandit.primary.magSize = 30
--     bandit.primary.magCount = 5 -- number of extra mags
--     bandit.primary.bulletsLeft = 15 -- how many bullets in currently loaded magazine

--     bandit.secondary = {}
--     bandit.secondary.name = "Base.Pistol" -- itemType
--     bandit.secondary.magSize = 15
--     bandit.secondary.magCount = 3 -- number of extra mags
--     bandit.secondary.bulletsLeft = 2 -- how many bullets in currently loaded magazine

--     -- optional:
--     bandit.hairStyle = "Fabian"
--     bandit.hairColor = {r=0.1, g=0.2, b=0.3}
--     bandit.beardStyle = "Fabian"
--     bandit.beardColor = {r=0.1, g=0.2, b=0.3}

--     table.insert(event.bandits, bandit)
--   end

--   -- Send command to spawn bandits
--   sendClientCommand(player, 'Commands', 'SpawnGroup', event)
--   print("Sent command to spawn " .. count .. " bandit(s) at x=" .. event.x .. ", y=" .. event.y)
--   return event -- Return event data for debugging
-- end

-- -- Function to spawn a single bandit (convenience function)
-- function ZMBanditHandler.spawnBandit(x, y, player)
--   return ZMBanditHandler.spawnMultipleBandits(1, x, y, player)
-- end

-- -- Function to spawn bandits at a random position near the player
-- function ZMBanditHandler.spawnBanditsNearby(count, distance, player)
--   player = player or getSpecificPlayer(0)
--   if not player then return nil end

--   distance = distance or 20
--   local angle = ZombRand(0, 360)
--   local radians = math.rad(angle)

--   local x = player:getX() + (distance * math.cos(radians))
--   local y = player:getY() + (distance * math.sin(radians))

--   return ZMBanditHandler.spawnMultipleBandits(count, x, y, player)
-- end

-- -- Function to spawn ambush (bandits surrounding player)
-- function ZMBanditHandler.spawnAmbush(count, distance, player)
--   player = player or getSpecificPlayer(0)
--   if not player then return nil end

--   distance = distance or 15
--   count = count or 4
--   local bandits = {}

--   -- Place bandits in a circle around the player
--   for i = 1, count do
--     local angle = ((i-1) * (360/count))
--     local radians = math.rad(angle)

--     local x = player:getX() + (distance * math.cos(radians))
--     local y = player:getY() + (distance * math.sin(radians))

--     table.insert(bandits, ZMBanditHandler.spawnMultipleBandits(1, x, y, player))
--   end

--   print("Spawned ambush of " .. count .. " bandits around player")
--   return bandits
-- end

-- print("[ZM_Mungkinkah] ZMBanditHandler loaded")