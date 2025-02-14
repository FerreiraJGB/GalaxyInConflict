local oldInit = init
local oldUpdate = update

function init()
	oldInit()
  
	-- eats up a specified item, or tries to
	-- (has to be placed here instead of 'gic_player_primary' because this script can access 'player' scripts)
	message.setHandler("gic_consumeItem",
      function(_, _, item)
		player.consumeItem({name = item, count = 1})
	  end)
	  
	message.setHandler("gic_checkStat",
      function(_, _, entityID, stat_name)
		-- sb.logInfo("player received request to check stat, sending back result")
		-- sb.logInfo("checking stat: " .. sb.printJson(stat_name))
		world.sendEntityMessage(entityID, "gic_confirmStat", status.stat(stat_name))
	  end)
	

	--self.gic_novakid = (world.entitySpecies(entity.id()) == "gic_realisticnovakid")
	
	--if self.gic_novakid then
		--self.gic_unbrandedConfig = root.assetJson("/stats/gic_unbranded.config")
	--end
	
	self.sikaDetectRadius = 120
	self.sikaDetectParams = {
		boundMode = "position",
		includedTypes = {"monster","npc","player"},
		order = "nearest"
	}
	self.sikaMaxDetect = 15 --max set value to prevent too much lag
	
	self.sikaHelicopters = {
		gic_sika_helicopter = true,
		gic_sika_helicopter_mg = true,
		gic_sika_helicopter_alt = true,
		--gic_sika_helicopter_alt2 = true, --as requested by Med, this sika (with just hardpoints) shouldn't have any targeting systems
		gic_sika_helicopter_civilian = true --unsure whether or not to leave the civ sika with the targeting system, since it seems odd that the civ sika *would* still have targeting systems. could be justified by something-something civ sika was hastily-done conversion to civ spec? unknown.
	}
end


local ews_validThermalCoords = {}
local ews_invalidThermalCoords = {}
local ews_thermalRuns = 0
local ews_buffer = 0
function update(dt)
	oldUpdate(dt)
	
	if (world.entitySpecies(entity.id()) == "gic_realisticnovakid") and status.statusProperty("gic_stopUnbrandedCycle",false) == false then
		local config = root.assetJson("/stats/gic_unbranded.config")
		
		gic_drawNovakidTimer(config)
	end
	
	if player.isLounging and player.loungingIn() ~= nil and self.sikaHelicopters[string.lower(world.entityTypeName(player.loungingIn()))] then
		gic_sikaDrawEnemyIndicators()
	end
	
	
	
	-- THERMAL SIGHT STUFF
	local ews_thermalSightActive = status.statusProperty("ews_thermalSightActive", false)
	ews_buffer = ews_buffer + 1
	
	if ews_thermalSightActive then
	
		-- run thermal sight code (~6 times per second for performance reasons)
		if (ews_buffer >= 10) then
			ews_buffer = 0
			ews_validThermalCoords = nil
			ews_invalidThermalCoords = nil
			ews_validThermalCoords = {}
			ews_invalidThermalCoords = {}
			-- sb.logInfo("start thermal sight")
			
			ews_thermalRuns = 0
			ews_thermalSight()
			-- sb.logInfo("end thermal sight")
			-- sb.logInfo("thermal sight code run times: " .. ews_thermalRuns)
		end
		
		-- draw the thermal sight results
		local pos = entity.position()
		local userAimAngle = status.statusProperty("ews_aimAngle")
		local maxDistance = status.statusProperty("ews_thermalSightRange")
		local userFacing = status.statusProperty("ews_facingDirection")
		local maxAngle = status.statusProperty("ews_thermalSightAngle")
		local checkLOS = status.statusProperty("ews_thermalLOS")
		local color = status.statusProperty("ews_thermalColor")
		
		for xCoord, status in pairs(ews_validThermalCoords) do
			for yCoord, status2 in pairs(status) do
				-- note to self: angles and etc are calculated real-time for smooth functionality.
				-- not as resource intensive as searching up for positions and etc!!
				
				local targetCoord = {xCoord, yCoord}
				local distanceVec = world.distance(targetCoord, pos)
				local dist = vec2.mag(distanceVec)
				
				local angle
		
				if (userFacing == -1) then
					-- flip x-coordinate to get right angle value
					-- user's angle value grabbed from item should be limited from pi/2 to -pi/2 (iirc?)
					-- so account for facing direction, etc
					
					local tempVec = {distanceVec[1], distanceVec[2]}
					tempVec[1] = -tempVec[1]
					angle = vec2.angle(tempVec)
				else
					angle = vec2.angle(distanceVec)
				end
				
				if angle > math.pi then
					angle = angle - math.pi * 2
				end
				
				local variant = math.floor(math.random(1, 4))
				if dist <= maxDistance and math.abs(angle - userAimAngle) < maxAngle then
					if (not checkLOS) or (checkLOS and not world.lineTileCollision(pos, targetCoord)) then
						local drawCoordinates = world.distance(targetCoord, world.entityPosition(entity.id()))
						localAnimator.addDrawable({
						
						  image = "/items/active/unsorted/oredetector/detectnoise.png:"..variant,
						  fullbright = true,
						  position = drawCoordinates,
						  centered = false,
						  color = color
						}, "overlay")
					end
				end
			end
		end
	end
