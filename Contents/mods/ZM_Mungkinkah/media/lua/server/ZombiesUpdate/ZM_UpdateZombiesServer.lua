ZM_ZombieUpdateServer = ZM_ZombieUpdateServer or {}
ZM_ZombieIndex = ZM_ZombieIndex or {} -- server-side mapping uuid -> info




local function makeUUID()
    local _tostring = tostring or function(v) return "" .. (v == nil and "nil" or v) end
    local now = 0
    if type(os) == "table" and type(os.time) == "function" then
        now = os.time() or 0
    elseif type(os) == "table" and type(os.clock) == "function" then
        now = math.floor(os.clock() * 1000)
    end

    local r1, r2
    if type(math) == "table" and type(math.random) == "function" and type(math.floor) == "function" then
        r1 = math.random(1, 9999999)
        r2 = math.floor(math.random() * 10000)
    else
        -- fallback deterministic-ish values if math.random is unavailable
        r1 = (now % 9999999) + 1
        r2 = (now % 10000)
    end

    return _tostring(now) .. "_" .. _tostring(r1) .. "_" .. _tostring(r2)
end

function ZM_ZombieUpdateServer.spawnZombieAtCoords(player, args)
    local zombieType = args.type or "SCP001"
    local x = args.x or 0
    local y = args.y or 0
    local z = args.z or 0
    local count = args.count or 1
    local baseHP = 150;
    local walkType = "sprint"
    local canSprint = true
    local outfit = "ArmyCamoGreen"
    local profession = "Soldier"
    local zombName = "SCP001"

    -- spawn 'count' zombies (use count instead of hardcoded 1)
    addZombiesInOutfit(
        x, y, z, count,
        outfit,
        0.5,
        false,
        false,
        false,
        false,
        1.0
    )

    local square = getCell():getGridSquare(x, y, z or 0)
    if not square then
        print("ZM_ZombieUpdateServer: no square at coords")
        return nil
    end

    local zombies = square:getMovingObjects()
    local setCount = 0
    local broadcastEntries = {}

    for i = zombies:size() - 1, 0, -1 do
        local obj = zombies:get(i)
        if instanceof(obj, "IsoZombie") then

            obj:setHealth(baseHP)
            obj:setWalkType(walkType)

            setCount = setCount + 1
            if setCount >= count then break end
        end
    end

    -- send spawn result to caller
    sendServerCommand(player, "ZM_UpdateZombieResponse", "zombieSpawned", {
        count = setCount, x = x, y = y, z = z
    })

    -- broadcast new/updated index entries to all online players
    local online = getOnlinePlayers()
    if online then
        for i = 0, online:size() - 1 do
            local p = online:get(i)
            sendServerCommand(p, "ZM_UpdateZombieResponse", "syncZombieIndex", { zombies = broadcastEntries })
        end
    end
end

function ZM_ZombieUpdateServer.decrementGracePeriod(zombieId, damageNegationCount)
    local damageGracePeriod = {}
    damageGracePeriod.zombieId = zombieId
    damageGracePeriod.damageNegationCount = damageNegationCount - 1
    -- return damageGracePeriod
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "ZM_UpdateZombie" then
        if command == "spawnZombieAtCoords" then
          ZM_ZombieUpdateServer.spawnZombieAtCoords(player, args)
        elseif command == "setHealth" then
          ZM_ZombieUpdateServer.modifyZed(args.zombie, args.health, args.damageNegationCount, args.extraData)
        elseif command == "test3" then

        elseif command == "test4" then

        end
    end
end)
