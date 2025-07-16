
function countTankZedsInCell()
    if not TankZedModII then
      print("TankZedModII is not initialized.")
      return 0
    end

    local cell = getPlayer():getCell()
    local zombies = cell:getZombieList()
    local count = 0

    if not zombies:isEmpty() then
        for i = 0, zombies:size() - 1 do
            local zed = zombies:get(i)
            if TankZedModII.isTankZed(zed) then
                count = count + 1
            end
        end
    end

    print("Tank Zeds in current cell: " .. count)
    return count
end


function countTankZedsInRadius(player, radius)
    if not TankZedModII then
        print("TankZedModII is not initialized.")
        return 0
    end

    local cell = player:getCell()
    local x, y, z = player:getX(), player:getY(), player:getZ()
    local count = 0

    for xDelta = -radius, radius do
        for yDelta = -radius, radius do
            local sq = cell:getGridSquare(x + xDelta, y + yDelta, z)
            if sq then
                local zed = sq:getZombie()
                if zed and TankZedModII.isTankZed(zed) then
                    count = count + 1
                end
            end
        end
    end

    print("Tank Zeds within " .. radius .. " tiles: " .. count)
    return count
end