end

-- turns into pixel values (?)
function gic_pix(val)
	return val*0.125
end

function gic_drawNovakidTimer(config)
	local novakidStage = status.statusProperty("gic_novakidStage",config.startingStage) --backup params as safeguard
	local novakidTime = status.statusProperty("gic_novakidTime",config.stages[config.startingStage].duration) --backup params as safeguard
	
	local defColors = config.defaultColors
	local backLineColor = defColors[1]
	local lineColor = defColors[2]
	
	if config.stages[novakidStage].colorOverrides ~= nil then
		local colors = config.stages[novakidStage].colorOverrides
		backLineColor = colors[1]
		lineColor = colors[2]
	end
	
	
	local offset = {0,-3.0}
	local y = offset[2]
	local x = offset[1]
	local lineWidth = 3
	local w2 = lineWidth / 2
	local pixel
	
	-- backing
	localAnimator.addDrawable({
		line = {{x-w2-gic_pix(1), y}, {x+w2+gic_pix(1), y}}, 
		width = 4, 
		fullbright = true, 
		color = backLineColor
	}, "overlay+2")
	
	-- front
	local portion = novakidTime / config.stages[novakidStage].duration
	localAnimator.addDrawable({
		line = {{x-w2, y}, {x-w2 + lineWidth * portion, y}}, 
		width = 2, 
		fullbright = true, 
		color = lineColor
	}, "overlay+3")
end

