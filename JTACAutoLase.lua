--
-- Tells a JTAC to lase a target
-- Usage: Load the script at the start of the mission. With Trigger Once at start of mission -  JTACAutoLase('Source1', 1688)
-- Where Source1 is the Group name of the JTAC Group with one and only one JTAC unit.
--
-- NOTE: Each JTAC must be in a separate group to other JTACS and must not have any other units in it's group.
-- Group name must be unique and not be the same as any other Unit's name
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
JTAC_maxDistance = 2500 -- How far a JTAC can "see"

JTAC_smokeOn = true

JTAC_jtacStatusF10 = true

-- END CONFIG
--
-- TODO, make it so JTACs can't lase the same target
-- TODO Make JTAC lase Vehicles first then Soldiers? Not sure if this is a good idea or not..

-- Dont Modify below here

GLOBAL_JTAC_LASE = {}
GLOBAL_JTAC_IR = {}
GLOBAL_JTAC_SMOKE = {}
GLOBAL_JTAC_UNITS = {} -- list of JTAC units for f10 command
GLOBAL_JTAC_CURRENT_TARGETS = {}
GLOBAL_JTAC_RADIO_ADDED = {} --keeps track of who's had the radio command added

--- TODO Change back to make it so we have to lookup JTAC unit and enemy unit each time. When either dies script crashes silently!

function JTACAutoLase(jtacGroupName, laserCode)

    -- env.info('JTACAutoLase '..jtacGroupName.." "..laserCode.." "..currentTargetName:toString())

    -- clear laser - just in case
    cancelLase(jtacGroupName)

    local jtacGroup = getGroup(jtacGroupName)
    local jtacUnit

    if jtacGroup == nil or #jtacGroup == 0 then

        notify("JTAC Group " .. jtacGroupName .. " KIA!",10)

        --remove from list
        GLOBAL_JTAC_UNITS[jtacGroupName] = nil

        cleanupJTAC(jtacGroupName)

        return
    else

        jtacUnit = jtacGroup[1]
        --add to list
        GLOBAL_JTAC_UNITS[jtacGroupName] =jtacUnit:getName()
    end


    -- search for current unit

    if jtacUnit:isActive() == false then

        cleanupJTAC(jtacGroupName)

        env.info(jtacGroupName..' Not Active - Waiting 30 seconds')
        timer.scheduleFunction(timerJTACAutoLase, {jtacGroupName,laserCode} , timer.getTime() + 30)

        return

    end

    local enemyUnit = getCurrentUnit(jtacUnit,jtacGroupName)

    if enemyUnit == nil and GLOBAL_JTAC_CURRENT_TARGETS[jtacGroupName] ~=nil then

		local tempUnitInfo = GLOBAL_JTAC_CURRENT_TARGETS[jtacGroupName]

        env.info("TEMP UNIT INFO: "..tempUnitInfo.name.." "..tempUnitInfo.unitType)

        local tempUnit= Unit.getByName(tempUnitInfo.name)
		
        if tempUnit ~=nil and tempUnit:getLife() > 0 and tempUnit:isActive() == true then
    	    notify(jtacGroupName .. " target ".. tempUnitInfo.unitType .. " lost. Scanning for Targets. ", 10)
        else
            notify(jtacGroupName .. " target "..  tempUnitInfo.unitType .. " KIA. Good Job! Scanning for Targets. ", 10)
        end

        --remove from smoke list
        GLOBAL_JTAC_SMOKE[tempUnitInfo.name] = nil

        -- remove from target list
        GLOBAL_JTAC_CURRENT_TARGETS[jtacGroupName] = nil
    end


    if enemyUnit == nil then
        enemyUnit = findNearestVisibleEnemy(jtacUnit)
		
        if enemyUnit ~= nil then

            -- store current target for easy lookup
            GLOBAL_JTAC_CURRENT_TARGETS[jtacGroupName] = {name =enemyUnit:getName(), unitType = enemyUnit:getTypeName() }

        	notify(jtacGroupName .. " lasing new target ".. enemyUnit:getTypeName() ..'. CODE: '..laserCode , 10)

            -- create smoke
            if JTAC_smokeOn == true then

                --create first smoke
                createSmokeMarker(enemyUnit)

            end

        end
    end

    if enemyUnit ~= nil then

        laseUnit(enemyUnit, jtacUnit, jtacGroupName, laserCode)

     --   env.info('Timer timerSparkleLase '..jtacGroupName.." "..laserCode.." "..enemyUnit:getName())
        timer.scheduleFunction(timerJTACAutoLase, {jtacGroupName,laserCode}, timer.getTime() + 1)


        if JTAC_smokeOn == true then
            local nextSmokeTime = GLOBAL_JTAC_SMOKE[enemyUnit:getName()]

            --recreate smoke marker after 5 mins
            if nextSmokeTime ~= nil and nextSmokeTime < timer.getTime() then

              createSmokeMarker(enemyUnit)

            end
        end

    else
       -- env.info('LASE: No Enemies Nearby')

		-- stop lazing the old spot
		cancelLase(jtacGroupName)
      --  env.info('Timer Slow timerSparkleLase '..jtacGroupName.." "..laserCode.." "..enemyUnit:getName())

        timer.scheduleFunction(timerJTACAutoLase, {jtacGroupName,laserCode} , timer.getTime() + 5)

    end
