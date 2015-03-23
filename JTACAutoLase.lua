-- User: Ciaran
-- Date: 18/03/2015
-- Time: 20:48
-- Tells a JTAC to lase a target
-- Usage: Load the script at the start of the mission. With Trigger Once at start of mission -  JTACAutoLase('Source1', 1688)
-- Where Source1 is the Group name of the JTAC Group with one and only one JTAC unit.
--
-- NOTE: Each JTAC must be in a separate group to other JTACS and must not have any other units in it's group
--
-- Bugs and Limitations... JTAC will try to lase targets through buildings... this can be limited by changing the maxDistance
--
-- Last Edit:  20/03/2015 
--
-- Change log: Fixed JTAC lasing through terrain. 
--				Fixed Lase staying on when JTAC Dies
--				Fixed Lase staying on when target dies and there are no other targets
--				Addes Radio noise when message is shown
-- CONFIG
maxDistanceJTAC = 2500 -- How far a JTAC can "see"

smokeOn=false

-- END CONFIG
--
-- TODO, make it so JTACs can't lase the same target
-- TODO Make JTAC lase Vehicles first then Soldiers? Not sure if this is a good idea or not..



-- Dont Modify below here

GLOBAL_JTAC_LASE = {}
GLOBAL_JTAC_IR = {}
GLOBAL_JTAC_SMOKE = {}

function JTACAutoLase(jtacGroupName, laserCode, currentTargetName, currentTargetType)

    -- env.info('JTACAutoLase '..jtacGroupName.." "..laserCode.." "..currentTargetName:toString())

    local jtacGroup = getGroup(jtacGroupName)

    if jtacGroup == nil or #jtacGroup == 0 then
     
     	notify("JTAC Group " .. jtacGroupName .. " KIA!",10)
		
        return
    end

    -- clear laser - just in case
    cancelLase(jtacGroupName)

    -- search for current unit

    if jtacGroup[1]:isActive() == false then


        env.info(jtacGroupName..' Not Active - Waiting 30 seconds')
        timer.scheduleFunction(timerJTACAutoLase, {jtacGroupName,laserCode,nil,nil} , timer.getTime() + 30)

        return

    end

    local enemyUnit = getCurrentUnit(currentTargetName, jtacGroup[1])

    if enemyUnit == nil and currentTargetName ~=nil then
    	notify(jtacGroupName .. " target ".. currentTargetType .. " lost. Scanning for Targets. ", 10)
    end


    if enemyUnit == nil then
        enemyUnit = findNearestVisibleEnemy(jtacGroup[1])
		
        if enemyUnit ~= nil then

            currentTargetType = enemyUnit:getTypeName()

        	notify(jtacGroupName .. " lasing new target ".. enemyUnit:getTypeName() ..'. CODE: '..laserCode , 10)

			
        end
    end

    if enemyUnit ~= nil then

        laseUnit(enemyUnit, jtacGroup[1], jtacGroupName, laserCode)

     --   env.info('Timer timerSparkleLase '..jtacGroupName.." "..laserCode.." "..enemyUnit:getName())
        timer.scheduleFunction(timerJTACAutoLase, {jtacGroupName,laserCode,enemyUnit:getName(),enemyUnit:getTypeName()}, timer.getTime() + 1)

    else
        env.info('LASE: No Enemies Nearby')

		-- stop lazing the old spot
		cancelLase(jtacGroupName)
      --  env.info('Timer Slow timerSparkleLase '..jtacGroupName.." "..laserCode.." "..enemyUnit:getName())

        timer.scheduleFunction(timerJTACAutoLase, {jtacGroupName,laserCode,nil,nil} , timer.getTime() + 5)

    end
end


-- used by the timer function
function timerJTACAutoLase(args)

    JTACAutoLase(args[1], args[2], args[3],args[4])

end

function notify(message, displayFor)


   trigger.action.outTextForCoalition(coalition.side.BLUE, message,displayFor)
   trigger.action.outSoundForCoalition(coalition.side.BLUE, "radiobeep.ogg")	

end

function cancelLase(jtacGroupName)

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

function laseUnit(enemyUnit, jtacUnit, jtacGroupName,laserCode)

	cancelLase(jtacGroupName)

    local spots = {}

    local enemyVector = enemyUnit:getPoint()
    local enemyVectorUpdated = {x = enemyVector.x, y = enemyVector.y + 2.0, z = enemyVector.z}
    local status, result = pcall(function ()
        spots['irPoint'] = Spot.createInfraRed(jtacUnit, {x = 0, y = 2.0, z = 0}, enemyVectorUpdated)
        spots['laserPoint'] = Spot.createLaser(jtacUnit, {x = 0, y = 2.0, z = 0}, enemyVectorUpdated, laserCode)
        return spots
    end)

  --  env.info('Loaded Lazing')

    if not status then
        env.error('ERROR: ' .. assert(result), false)
    else
        if result.irPoint then
           
        --    env.info(jtacUnit:getName() .. ' placed IR Pointer on '..enemyUnit:getName())

            GLOBAL_JTAC_IR[jtacGroupName] = result.irPoint --store so we can remove after
        end
        if result.laserPoint then
		
		--	env.info(jtacUnit:getName() .. ' is Lasing '..enemyUnit:getName()..'. CODE:'..laserCode)
          
            GLOBAL_JTAC_LASE[jtacGroupName] = result.laserPoint

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

    if unit ~=nil and unit:isActive() == true and unit:getLife() > 0 then

        -- calc distance
        tempPoint = unit:getPoint()
     --   tempPosition = unit:getPosition()

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

                	if units[x]:isActive() == true then

                        -- calc distance
                        tempPoint = units[x]:getPoint()
                       -- tempPosition = units[x]:getPosition()

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
    end


    if nearestUnit == nil then
        return nil
    end


    return nearestUnit
end


-- Returns only alive units from group but the group / unit may not be active

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

    return math.sqrt(xDiff * xDiff + yDiff * yDiff)
end

--[[

    Logic
    - Initialise with JTAC name
        - JTAC searches through all groups and picks the nearest (non troop?) target to it
            - starts lazing
        - if nothing but troops, lase troops
            - every second, check that unit is still visible, if not restart

        ]]