function gic_sikaDrawEnemyIndicators()
  if self.sikaDetectRadius then
    local pos = entity.position()
    local enemiesNearby = world.entityQuery(entity.position(), self.sikaDetectRadius, self.sikaDetectParams)
    for k, eId in ipairs(enemiesNearby) do
      --if world.entityCanDamage(eId, self.playerId) and self.enemyDetectTypeNames[string.lower(world.entityTypeName(eId))] then
	  if world.entityCanDamage(eId, self.playerId) and k <= self.sikaMaxDetect + 1 then
		local hostilePos = world.entityPosition(eId)
        local enemyVec = world.distance(hostilePos, pos)
        local dist = vec2.mag(enemyVec)
        if dist > 7 then
          local arrowAngle = vec2.angle(enemyVec)
          local arrowOffset = vec2.withAngle(arrowAngle, 6.5)
          localAnimator.addDrawable({
                image = "/scripts/deployment/enemyarrow.png",
                rotation = arrowAngle,
                position = arrowOffset,
                fullbright = true,
                centered = true,
                color = {255, 255, 255, 255 * (1 - dist / self.sikaDetectRadius)}
              }, "overlay")
			
			
			
		   local entityType = world.entityType(eId)
		   if (entityType == "npc" or entityType == "player") then
				world.debugLine(entity.position(), hostilePos, {255,0,0,255})
			   
			   -- localAnimator.addDrawable({
                -- image = "/scripts/deployment/gic_sika_detectnpc.png",
                -- position = vec2.add(enemyVec,{0,-0.5}),
                -- fullbright = true,
                -- centered = true,
                -- color = {255, 255, 255, 255}
			   -- }, "foregroundoverlay+999")
			   
			   
				local boxColor = "#00FF00FF"
				local imageSize = {8,16}
				   
				local x1 = gic_pix(-imageSize[1])
				local y1 = gic_pix(-imageSize[2])
				local x2 = gic_pix(imageSize[1])
				local y2 = gic_pix(imageSize[2])
				
				local hostilePos = {hostilePos[1],hostilePos[2]-0.375} --3 pixels down
				   
				localAnimator.addDrawable({
					line = {
						world.distance(vec2.add(hostilePos,{x1,y1}), pos), 
						world.distance(vec2.add(hostilePos,{x1,y2}), pos)
					}, 
					width = 2, 
					fullbright = true, 
					color = boxColor
				}, "overlay+2")
				localAnimator.addDrawable({
					line = {
						world.distance(vec2.add(hostilePos,{x2,y1}), pos), 
						world.distance(vec2.add(hostilePos,{x2,y2}), pos)
					}, 
					width = 2, 
					fullbright = true, 
					color = boxColor
				}, "overlay+2")
				localAnimator.addDrawable({
					line = {
						world.distance(vec2.add(hostilePos,{x1,y1}), pos), 
						world.distance(vec2.add(hostilePos,{x2,y1}), pos)
					}, 
					width = 2, 
					fullbright = true, 
					color = boxColor
				}, "overlay+2")
				localAnimator.addDrawable({
					line = {
						world.distance(vec2.add(hostilePos,{x1,y2}), pos), 
						world.distance(vec2.add(hostilePos,{x2,y2}), pos)
					}, 
					width = 2, 
					fullbright = true, 
					color = boxColor
				}, "overlay+2")
			   
		   else --monster rendering
		   
				-- generic draw (standard box)
				local boxColor = "#00FF00FF"
				if 1 == 1 then
				   --local entityPort = world.entityPortrait(eId,"full")
				   --local imageSize = root.imageSize(entityPort[1].image)
				   local imageSize = {32,32}
				   --sb.logInfo(sb.printJson(entityPort[1].image))
				   
				   local x1 = gic_pix(-imageSize[1])
				   local y1 = gic_pix(-imageSize[2])
				   local x2 = gic_pix(imageSize[1])
				   local y2 = gic_pix(imageSize[2])
				   
				   localAnimator.addDrawable({
						line = {
							world.distance(vec2.add(hostilePos,{x1,y1}), pos), 
							world.distance(vec2.add(hostilePos,{x1,y2}), pos)
						}, 
						width = 2, 
						fullbright = true, 
						color = boxColor
					}, "overlay+2")
					localAnimator.addDrawable({
						line = {
							world.distance(vec2.add(hostilePos,{x2,y1}), pos), 
							world.distance(vec2.add(hostilePos,{x2,y2}), pos)
						}, 
						width = 2, 
						fullbright = true, 
						color = boxColor
					}, "overlay+2")
					localAnimator.addDrawable({
						line = {
							world.distance(vec2.add(hostilePos,{x1,y1}), pos), 
							world.distance(vec2.add(hostilePos,{x2,y1}), pos)
						}, 
						width = 2, 
						fullbright = true, 
						color = boxColor
					}, "overlay+2")
					localAnimator.addDrawable({
						line = {
							world.distance(vec2.add(hostilePos,{x1,y2}), pos), 
							world.distance(vec2.add(hostilePos,{x2,y2}), pos)
						}, 
						width = 2, 
						fullbright = true, 
						color = boxColor
					}, "overlay+2")
					
					--world.debugLine(vec2.add(hostilePos,{x1,y1}), vec2.add(hostilePos,{x1,y2}), {255,0,0,255})
					--world.debugLine(vec2.add(hostilePos,{x2,y1}), vec2.add(hostilePos,{x2,y2}), {255,0,0,255})
					--world.debugLine(vec2.add(hostilePos,{x1,y1}), vec2.add(hostilePos,{x2,y1}), {255,0,0,255})
					--world.debugLine(vec2.add(hostilePos,{x1,y2}), vec2.add(hostilePos,{x2,y2}), {255,0,0,255})
				end
				
				--draw via portrait image
				if 1 == 2 then
				   local entityPort = world.entityPortrait(eId,"full")
				   local imageSize = root.imageSize(entityPort[1].image)
				   sb.logInfo(sb.printJson(entityPort[1].image))
				   
				   local x1 = gic_pix(-imageSize[1])
				   local y1 = gic_pix(-imageSize[2])
				   local x2 = gic_pix(imageSize[1])
				   local y2 = gic_pix(imageSize[2])
				   
				   localAnimator.addDrawable({
						line = {
							world.distance(vec2.add(hostilePos,{x1,y1}), pos), 
							world.distance(vec2.add(hostilePos,{x1,y2}), pos)
						}, 
						width = 2, 
						fullbright = true, 
						color = "#00FF00FF"
					}, "overlay+2")
					localAnimator.addDrawable({
						line = {
							world.distance(vec2.add(hostilePos,{x2,y1}), pos), 
							world.distance(vec2.add(hostilePos,{x2,y2}), pos)
						}, 
						width = 2, 
						fullbright = true, 
						color = "#00FF00FF"
					}, "overlay+2")
					localAnimator.addDrawable({
						line = {
							world.distance(vec2.add(hostilePos,{x1,y1}), pos), 
							world.distance(vec2.add(hostilePos,{x2,y1}), pos)
						}, 
						width = 2, 
						fullbright = true, 
						color = "#00FF00FF"
					}, "overlay+2")
					localAnimator.addDrawable({
						line = {
							world.distance(vec2.add(hostilePos,{x1,y2}), pos), 
							world.distance(vec2.add(hostilePos,{x2,y2}), pos)
						}, 
						width = 2, 
						fullbright = true, 
						color = "#00FF00FF"
					}, "overlay+2")
					
					--world.debugLine(vec2.add(hostilePos,{x1,y1}), vec2.add(hostilePos,{x1,y2}), {255,0,0,255})
					--world.debugLine(vec2.add(hostilePos,{x2,y1}), vec2.add(hostilePos,{x2,y2}), {255,0,0,255})
					--world.debugLine(vec2.add(hostilePos,{x1,y1}), vec2.add(hostilePos,{x2,y1}), {255,0,0,255})
					--world.debugLine(vec2.add(hostilePos,{x1,y2}), vec2.add(hostilePos,{x2,y2}), {255,0,0,255})
				end
			   
			   
			    --draw via bounding box
			    if 1 == 2 then
				   local boundBox = world.entityMetaBoundBox(eId)
				   
				   if boundBox ~= nil then
				   
					localAnimator.addDrawable({
						line = {
							world.distance(vec2.add(hostilePos,{boundBox[1],boundBox[2]}), pos), 
							world.distance(vec2.add(hostilePos,{boundBox[1],boundBox[4]}), pos)
						}, 
						width = 2, 
						fullbright = true, 
						color = "#00FF00FF"
					}, "overlay+2")
					localAnimator.addDrawable({
						line = {
							world.distance(vec2.add(hostilePos,{boundBox[3],boundBox[2]}), pos), 
							world.distance(vec2.add(hostilePos,{boundBox[3],boundBox[4]}), pos)
						}, 
						width = 2, 
						fullbright = true, 
						color = "#00FF00FF"
					}, "overlay+2")
					localAnimator.addDrawable({
						line = {
							world.distance(vec2.add(hostilePos,{boundBox[1],boundBox[2]}), pos), 
							world.distance(vec2.add(hostilePos,{boundBox[3],boundBox[2]}), pos)
						}, 
						width = 2, 
						fullbright = true, 
						color = "#00FF00FF"
					}, "overlay+2")
					localAnimator.addDrawable({
						line = {
							world.distance(vec2.add(hostilePos,{boundBox[1],boundBox[4]}), pos), 
							world.distance(vec2.add(hostilePos,{boundBox[3],boundBox[4]}), pos)
						}, 
						width = 2, 
						fullbright = true, 
						color = "#00FF00FF"
					}, "overlay+2")
					
					--world.debugLine(entity.position(), world.distance(vec2,add(hostilePos,boundBox[1]), pos), {255,0,0,255})
					--world.debugLine(entity.position(), hostilePos, {255,0,0,255})
					--world.debugLine(entity.position(), hostilePos, {255,0,0,255})
					--world.debugLine(entity.position(), hostilePos, {255,0,0,255})
				   end
				end
		   end
		   
        end
      end
    end
  end