end


-- used by the timer function
function timerJTACAutoLase(args)

    JTACAutoLase(args[1], args[2])

end

function cleanupJTAC(jtacGroupName)
    -- clear laser - just in case
    cancelLase(jtacGroupName)

    -- Cleanup
    GLOBAL_JTAC_UNITS[jtacGroupName] = nil

    GLOBAL_JTAC_CURRENT_TARGETS[jtacGroupName] = nil

end


function notify(message, displayFor)


   trigger.action.outTextForCoalition(coalition.side.BLUE, message,displayFor)
   trigger.action.outSoundForCoalition(coalition.side.BLUE, "radiobeep.ogg")	

end

function createSmokeMarker(enemyUnit)

    --recreate in 5 mins
    GLOBAL_JTAC_SMOKE[enemyUnit:getName()] = timer.getTime() +300.0

    -- move smoke 2 meters above target for ease
    local enemyPoint = enemyUnit:getPoint()
    trigger.action.smoke({x = enemyPoint.x, y = enemyPoint.y + 2.0, z = enemyPoint.z},trigger.smokeColor.Red)
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
function getCurrentUnit(jtacUnit,jtacGroupName)


    local unit = nil

    if GLOBAL_JTAC_CURRENT_TARGETS[jtacGroupName] ~=nil then
       unit =  Unit.getByName(GLOBAL_JTAC_CURRENT_TARGETS[jtacGroupName].name)
    end

    local tempPoint = nil
    local tempDist = nil
    local tempPosition = nil

    local jtacPosition = jtacUnit:getPosition()
    local jtacPoint = jtacUnit:getPoint()

    if unit ~=nil and unit:getLife() > 0 and unit:isActive() == true then

        -- calc distance
        tempPoint = unit:getPoint()
     --   tempPosition = unit:getPosition()

        tempDist = getDistance(tempPoint.x, tempPoint.z, jtacPoint.x, jtacPoint.z)
        if tempDist < JTAC_maxDistance  then
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
    local nearestDistance = JTAC_maxDistance

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
                    --    env.info("JTAC_maxDistance" ..JTAC_maxDistance)

                        if tempDist < JTAC_maxDistance and tempDist < nearestDistance then

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

function getJTACStatus()

    --returns the status of all JTAC units

    local jtacGroupName = nil
    local jtacUnit = nil
    local jtacUnitName= nil

    local message = "JTAC STATUS: \n\n"

    for jtacGroupName,jtacUnitName in pairs(GLOBAL_JTAC_UNITS) do

        --look up units
        jtacUnit = Unit.getByName(jtacUnitName)

        if jtacUnit~=nil and jtacUnit:getLife() > 0 and jtacUnit:isActive() == true then

            local enemyUnit = getCurrentUnit(jtacUnit,jtacGroupName)

            if enemyUnit ~= nil and enemyUnit:getLife() > 0 and enemyUnit:isActive() == true  then
                message = message ..""..jtacGroupName .. " currently targeting ".. enemyUnit:getTypeName().."\n"
            else
                message = message ..""..jtacGroupName .. " searching for targets\n"
            end

        end

    end
	
	  notify(message,10)
	
end


-- Radio command for players (F10 Menu)

function addRadioCommands()

	--looop over all players and add command
--    missionCommands.addCommandForCoalition( coalition.side.BLUE, "JTAC Status" ,nil, getJTACStatus ,nil)

    timer.scheduleFunction(addRadioCommands, nil, timer.getTime() + 10)

    local blueGroups = coalition.getGroups(coalition.side.BLUE)
    local x = 1

    if blueGroups ~= nil then
        for x, tmpGroup in pairs(blueGroups) do


            local index ="GROUP_".. Group.getID(tmpGroup)
         --   env.info("adding command for "..index)
            if GLOBAL_JTAC_RADIO_ADDED[index] == nil then
               -- env.info("about command for "..index)
                missionCommands.addCommandForGroup( Group.getID(tmpGroup) , "JTAC Status" ,nil, getJTACStatus ,nil )
                GLOBAL_JTAC_RADIO_ADDED[index] = true
                env.info("Added command for "..index)
            end
        end

    end



end

if JTAC_jtacStatusF10 == true then
    timer.scheduleFunction(addRadioCommands, nil, timer.getTime() + 10)
end

--[[

    Logic
    - Initialise with JTAC name
        - JTAC searches through all groups and picks the nearest (non troop?) target to it
            - starts lazing
        - if nothing but troops, lase troops
            - every second, check that unit is still visible, if not restart

        ]]


