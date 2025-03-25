ZMBanditHandler = {}

-- Spawns multiple powerful bandits at the specified coordinates
-- @param count - number of bandits to spawn
-- @param x - x coordinate (optional - uses player position if nil)
-- @param y - y coordinate (optional - uses player position if nil)
-- @param player - The player initiating the spawn (needed for sendClientCommand)
function ZMBanditHandler.spawnMultipleBandits(count, x, y, player)
  if not player then return end
  if not count or count <= 0 then count = 1 end

  -- Use player's position if coordinates not provided
  local spawnX = x
  local spawnY = y

  if spawnX == nil or spawnY == nil then
      spawnX = player:getX()
      spawnY = player:getY()
  end

  local event = {}
  event.hostile = true
  event.program = {}
  event.program.name = "Bandit"
  event.program.stage = "Prepare"
  event.x = spawnX
  event.y = spawnY
  event.bandits = {}

  -- Add multiple bandits to the event
  for i = 1, count do
      local bandit = {}
      bandit.clan = 1
      bandit.health = 8.0
      bandit.femaleChance = 50
      bandit.eatBody = false
      bandit.accuracyBoost = 1.5
      bandit.outfit = "Police"

      bandit.weapons = {}
      bandit.melee = "Base.Axe"

      bandit.primary = {}
      bandit.primary.name = "Base.AssaultRifle2"
      bandit.primary.magSize = 30
      bandit.primary.magCount = 5
      bandit.primary.bulletsLeft = 15

      bandit.secondary = {}
      bandit.secondary.name = "Base.Pistol"
      bandit.secondary.magSize = 15
      bandit.secondary.magCount = 3
      bandit.secondary.bulletsLeft = 15

      bandit.hairStyle = "Fabian"
      bandit.hairColor = {r=0.1, g=0.2, b=0.3}
      bandit.beardStyle = "Fabian"
      bandit.beardColor = {r=0.1, g=0.2, b=0.3}

      table.insert(event.bandits, bandit)
  end

  sendClientCommand(player, 'Commands', 'SpawnGroup', event)
  return true
end