end



-- code to find the creatures in range
function ews_thermalSight()
  -- if self.sikaDetectRadius then
    local pos = entity.position()
	
	local maxDistance = status.statusProperty("ews_thermalSightRange") * 1.2 -- add on a bit of extra range to account for entities hitboxes being large
	local maxAngle = status.statusProperty("ews_thermalSightAngle") * 1.75 -- add on a bit of extra range to account for entities hitboxes being large
	
	local userAimAngle = status.statusProperty("ews_aimAngle")
	local userFacing = status.statusProperty("ews_facingDirection")
	
	local enemiesNearby = world.entityQuery(entity.position(), maxDistance, self.sikaDetectParams)
	
	
    for k, eId in ipairs(enemiesNearby) do
      --if world.entityCanDamage(eId, self.playerId) and self.enemyDetectTypeNames[string.lower(world.entityTypeName(eId))] then
	  if world.entityCanDamage(eId, self.playerId) and k <= self.sikaMaxDetect + 1 then
		local hostilePos = world.entityPosition(eId)
        local enemyVec = world.distance(hostilePos, pos)
        local dist = vec2.mag(enemyVec)
		local angle
		
		if (userFacing == -1) then
			-- flip x-coordinate to get right angle value
			-- user's angle value grabbed from item should be limited from pi/2 to -pi/2 (iirc?)
			-- so account for facing direction, etc
			
			local tempVec = {enemyVec[1], enemyVec[2]}
			tempVec[1] = -tempVec[1]
			angle = vec2.angle(tempVec)
		else
			angle = vec2.angle(enemyVec)
		end
		
		if angle > math.pi then
			angle = angle - math.pi * 2
		end
		
		-- sb.logInfo("monsterAngle " .. angle)
		-- sb.logInfo("userAimAngle " .. userAimAngle)
		
		-- if hostile is incredibly close, then do the calculations regardless of angle
		-- this is to account for situations where the target is too close for the angle bump to matter
		if dist <= maxDistance and (dist <= maxDistance * 0.25 or math.abs(angle - userAimAngle) < maxAngle) then
			-- begin recursive code
			ews_renderThermals(eId, hostilePos, 0)
        end
      end
    end
  -- end
