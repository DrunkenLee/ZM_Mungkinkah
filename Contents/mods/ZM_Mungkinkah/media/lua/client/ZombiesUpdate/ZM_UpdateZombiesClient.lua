ZM_ZombieUpdate = ZM_ZombieUpdate or {}
ZM_ZombieIndex = ZM_ZombieIndex or {}


local function findZombieByUUIDInSquare(sq, uuid)
    if not sq then return nil end
    local objs = sq:getMovingObjects()
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        if instanceof(obj, "IsoZombie") then
            local md = obj:getModData() or {}
            if md._zm_uuid == uuid then return obj end
        end
    end
    return nil
end

local function findNearestZombieInSquare(sq, data)
    if not sq then return nil end
    local best, bd = nil, math.huge
    local objs = sq:getMovingObjects()
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        if instanceof(obj, "IsoZombie") then
            local dx = obj:getX() - data.x
            local dy = obj:getY() - data.y
            local d2 = dx*dx + dy*dy
            if d2 < bd then bd = d2; best = obj end
        end
    end
    if bd <= (1.5 * 1.5) then return best end
    return nil
end

ZM_ZombieUpdate.spawnZombieAtCoords = function(coords, args)
  local zombieType = args.type or "SCP001"
  local x = coords.x or 0
  local y = coords.y or 0
  local z = coords.z or 0
  local count = args.count or 1

  sendClientCommand("ZM_UpdateZombie", "spawnZombieAtCoords", {
    type = zombieType,
    x = x,
    y = y,
    z = z,
    count = count
  })
end


ZM_ZombieUpdate.printZombiesModDataInRadius = function(radius)
  radius = radius or 10
  local player = getPlayer()
  if not player then
    print("ZM_ZombieUpdate: no local player found")
    return
  end

  local px, py, pz = player:getX(), player:getY(), player:getZ()
  local found = 0
  print(string.format("ZM_ZombieUpdate: scanning radius %d around player at (%d,%d,%d)", radius, px, py, pz))

  local cell = getCell()
  for dx = -radius, radius do
    for dy = -radius, radius do
      local sq = cell:getGridSquare(px + dx, py + dy, pz)
      if sq then
        local objs = sq:getMovingObjects()
        for i = 0, objs:size() - 1 do
          local obj = objs:get(i)
          if instanceof(obj, "IsoZombie") then
            found = found + 1
            local zx, zy, zz = obj:getX(), obj:getY(), obj:getZ()
            print(string.format(" Zombie #%d at (%d,%d,%d):", found, zx, zy, zz))
            -- don't print the raw table; the code below will iterate and print modData entries
            local md = obj:getModData() or {}
            local empty = true
            for k, v in pairs(md) do
              empty = false
              print("  " .. tostring(k) .. " = " .. tostring(v))
            end
            if empty then
              print("  <modData empty>")
            end
          end
        end
      end
    end
  end

  print("ZM_ZombieUpdate: total zombies found = " .. tostring(found))
end

local function printTable(root, indent, visited)
  indent = indent or ""
  visited = visited or {}
  if type(root) ~= "table" then
    print(indent .. tostring(root))
    return
  end
  if visited[root] then
    print(indent .. "<cycle>")
    return
  end
  visited[root] = true

  -- collect and sort keys for stable output
  local keys = {}
  for k in pairs(root) do table.insert(keys, k) end
  table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)

  for _, k in ipairs(keys) do
    local v = root[k]
    local kstr = tostring(k)
    local vtype = type(v)
    if vtype == "table" then
      print(indent .. kstr .. " = {")
      printTable(v, indent .. "  ", visited)
      print(indent .. "}")
    else
      print(indent .. kstr .. " = " .. tostring(v))
    end
  end

  visited[root] = nil
end

local function ZM_UpdateOnHitZombie(zombie, attacker, bodyPart, weapon)
    if not zombie or not instanceof(zombie, "IsoZombie") then return end

    local md = zombie:getOutfitName() or "Random"
    local usingLegendWeapon = false
    local weaponName = "Unknown"

    if weapon then
      print("ADA KOK WEAPON NYA")
      weaponName = weapon:getName() or "Unknown"
    end

    if string.find(weaponName, "Legend") or string.find(weaponName, "+10") then
      print("Legendary weapon detected: " .. weaponName)
      usingLegendWeapon = true
    end

    local isElite = false
    if md == "ArmyCamoGreen" then
        isElite = true
    end

    if weapon and isElite and not usingLegendWeapon then
        local playerSayRoll = ZombRand(0 , 100)
        if playerSayRoll > 95 then
          getPlayer():Say("Fookin hell, i need a legendary weapon for this elite zombie!")
        end
        local avoidDmgRoll = ZombRand(0, 100)
        if avoidDmgRoll < 95 then
          zombie:setAvoidDamage(true)
          -- zombie:setNoDamage(true, 0)
          zombie:setVariable("hitreaction", "TankZed_HitReact")
        end
    end
end

local function ZM_OnWeaponHitCharacter(attacker, target, weapon, damage)
    if target and instanceof(target, "IsoZombie") then
        print(weapon)
        ZM_UpdateOnHitZombie(target, attacker, bodyPart, weapon)
    end
end

-- Events.OnWeaponHitCharacter.Add(ZM_OnWeaponHitCharacter) -- disabled due to contra with new projectile

-- Events.OnHitZombie.Add(ZM_UpdateOnHitZombie)


Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "ZM_UpdateZombieResponse" then return end
    if command == "syncZombieIndex" and args.zombies then
        local cell = getCell()
        for _, data in ipairs(args.zombies) do
            ZM_ZombieIndex[data.uuid] = data -- local cache

            -- try uuid match first, then position fallback
            local sq = cell:getGridSquare(data.x, data.y, data.z)
            local obj = findZombieByUUIDInSquare(sq, data.uuid)
            if not obj then obj = findNearestZombieInSquare(sq, data) end

            if obj then
                local md = obj:getModData() or {}
                md._zm_uuid = data.uuid
                md.name = data.name
                md._scpNegations = data.negations
                print(string.format("Client: applied server data uuid=%s name=%s -> local zombie at (%.1f,%.1f,%.1f)",
                    tostring(data.uuid), tostring(data.name), obj:getX(), obj:getY(), obj:getZ()))
            else
                print(string.format("Client: couldn't match server zombie uuid=%s at (%.1f,%.1f,%.1f)", data.uuid, data.x, data.y, data.z))
            end
        end
    end
end)