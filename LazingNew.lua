--
-- Created by IntelliJ IDEA.
-- User: Ciaran
-- Date: 18/03/2015
-- Time: 20:48
-- Tells a JTAC to lase a target
-- Usage: Load the script at the start of the mission. With Trigger Once at start of mission -  InitSparkleLase('Source1', 1688)
-- Where Source1 is the Group name of the JTAG Group.
--
-- NOTE: Each JTAC must be in a separate group to other JTACS and must not have any other units in it's group
--
-- Bugs and Limitations... Jtag will try to laze targets through buildings... this can be limited by changing the maxDistance
--
-- Last Edit:  20/03/2015 
--
-- Change log: Fixed JTAC lasing through terrain. 
--				Fixed Lase staying on when JTAC Dies
--				Fixed Lase staying on when target dies and there are no other targets
-- CONFIG
maxDistanceJTAC = 2500 -- How far a JTAG can "see"
-- END CONFIG
--
-- TODO, make it so JTAC can't lase the same target
-- TODO Make JTAC lase Vehicles first then Soldiers

--[[

    Logic
    - Initialise with JTAC name
        - JTAC searches through all groups and picks the nearest non troop to it
            - starts lazing
        - if nothing but troops, lase troops
            - every second, check that unit is still visible, if not restart

        ]]


-- Dont Modify below here

GLOBAL_JTAC_LASE = {}
GLOBAL_JTAC_IR = {}

function InitSparkleLase(jtacGroupName, laserCode, currentTargetName, currentTargetType)

    -- env.info('InitSparkleLase '..jtacGroupName.." "..laserCode.." "..currentTargetName:toString())

    local jtacGroup = getGroup(jtacGroupName)

    if jtacGroup == nil or #jtacGroup == 0 then
        trigger.action.outText("JTAC Group " .. jtacGroupName .. " KIA!", 5)
		
		-- clear laser
		cancelLaze(jtacGroupName)
		
		
        return
    end

    -- search for current unit

    local enemyUnit = getCurrentUnit(currentTargetName, jtacGroup[1])

    if enemyUnit == nil and currentTargetName ~=nil then
        trigger.action.outText( jtacGroupName .. " target ".. currentTargetType .. " lost. Scanning for Targets. ", 5)
    end


    if enemyUnit == nil then
        enemyUnit = findNearestVisibleEnemy(jtacGroup[1])
		
        if enemyUnit ~= nil then
            trigger.action.outText(jtacGroupName .. " lazing new target ".. enemyUnit:getTypeName() , 10)
			currentTargetType = enemyUnit:getTypeName()
			
        end
    end

    if enemyUnit ~= nil then

        lazeUnit(enemyUnit, jtacGroup[1], jtacGroupName, laserCode)

     --   env.info('Timer timerSparkleLase '..jtacGroupName.." "..laserCode.." "..enemyUnit:getName())
        timer.scheduleFunction(timerSparkleLase, {jtacGroupName,laserCode,enemyUnit:getName(),enemyUnit:getTypeName()}, timer.getTime() + 1)

    else
        env.info('LAZE: No Enemies Nearby')

		-- stop lazing the old spot
		cancelLaze(jtacGroupName)
      --  env.info('Timer Slow timerSparkleLase '..jtacGroupName.." "..laserCode.." "..enemyUnit:getName())

        timer.scheduleFunction(timerSparkleLase, {jtacGroupName,laserCode,nil,nil} , timer.getTime() + 5)

    end
end


-- used by the timer function
function timerSparkleLase(args)

    InitSparkleLase(args[1], args[2], args[3],args[4])

end

function cancelLaze(jtacGroupName)

	--local index = "JTAC_"..jtacUnit:getID()

    local tempLase = GLOBAL_JTAC_LASE[jtacGroupName]

    if tempLase ~= nil then
        Spot.destroy(tempLase)
        GLOBAL_JTAC_LASE[jtacGroupName] = nil

  --      env.info('Destroy laze  '..index)

        tempLase = nil
    end

    local tempIR = GLOBAL_JTAC_IR[jtacGroupName]

    if tempIR ~= nil then
        Spot.destroy(tempIR)
        GLOBAL_JTAC_IR[jtacGroupName] = nil

      --  env.info('Destroy laze  '..index)

        tempIR = nil
    end

end