end


-- initial direction: 2 = up, 3 = right, 4 = down, 5 = left 	(starts at 2 to avoid any true == 1 or something)
-- coordinate checking system: can't do 2d array because 2d array would have to be... big
	-- so doing a scuffed 2d array, format somewhat looks like this:
	-- {"1042":{"1029":true,"1030":true,"1031":true,"1027":true,"1028":true}}
function ews_renderThermals(targetEntity, startingPosition, initialDirection)
	-- sb.logInfo("start new renderThermals")
	
	
	-- first time i've ever done recursion. lovely stuff.
	
	ews_thermalRuns = ews_thermalRuns + 1
	
	local newPos = startingPosition
	newPos[1] = math.floor(newPos[1])
	newPos[2] = math.floor(newPos[2])
	
	
	-- check current position
	-- if valid, mark as valid and being checking adjacent squares
	-- if valid and already found, cancel
	-- if invalid, then cancel
	if gic_findEntity(newPos) then
	
		-- if not gic_findCoordinate(ews_validThermalCoords, newPos) then
		
		-- sb.logInfo("coordinate " .. sb.printJson(ews_validThermalCoords[newPos[1]]))
		-- sb.logInfo("coordinateValid " .. sb.printJson(ews_validThermalCoords[newPos[1]] == newPos[2]))
		
		-- define the first coordinate (if it doesn't exist) so code doesn't break
		if not ews_validThermalCoords[newPos[1]] then ews_validThermalCoords[newPos[1]] = {} end
		
		if not (ews_validThermalCoords[newPos[1]][newPos[2]]) then
			-- sb.logInfo("valid origin coordinate")
			-- ews_validThermalCoords[#ews_validThermalCoords + 1] = newPos
			ews_validThermalCoords[newPos[1]][newPos[2]] = true
			
			
			-- local drawCoordinates = world.distance(newPos, world.entityPosition(entity.id()))
			-- localAnimator.addDrawable({
              -- image = "/items/active/unsorted/oredetector/detectnoise.png:1",
              -- fullbright = true,
              -- position = drawCoordinates,
              -- centered = false
            -- }, "overlay")
		else
			-- sb.logInfo("origin coordinate already found")
			return {ews_validThermalCoords, ews_invalidThermalCoords, false}
		end
	else
		-- define the first coordinate (if it doesn't exist) so code doesn't break
		if not ews_invalidThermalCoords[newPos[1]] then ews_invalidThermalCoords[newPos[1]] = {} end
		
		ews_invalidThermalCoords[newPos[1]][newPos[2]] = true
		-- sb.logInfo("origin coordinate invalid")
		return {ews_validThermalCoords, ews_invalidThermalCoords, false}
	end
	
	
	
	-- check coordinates above recursively
	local targetPos = {newPos[1], newPos[2] + 1}
	if not ews_validThermalCoords[targetPos[1]] then ews_validThermalCoords[targetPos[1]] = {} end -- safeguard (in case coordinate hasn't been checked before)
	if not ews_invalidThermalCoords[targetPos[1]] then ews_invalidThermalCoords[targetPos[1]] = {} end -- safeguard (in case coordinate hasn't been checked before)
	
	-- don't check above if this cycle was told to check downwards; by that logic, upwards has already been checked! (and is valid!)
	if not (initialDirection == 4) and not (ews_validThermalCoords[targetPos[1]][targetPos[2]]) and not (ews_invalidThermalCoords[targetPos[1]][targetPos[2]]) then
		-- sb.logInfo("recursively checking above")
		local results = ews_renderThermals(targetEntity, targetPos, 2)
		-- sb.logInfo("checkUpSuccess " .. sb.printJson(results[3]))
		-- sb.logInfo("post: valid coords " .. sb.printJson(results[1]))
		-- sb.logInfo("post: invalid coords " .. sb.printJson(results[2]))
	end
	
	
	-- check coordinates below recursively
	local targetPos = {newPos[1], newPos[2] - 1}
	if not ews_validThermalCoords[targetPos[1]] then ews_validThermalCoords[targetPos[1]] = {} end -- safeguard (in case coordinate hasn't been checked before)
	if not ews_invalidThermalCoords[targetPos[1]] then ews_invalidThermalCoords[targetPos[1]] = {} end -- safeguard (in case coordinate hasn't been checked before)
	
	-- don't check downwards if this cycle was told to check upwards; by that logic, downwards has already been checked! (and is valid!)
	if not (initialDirection == 2) and not (ews_validThermalCoords[targetPos[1]][targetPos[2]]) and not (ews_invalidThermalCoords[targetPos[1]][targetPos[2]]) then
		-- sb.logInfo("recursively checking below")
		local results = ews_renderThermals(targetEntity, targetPos, 4)
		-- sb.logInfo("checkDownSuccess " .. sb.printJson(results[3]))
		-- sb.logInfo("post: valid coords " .. sb.printJson(results[1]))
		-- sb.logInfo("post: invalid coords " .. sb.printJson(results[2]))
	end
	
	
	-- check coordinates to the right recursively
	local targetPos = {newPos[1] + 1, newPos[2]}
	if not ews_validThermalCoords[targetPos[1]] then ews_validThermalCoords[targetPos[1]] = {} end -- safeguard (in case coordinate hasn't been checked before)
	if not ews_invalidThermalCoords[targetPos[1]] then ews_invalidThermalCoords[targetPos[1]] = {} end -- safeguard (in case coordinate hasn't been checked before)
	
	-- don't check rightwards if this cycle was told to check leftwards; by that logic, leftwards has already been checked! (and is valid!)
	if not (initialDirection == 5) and not (ews_validThermalCoords[targetPos[1]][targetPos[2]]) and not (ews_invalidThermalCoords[targetPos[1]][targetPos[2]]) then
		-- sb.logInfo("recursively checking to right")
		local results = ews_renderThermals(targetEntity, targetPos, 3)
		-- sb.logInfo("checkLeftSuccess " .. sb.printJson(results[3]))
		-- sb.logInfo("post: valid coords " .. sb.printJson(results[1]))
		-- sb.logInfo("post: invalid coords " .. sb.printJson(results[2]))
	end
	
	
	-- check coordinates to the left recursively
	local targetPos = {newPos[1] - 1, newPos[2]}
	if not ews_validThermalCoords[targetPos[1]] then ews_validThermalCoords[targetPos[1]] = {} end -- safeguard (in case coordinate hasn't been checked before)
	if not ews_invalidThermalCoords[targetPos[1]] then ews_invalidThermalCoords[targetPos[1]] = {} end -- safeguard (in case coordinate hasn't been checked before)
	
	-- don't check leftwards if this cycle was told to check rightwards; by that logic, rightwards has already been checked! (and is valid!)
	if not (initialDirection == 3) and not (ews_validThermalCoords[targetPos[1]][targetPos[2]]) and not (ews_invalidThermalCoords[targetPos[1]][targetPos[2]]) then
		-- sb.logInfo("recursively checking to right")
		local results = ews_renderThermals(targetEntity, targetPos, 5)
		-- sb.logInfo("checkLeftSuccess " .. sb.printJson(results[3]))
		-- sb.logInfo("post: valid coords " .. sb.printJson(results[1]))
		-- sb.logInfo("post: invalid coords " .. sb.printJson(results[2]))
	end
	
	
	
	-- sb.logInfo("post2: valid coords " .. sb.printJson(validCoords))
	-- sb.logInfo("post2: invalid coords " .. sb.printJson(invalidCoords))
	
	-- sb.logInfo("end new renderThermals")
	return {ews_validThermalCoords, ews_invalidThermalCoords, true}
end


function gic_findEntity(pos) -- looks for possibly hostile entities
	-- local monsterId = animationConfig.animationParameter("monsterId")
	local queryParameters = {
		-- withoutEntityId = monsterId,
		includedTypes = {"creature"},
		order = "nearest"
	}
	if not monsterId then
		queryParameters = {
			includedTypes = {"creature"},
			order = "nearest"
		}
	end
	local entityId = entity.id()
	
	local candidates = world.entityQuery(pos, 1, queryParameters)
	for _, candidate in ipairs(candidates) do
		if world.entityCanDamage(entityId, candidate) then
			if world.entityAggressive(candidate) then
				return true
			else
				return "neutral"
			end
		end
	end
	return false
end