function lazeUnit(enemyUnit, jtacUnit, jtacGroupName,laserCode)

	cancelLaze(jtacGroupName)

    local spots = {}

    local enemyVector = enemyUnit:getPoint()
    local enemyVectorUpdated = {x = enemyVector.x, y = enemyVector.y + 2, z = enemyVector.z}
    local status, result = pcall(function ()
        spots['Sparkle'] = Spot.createInfraRed(jtacUnit, {x = 0, y = 2, z = 0}, enemyVectorUpdated)
        spots['Laser'] = Spot.createLaser(jtacUnit, {x = 0, y = 2, z = 0}, enemyVectorUpdated, laserCode)
        return spots
    end)

  --  env.info('Loaded Lazing')

    if not status then
        env.error('ERROR: ' .. assert(result), false)
    else
        if result.Sparkle then
            local Sparkle = result.Sparkle
            env.info(jtacUnit:getName() .. ' is Lazing '..enemyUnit:getName())

            GLOBAL_JTAC_IR[jtacGroupName] = Sparkle --store so we can remove after
        end
        if result.Laser then
            local Laser = result.Laser

            GLOBAL_JTAC_LASE[jtacGroupName] = Laser

        end
    end




end

-- get currently selected unit and check they're still in range
function getCurrentUnit(currentTargetName, jtacUnit)

    if currentTargetName == nil then
        return nil
    end

    local unit = Unit.getByName(currentTargetName)

    local tempPoint = nil
    local tempDist = nil
    local tempPosition = nil

    local jtacPosition = jtacUnit:getPosition()
    local jtacPoint = jtacUnit:getPoint()

    if unit ~=nil and unit:getLife() > 0 then

        -- calc distance
        tempPoint = unit:getPoint()
        tempPosition = unit:getPosition()

        tempDist = getDistance(tempPoint.x, tempPoint.z, jtacPoint.x, jtacPoint.z)
        if tempDist < maxDistanceJTAC  then
            -- calc visible
			
			-- check slightly above the target as rounding errors can cause issues, plus the unit has some height anyways
			local offsetEnemyPos = {x = tempPoint.x, y = tempPoint.y + 2.0 , z = tempPoint.z }
			local offsetJTACPos = {x = jtacPoint.x, y = jtacPoint.y+2.0 , z = jtacPoint.z}
			
            if land.isVisible(offsetEnemyPos, offsetJTACPos) then
                return unit
            end
			
        end
    end
    return nil

end


-- Find nearest enemy to JTAC that isn't blocked by terrain
function findNearestVisibleEnemy(jtacUnit)

    local x = 1
    local i = 1

    local units = nil
    local groupName = nil

    local nearestUnit = nil
    local nearestDistance = maxDistanceJTAC

    local redGroups = coalition.getGroups(1, Group.Category.GROUND)

    local jtacPoint = jtacUnit:getPoint()
    local jtacPosition = jtacUnit:getPosition()

    local tempPoint = nil
    local tempPosition = nil

    local tempDist = nil

    -- finish this function
    for i = 1, #redGroups do
        if redGroups[i] ~= nil then
            groupName = redGroups[i]:getName()
            units = getGroup(groupName)
            if #units > 0 then

                for x = 1, #units do

                    -- calc distance
                    tempPoint = units[x]:getPoint()
                    tempPosition = units[x]:getPosition()

                    tempDist = getDistance(tempPoint.x, tempPoint.z, jtacPoint.x, jtacPoint.z)

               --     env.info("tempDist" ..tempDist)
                --    env.info("maxDistanceJTAC" ..maxDistanceJTAC)

                    if tempDist < maxDistanceJTAC and tempDist < nearestDistance then

						local offsetEnemyPos = {x = tempPoint.x, y = tempPoint.y + 2.0 , z = tempPoint.z }
						local offsetJTACPos = {x = jtacPoint.x, y = jtacPoint.y+2.0 , z = jtacPoint.z}
			
			
                        -- calc visible
                        if land.isVisible(offsetEnemyPos,offsetJTACPos) then

                            nearestDistance = tempDist
                            nearestUnit = units[x]

                        end
                    end
                end
            end
        end
    end


    if nearestUnit == nil then
        return nil
    end


    return nearestUnit
end


-- Returns only alive units from group

function getGroup(groupName)

    local groupUnits = Group.getByName(groupName)

    local filteredUnits = {} --contains alive units
    local x = 1

    if groupUnits ~= nil then

        groupUnits = groupUnits:getUnits()

        if groupUnits ~= nil and #groupUnits > 0 then
            for x = 1, #groupUnits do
                if groupUnits[x]:getLife() > 0 then
                    table.insert(filteredUnits, groupUnits[x])
                end
            end
        end
    end

    return filteredUnits
end

-- Distance measurement between two positions, assume flat world

function getDistance(xUnit, yUnit, xZone, yZone)
    local xDiff = xUnit - xZone
    local yDiff = yUnit - yZone
--
--    env.info("xUnit" ..xUnit)
--    env.info("yUnit" ..yUnit)
--    env.info("xZone" ..xZone)
--    env.info("yZone" ..yZone)

    return math.sqrt(xDiff * xDiff + yDiff * yDiff)
end



