require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  vehicle.setPersistent(true)
  self.specialLast = false
  self.rockingTimer = 0
  self.facingDirection = 1
  self.angle = 0
  --animator.setParticleEmitterActive("burningSmoke", true)
  self.damageEmoteTimer = 0
  self.spawnPosition = mcontroller.position()

  self.worldBottomDeathLevel = 5

  self.waterFactor = 0 --how much water are we in right now

  self.rockingInterval = config.getParameter("rockingInterval")
  self.maxHealth = config.getParameter("maxHealth")
  self.protection = config.getParameter("protection")

  self.damageStateNames = config.getParameter("damageStateNames")
  self.damageStateDriverEmotes = config.getParameter("damageStateDriverEmotes")
  self.materialKind = config.getParameter("materialKind")

  self.windLevelOffset = config.getParameter("windLevelOffset")
  self.rockingWindAngleMultiplier = config.getParameter("rockingWindAngleMultiplier")
  self.maxRockingAngle = config.getParameter("maxRockingAngle")
  self.angleApproachFactor = config.getParameter("angleApproachFactor")

  self.speedRotationMultiplier = config.getParameter("speedRotationMultiplier")

  self.targetMoveSpeed = config.getParameter("targetMoveSpeed")
  self.moveControlForce = config.getParameter("moveControlForce")

  mcontroller.resetParameters(config.getParameter("movementSettings"))

  self.minWaterFactorToFloat = config.getParameter("minWaterFactorToFloat")
  self.sinkingBuoyancy = config.getParameter("sinkingBuoyancy")
  self.sinkingFriction = config.getParameter("sinkingFriction")

  self.bowWaveParticleNames=config.getParameter("bowWaveParticles")
  self.bowWaveMaxEmissionRate=config.getParameter("bowWaveMaxEmissionRate")

  self.splashParticleNames = config.getParameter("splashParticles")
  self.splashEpsilon = config.getParameter("splashEpsilon")

  self.maxGroundSearchDistance = config.getParameter("maxGroundSearchDistance")

  
  
  --vehicle gun script
    
  animator.rotateGroup("guns", 0, true)
  self.fireTimer = 0
  self.fireTimer2 = 0
  self.gunnerTimer = 0
  self.explodeTimer = 5
  self.headlightCanToggle = true
  self.headlightsOff = true
  animator.setAnimationState("headlights", "off")
  animator.setGlobalTag("hatchState", "closed")
  self.hatchState = "closed"
  local effects = jarray()
  effects[1] = "invulnerable"
  effects[2] = "invisible"
  vehicle.setLoungeStatusEffects("hatchGunner", effects)
    
  local bounds = mcontroller.localBoundBox()
  self.frontGroundTestPoint = {bounds[1]+1.0,bounds[2]+2.5}
  self.frontGroundTestPoint2 = {bounds[1]+4.0,bounds[2]+2.5}
  self.backGroundTestPoint = {bounds[3]-1.0, bounds[2]+2.5}
  self.backGroundTestPoint2 = {bounds[3]-4.0, bounds[2]+2.5}

  --this comes in from the controller.
  self.ownerKey = config.getParameter("ownerKey")
  vehicle.setPersistent(self.ownerKey)

  --setup the store functionality
  message.setHandler("store",
      function(_, _, ownerKey)
        local animState=animator.animationState("base")

        if (animState == "idle" or animState == "sinking") then
          if (self.ownerKey and self.ownerKey == ownerKey) then
            self.spawnPosition = mcontroller.position()
            animator.setAnimationState("base", "warpOutPart1")
            local localStorable = (self.driver == nil)
            return {storable = true, healthFactor = storage.health / self.maxHealth}
          end
        end
      end)
  
  self.id = entity.id()
  message.setHandler("lockHook",
      function(_, _, pos, id)
		local localPos = mcontroller.position()
		local pos1 = world.xwrap({localPos[1],localPos[2]})
		local pos2 = world.xwrap({pos[1],pos[2]-8})
		
		world.debugPoint(pos1, {255, 0, 0, 255})
		world.debugPoint(pos2, {255, 0, 255, 255})
		
		local possibleCollision = world.lineCollision(pos1, pos2)
		
		if not possibleCollision then
			mcontroller.setPosition({pos[1],pos[2]-5})
			mcontroller.setVelocity({0,0})
			
			world.sendEntityMessage(id, "confirmHooked",self.id)
		else
			world.sendEntityMessage(id, "unhook")
		end
      end)

  -- setup boarding follower functionality (largely ripped from the shuttlecraft mod)
  message.setHandler("gic_boardGunnerFollower",
      function(_, _, uuid, npcId)
  			if vehicle.entityLoungingIn("drivingSeat") ~= nil then 
				if world.entityUniqueId(vehicle.entityLoungingIn("drivingSeat")) == uuid then
					self.boardFollower = npcId
				end
			end
	  end)
  self.gunnerAimPos = vehicle.aimPosition("hatchGunner");
  
  
  if (storage.health) then
    animator.setAnimationState("base", "idle")
  else
    local startHealthFactor = config.getParameter("startHealthFactor")

    if (startHealthFactor == nil) then
        storage.health = self.maxHealth
    else
       storage.health = math.min(startHealthFactor * self.maxHealth, self.maxHealth)
    end
    animator.setAnimationState("base", "warpInPart1")
  end

  updateDamageEffects(0, true)
end

--vehicle gun script over


function update()
  vehicle.setPersistent(true)
  if mcontroller.position()[2] < self.worldBottomDeathLevel then
    vehicle.destroy()
    return
  end
  
  local animState = animator.animationState("base")
  local waterFactor = 0--mcontroller.liquidPercentage()

  if (animState == "warpedOut") then
    vehicle.destroy()
  elseif (animState == "warpInPart1" or animState == "warpOutPart2") then
    -- world.debugText("warping",mcontroller.position(),"red")

    mcontroller.setPosition(self.spawnPosition)
    mcontroller.setVelocity({0, 0})
  --elseif (animState == "sinking") then
    -- world.debugText("sinking", mcontroller.position(), "red")

    --self.angle = updateSinking(waterFactor, self.angle, -math.pi * 0.4)
  elseif (animState == "idle") then
	
	
	-- ripped (and edited) from shuttlecraft mod's code
	if (vehicle.entityLoungingIn("drivingSeat") ~= nil) and self.boardFollower then followerEmbark(self.boardFollower) end 
  
    -- world.debugText("idle", mcontroller.position(), "green")

    local healthFactor = storage.health / self.maxHealth
    local waterSurface = self.maxGroundSearchDistance
    self.waterBounds = mcontroller.localBoundBox()

    --work out water surface
    if (waterFactor > 0) then
      waterSurface = (self.waterBounds[4] * waterFactor) + (self.waterBounds[2] * (1.0 - waterFactor))
    end

    self.waterBounds[2] = waterSurface + 0.25
    self.waterBounds[4] = waterSurface + 0.5

    --world.debugText(string.format("WaterSurface=%s", self.waterBounds[2]), mcontroller.position(), "yellow")
	--world.debugText(string.format("WaterSurface=%s", self.waterBounds[4]), mcontroller.position(), "yellow")

  local moving, facing = updateDriving()
  aiTargeting(facing)
  updateHatchTurret(facing)
  
    --Rocking in the wind, and rotating up when moving
    local floating = updateFloating(waterFactor, moving,facing)
    updateMovingEffects(floating,moving)
    updatePassengers(healthFactor)

    if storage.health <= 0 then
      --vehicle.setLoungeEnabled("titanicPose", false)
      --animator.setAnimationState("base", "sinking")
      --self.sinkTimer = config.getParameter("maxSinkTime")
    end

    self.facingDirection = facing
    self.waterFactor = waterFactor
  end

  --take care of rotating and flipping
  animator.resetTransformationGroup("flip")
  animator.resetTransformationGroup("rotation")
  
  
  if self.facingDirection < 0 then
    animator.scaleTransformationGroup("flip", {-1, 1})
  end
  
  
  animator.rotateTransformationGroup("rotation", self.angle)

  mcontroller.setRotation(self.angle)
  
  
  
  visualDamageEffects()
  if self.explodeTimer <= 0 then
	vehicle.destroy()
	world.spawnProjectile(config.getParameter("deathProjectileType"), mcontroller.position(), entity.id(), {0,0}, false, config.getParameter("deathProjectileParameters"))
  elseif storage.health <= 0 and self.explodeTimer > 0 then
	self.queExplosion = true
	--self.explodeTimer = self.explodeTimer - script.updateDt()
	--sb.logInfo(self.explodeTimer)
  end
  
  if self.queExplosion == true then self.explodeTimer = self.explodeTimer - script.updateDt() end
  
  
  
  if self.queRepairText == true then
	local configDat = config.getParameter("repairTextConfig")
	
	--sb.logInfo(sb.printJson(configDat.actionOnReap[1].action))
	configDat.actionOnReap[1].specification.text = "^green;+"..math.floor(self.repairedHealth+0.5).."/"..math.floor(self.maxHealth-storage.health+0.5).." HP^reset;"
	world.spawnProjectile("gic_null",mcontroller.position(),entity.id(),{0,0},false,configDat)
	self.queRepairText = false
  end
end

-- basically ripped from the shuttlecraft mod, edited and such for this vehicle's purposes though.
function followerEmbark(npcId)
	--sb.logInfo("wow")
			local driverSeat = "drivingSeat"
			local boardSeat = nil

			if world.entityType(npcId) == "npc" then
				if vehicle.entityLoungingIn(driverSeat) ~= nil then 
					if vehicle.entityLoungingIn("hatchGunner") == nil and boardSeat == nil then 
						boardSeat = 2
					end 
				end 
				if boardSeat ~= nil then 
						local beamin = false 
						if world.magnitude(world.entityPosition(npcId), mcontroller.position()) >= 20 then beamin = true end
						world.callScriptedEntity(npcId, "setShuttlecraftLounge", entity.id(), boardSeat, beamin )
				end
			end
	self.boardFollower = nil
end

function aiTargeting(facing)
	--world.debugLine(vec2.add(animator.partPoint("hatchGunnerGun", "firePoint"), mcontroller.position()), self.gunnerAimPos, {255,0,0,255})
	
	self.aiFireMachineguns = false
	if vehicle.entityLoungingIn("hatchGunner") == nil or world.entityType(vehicle.entityLoungingIn("hatchGunner")) ~= "npc" then
		self.gunnerAimPos = vehicle.aimPosition("hatchGunner")
		return
	else
		local npcId = vehicle.entityLoungingIn("hatchGunner")
		
		-- ok most of this is my own stuff but the base targeting code is ripped from the shuttlecraft mod
		-- anyways just also wanted to say that this stuff is cool, since *you can pull many functions from the NPC*, many more than I had thought possible!
		-- cool stuff since yeah main thing is that the AI targeting priorities here will be based off the targeting priorities of the NPC itself!
		
		local range = 60 -- suitable range to engage enemy targets with the tank's weird 20mm cannon
		local targetList = world.entityQuery(mcontroller.position(), range, {withoutEntityId = npcId,includedTypes = {"npc", "monster", "player"}, order = "nearest"})
		local validTarget = nil
		if targetList[1] ~= nil then -- were we able to find valid targets?
			for i = 1, #targetList do 
				if world.callScriptedEntity(npcId, "entity.isValidTarget", targetList[i]) and world.callScriptedEntity(npcId, "entity.entityInSight", targetList[i]) then 
					validTarget = targetList[i]
					break
				end
			end
			
			
			if validTarget ~= nil then
				local pos = vec2.add(mcontroller.position(),animator.partPoint("hatchGunnerGun", "firePoint"))
				local canPos = world.entityPosition(validTarget)
				local diff = world.distance(vec2.add({0,3.2},canPos), pos)
				local aimAngle = math.atan(diff[2], diff[1])
				
				
				local gunAngle = animator.currentRotationAngle("hatchGunner")
				if facing < 0 then gunAngle = math.pi - gunAngle + self.angle
				else
					gunAngle = gunAngle + self.angle
				end
				
				
				--world.debugText("gunAngle: " .. sb.printJson(gunAngle), vec2.add(mcontroller.position(), {0,4.0}), "blue")
				--world.debugLine(pos, vec2.add(pos,{100*math.cos(gunAngle),100*math.sin(gunAngle)}), {0,0,255,255})
				
				
				local toTarget = vec2.angle(world.distance(canPos, pos))
				--world.debugLine(pos, vec2.add(pos,{100*math.cos(toTarget),100*math.sin(toTarget)}), {255,0,255,255})
				
				--world.debugText("toTarget: " .. sb.printJson(toTarget), vec2.add(mcontroller.position(), {0,-4.0}), "yellow")
				local toTargetAngle = util.angleDiff(gunAngle, toTarget % (2*math.pi))
				--world.debugText("toTargetAngle: " .. sb.printJson(toTargetAngle), vec2.add(mcontroller.position(), {0,-0.0}), "red")
				--world.debugText("toTargetAngleValid: " .. sb.printJson(math.abs(toTargetAngle) <= 0.01), vec2.add(mcontroller.position(), {0,-0.2}), "red")
				
				if math.abs(toTargetAngle) <= (15 * math.pi / 180) then --15 degrees of lenience
					self.aiFireMachineguns = true --trigger firing of machine guns
				end
				
				-- this took me too long to make. i am in pain.
				
				self.gunnerAimPos = world.entityPosition(validTarget)
				--sb.logInfo(sb.printJson(validTarget))
				--world.debugLine(vec2.add(animator.partPoint("hatchGunnerGun", "firePoint"), mcontroller.position()), world.entityPosition(validTarget), {0,255,0,255})
			end
		end
	end

end

function updateHatchTurret(facing)
	
	local hatchGunnerEnt = vehicle.entityLoungingIn("hatchGunner")
	if (hatchGunnerEnt ~= nil and world.entityType(hatchGunnerEnt) ~= "npc") then
		-- PLAYER CONTROLLED
		if vehicle.controlHeld("hatchGunner","down") then
			self.hatchState = "closed"
			
			local effects = jarray()
			effects[1] = "invulnerable"
			effects[2] = "invisible"
			vehicle.setLoungeStatusEffects("hatchGunner", effects)
			--vehicle.setLoungeOrientation("hatchGunner", "stand")
		end
		if vehicle.controlHeld("hatchGunner","up") then
			self.hatchState = "opened"
			
			vehicle.setLoungeStatusEffects("hatchGunner", jarray())
			--vehicle.setLoungeOrientation("hatchGunner", "stand")
		end
	else
		-- AI CONTROLLED; must always be opened due to a weird quirk with NPCs not getting status effects from vehicles?
		vehicle.setLoungeStatusEffects("hatchGunner", jarray())
		self.hatchState = "opened"
		
		--if self.aiFireMachineguns then --open
			--self.hatchState = "opened"
			
			--vehicle.setLoungeStatusEffects("hatchGunner", jarray())
		--else -- closed
			--self.hatchState = "closed"
			
			--local effects = jarray()
			--effects[1] = "invulnerable"
			--effects[2] = "invisible"
			--vehicle.setLoungeStatusEffects("hatchGunner", effects)
		--end
	end
	
	animator.setGlobalTag("hatchState", self.hatchState)
	
	
	if self.hatchState == "opened" and (vehicle.entityLoungingIn("hatchGunner") ~= nil) then
		local diff = world.distance(vec2.add({0,3.2},self.gunnerAimPos), vec2.add(mcontroller.position(),animator.partPoint("hatchGunnerGun", "rotationCenter")))
		local aimAngle = math.atan(diff[2], diff[1])
		local mechAimLimit = 30 * math.pi / 180
		local hatchGunnerProjectile = config.getParameter("hatchGunnerProjectile")
		local hatchGunnerProjectileConfig = config.getParameter("hatchGunnerProjectileConfig")
		local hatchGunnerFireCycle = config.getParameter("hatchGunnerFireCycle")
		
		if (vehicle.entityLoungingIn("hatchGunner") ~= nil) and (vehicle.entityLoungingIn("drivingSeat") == nil) then
			vehicle.setDamageTeam(world.entityDamageTeam(vehicle.entityLoungingIn("hatchGunner")))
		end
		
		if facing < 0 then
			if aimAngle > 0 then
				aimAngle = math.max(aimAngle, math.pi - mechAimLimit + self.angle)
			else
				aimAngle = math.min(aimAngle, -math.pi + mechAimLimit + self.angle)
			end

			animator.rotateGroup("hatchGunner", math.pi - aimAngle + self.angle)
		else
			if aimAngle - self.angle > 0 then
				aimAngle = math.min(aimAngle, mechAimLimit + self.angle)
			else
				aimAngle = math.max(aimAngle, -mechAimLimit + self.angle)
			end

			animator.rotateGroup("hatchGunner", aimAngle - self.angle)
		end
		
		
		if (vehicle.controlHeld("hatchGunner", "primaryFire") or self.aiFireMachineguns) then
			if self.gunnerTimer <= 0 then
				animator.playSound("hatchGunnerFire")
				world.spawnProjectile("gic_muzzleflashprojectile",vec2.add(mcontroller.position(), animator.partPoint("hatchGunnerGun", "firePoint")),entity.id(),{0,0},false,{})
				world.spawnProjectile(hatchGunnerProjectile, vec2.add(mcontroller.position(), animator.partPoint("hatchGunnerGun", "firePoint")), entity.id(), aimVector(aimAngle,0.0175), false, hatchGunnerProjectileConfig)
				self.gunnerTimer = self.gunnerTimer + hatchGunnerFireCycle
				animator.setAnimationState("hatchGunnerFiring", "fire")
			end
		end
		if self.gunnerTimer > 0 then self.gunnerTimer = self.gunnerTimer - script.updateDt() end
		
	end
end

function updateDriving()
  local moving = false
  local facing = self.facingDirection
  local diff = world.distance(vec2.add({0,1.25},vehicle.aimPosition("drivingSeat")), vec2.add(mcontroller.position(),animator.partPoint("frontGun", "rotationCenter")))
  local aimAngle = math.atan(diff[2], diff[1])
  local facingDirection --= (aimAngle > math.pi / 2 or aimAngle < -math.pi / 2) and -1 or 1
  local mechAimLimit = config.getParameter("mechAimLimit") * math.pi / 180
  local mechProjectile = config.getParameter("mechProjectile")
  local mechProjectile2 = config.getParameter("mechProjectile2")
  local mechProjectileConfig = config.getParameter("mechProjectileConfig")
  local mechProjectile2Config = config.getParameter("mechProjectile2Config")
  local mechFireCycle = config.getParameter("mechFireCycle")
  local mechFireCycle2 = config.getParameter("mechFireCycle2")
	
  local driverThisFrame = vehicle.entityLoungingIn("drivingSeat")
  
	if world.distance(vehicle.aimPosition("drivingSeat"), mcontroller.position())[1] > 0 and storage.health > 0 then
		facingDirection = 1
	else
		facingDirection = -1
	end
  
  if (driverThisFrame ~= nil) then
    vehicle.setDamageTeam(world.entityDamageTeam(driverThisFrame))

  if facingDirection < 0 then
    facing = -1

    if aimAngle > 0 then
      aimAngle = math.max(aimAngle, math.pi - mechAimLimit + self.angle)
    else
      aimAngle = math.min(aimAngle, -math.pi + mechAimLimit + self.angle)
    end

    animator.rotateGroup("guns", math.pi - aimAngle + self.angle)
  else
    facing = 1

    if aimAngle - self.angle > 0 then
      aimAngle = math.min(aimAngle, mechAimLimit + self.angle)
    else
      aimAngle = math.max(aimAngle, -mechAimLimit + self.angle)
    end

    animator.rotateGroup("guns", aimAngle - self.angle)
  end
	
	
	--stops driving/shooting when tank is about to explode
	if storage.health > 0 then
	
	
    if vehicle.controlHeld("drivingSeat", "left") then
      mcontroller.approachXVelocity(-self.targetMoveSpeed, self.moveControlForce)
      moving = true
    end

    if vehicle.controlHeld("drivingSeat", "right") then
      mcontroller.approachXVelocity(self.targetMoveSpeed, self.moveControlForce)
      moving = true
    end
	
	
	
	
    if vehicle.controlHeld("drivingSeat", "altFire") then
      if self.fireTimer <= 0 then
		
		--muzzle flashes
		world.spawnProjectile("gic_muzzleflashprojectile",vec2.add(mcontroller.position(), animator.partPoint("frontGun", "firePoint")),entity.id(),{0,0},false,{timeToLive = 0.3})
		world.spawnProjectile("gic_muzzleflashprojectile",vec2.add(mcontroller.position(), animator.partPoint("frontGun", "firePoint")),entity.id(),{0,0},false,{timeToLive = 0.3})
		world.spawnProjectile("gic_muzzleflashprojectile",vec2.add(mcontroller.position(), animator.partPoint("frontGun", "firePoint")),entity.id(),{0,0},false,{timeToLive = 0.3})
		
        world.spawnProjectile(mechProjectile, vec2.add(mcontroller.position(), animator.partPoint("frontGun", "firePoint")), entity.id(), {math.cos(aimAngle), math.sin(aimAngle)}, false, mechProjectileConfig)
        self.fireTimer = self.fireTimer + mechFireCycle
        animator.setAnimationState("frontFiring", "fire")
	  end
    end
	
	if self.fireTimer > 0 then self.fireTimer = self.fireTimer - script.updateDt() end
	
	
    if vehicle.controlHeld("drivingSeat", "primaryFire") then
      if self.fireTimer2 <= 0 then
	  world.spawnProjectile("gic_muzzleflashprojectile",vec2.add(mcontroller.position(), animator.partPoint("frontGun2", "firePoint2")),entity.id(),{0,0},false,{})
        world.spawnProjectile(mechProjectile2, vec2.add(mcontroller.position(), animator.partPoint("frontGun2", "firePoint2")), entity.id(), aimVector(aimAngle,0.03), false, mechProjectile2Config)
        self.fireTimer2 = self.fireTimer2 + mechFireCycle2
        animator.setAnimationState("frontFiring2", "fire")
      end
    end
	
	if self.fireTimer2 > 0 then self.fireTimer2 = self.fireTimer2 - script.updateDt() end
	
	
    if vehicle.controlHeld("drivingSeat", "up") then
      if self.headlightCanToggle then

        if self.headlightsOff then
          animator.playSound("headlightSwitchOn")
		  animator.setLightActive("headlightBeam", true)
		  animator.setLightActive("headlightBeam2", true)
		  animator.setAnimationState("headlights", "on")
		  self.headlightsOff = false
        else
          animator.playSound("headlightSwitchOff")
		  animator.setLightActive("headlightBeam", false)
		  animator.setLightActive("headlightBeam2", false)
		  animator.setAnimationState("headlights", "off")
		  self.headlightsOff = true
        end

        self.headlightCanToggle = false
        end
      else
      self.headlightCanToggle = true;
    end
	
	end
  else
    vehicle.setDamageTeam({type = "passive"})
  end
  
  return moving, facing
end

function aimVector(aimAngle,inaccuracy)
  local aimVector = vec2.rotate({1, 0}, (aimAngle + sb.nrand(inaccuracy, 0)))
  --aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

  --vehicle weapon scriptover
  
function visualDamageEffects()
	local healthPercentage = storage.health/self.maxHealth
	
	if healthPercentage <= 0.75 then
		animator.setParticleEmitterActive("burningSmoke1", true)
	else animator.setParticleEmitterActive("burningSmoke1", false) end
	
	if healthPercentage <= 0.5 then
		animator.setParticleEmitterActive("burningSmoke2", true)
	else animator.setParticleEmitterActive("burningSmoke2", false) end
	
	if healthPercentage <= 0.25 then
		animator.setParticleEmitterActive("burningSmoke3", true)
	else animator.setParticleEmitterActive("burningSmoke3", false) end
	
	if healthPercentage <= 0 then 
		animator.setParticleEmitterActive("burningSmoke4", true) 
	else animator.setParticleEmitterActive("burningSmoke4", false) end

end
	
function updateSinking(waterFactor, currentAngle, sinkAngle)
  self.sinkTimer = self.sinkTimer - script.updateDt()
  if self.sinkTimer <= 0 or mcontroller.onGround() then
    animator.playSound("changeDamageState")
    animator.setParticleEmitterBurstCount("damageShards", config.getParameter("destroyParticleBurstCount"))
    animator.burstParticleEmitter("damageShards")
    vehicle.destroy()
  else
    if (waterFactor > self.minWaterFactorToFloat) then
      if (currentAngle ~= sinkAngle) then
        currentAngle = currentAngle + (sinkAngle - currentAngle) * self.angleApproachFactor

        local lerpFactor = math.cos(currentAngle - sinkAngle)
        local finalBuoyancy = (self.maxBuoyancy * (1.0 - lerpFactor)) + (self.sinkingBuoyancy * lerpFactor)
        mcontroller.applyParameters({
            liquidBuoyancy = finalBuoyancy,
            liquidFriction = self.sinkingFriction,
            frictionEnabled = true
          })
      end
      animator.setParticleEmitterActive("bubbles", true)
    end
  end

  return currentAngle
end

function updateFloating(waterFactor, moving, facing)
  local floating = waterFactor > self.minWaterFactorToFloat

  local targetAngle
  if (floating) then
    self.rockingTimer = self.rockingTimer + script.updateDt()
    if self.rockingTimer > self.rockingInterval then
      self.rockingTImer = self.rockingTimer - self.rockingInterval
    end

    local speedAngle = mcontroller.xVelocity() * self.speedRotationMultiplier

    local windPosition = vec2.add(mcontroller.position(), self.windLevelOffset)
    local windLevel = world.windLevel(windPosition)
    local windMaxAngle = self.rockingWindAngleMultiplier * windLevel
    local windAngle = windMaxAngle * (math.sin(self.rockingTimer / self.rockingInterval * (math.pi * 2)))

    targetAngle = windMaxAngle + speedAngle
  else
    targetAngle = calcGroundCollisionAngle(self.waterBounds[2]) --pass in the water surface
  end

  self.angle = self.angle + (targetAngle - self.angle) * self.angleApproachFactor

  if waterFactor > (self.waterFactor + self.splashEpsilon) then
    local floatingLiquid = mcontroller.liquidId()
    if (floatingLiquid > 0) then
      if (floatingLiquid > #self.bowWaveParticleNames) then
        floatingLiquid = 1 --off the end, go to "water" as a default
      end

      local splashEmitter=self.splashParticleNames[floatingLiquid]

      animator.setParticleEmitterOffsetRegion(splashEmitter,self.waterBounds)

      animator.burstParticleEmitter(splashEmitter)
    end
  end
  return floating
end

function updateMovingEffects(floating, moving)
  if moving then
    animator.setAnimationState("propeller", "turning")
	if floating then
      local floatingLiquid = mcontroller.liquidId()
      if (floatingLiquid > 0) then
        if (floatingLiquid > #self.bowWaveParticleNames) then
          floatingLiquid = 1 --off the end, go to "water" as a default
        end

        local bowWaveEmitter = self.bowWaveParticleNames[floatingLiquid]

        local rateFactor = math.abs(mcontroller.xVelocity()) / self.targetMoveSpeed
        rateFactor = rateFactor * self.bowWaveMaxEmissionRate
        animator.setParticleEmitterEmissionRate(bowWaveEmitter, rateFactor)

        local bowWaveBounds = self.waterBounds
        animator.setParticleEmitterOffsetRegion(bowWaveEmitter, bowWaveBounds)

        animator.setParticleEmitterActive(bowWaveEmitter, true)
      end
    end
  else
    animator.setAnimationState("propeller", "still")
    for i, emitter in ipairs(self.bowWaveParticleNames) do
       animator.setParticleEmitterActive(emitter, false)
    end
  end
  
  if moving then
      animator.setParticleEmitterActive("smoke", true)
  else
    animator.setParticleEmitterActive("smoke", false)
  end
  
  if moving then
      animator.setParticleEmitterActive("smoke3", true)
  else
    animator.setParticleEmitterActive("smoke3", false)
  end
  if moving then
      animator.setParticleEmitterActive("smoke3a", true)
  else
    animator.setParticleEmitterActive("smoke3a", false)
  end
  
  if moving then
      animator.setParticleEmitterActive("smoke2", true)
  end
end


--headlight script

function switchHeadLights(oldIndex, newIndex, activate)
  if (activate ~= self.headlightsOn or oldIndex ~= newIndex) then
    local listOfLists = config.getParameter("lightsInDamageState")

    if (listOfLists ~= nil) then
      if (oldIndex ~= newIndex) then
        local listToSwitchOff = listOfLists[oldIndex]
        for i, name in ipairs(listToSwitchOff) do
          animator.setLightActive(name, false)
        end
      end

        local listToSwitchOn = listOfLists[newIndex]
        for i, name in ipairs(listToSwitchOn) do
        animator.setLightActive(name, activate)
      end
    end
    self.headlightsOn = activate

    if (self.headlightsOn) then
      animator.setAnimationState("headlights", "on")
    else
      animator.setAnimationState("headlights", "off")
    end
  end
end

--headlight script over

--make the driver emote according to the damage state of the vehicle
function updatePassengers(healthFactor)
  if healthFactor >= 0 then
    --if we have a scared face on because of taking damage
    if self.damageEmoteTimer > 0 then
      self.damageEmoteTimer = self.damageEmoteTimer - script.updateDt()
      if (self.damageEmoteTimer < 0) then
        maxDamageState = #self.damageStateDriverEmotes
        damageStateIndex = maxDamageState
        damageStateIndex = (maxDamageState - math.ceil(healthFactor * maxDamageState)) + 1
        vehicle.setLoungeEmote("drivingSeat", self.damageStateDriverEmotes[damageStateIndex])
      end
    end
  end
end

function applyDamage(damageRequest)
  local damage = 0
  
  local resistancesParam = config.getParameter("resistances")
  
  if damageRequest.damageSourceKind == "ews_melee" or damageRequest.damageType == "IgnoresDef" then
	if resistancesParam[damageRequest.damageSourceKind] then
		--sb.logInfo(damageResist)
		damage = damage + damageRequest.damage * (1 - resistancesParam[damageRequest.damageSourceKind])
	else
		damage = damage + damageRequest.damage
	end
  else
	--local drReq = root.evalFunction2("protection", damageRequest.damage, config.getParameter("protection"))
	
	if resistancesParam[damageRequest.damageSourceKind] then
		damage = damage + root.evalFunction2("protection", damageRequest.damage, config.getParameter("protection")) * (1 - resistancesParam[damageRequest.damageSourceKind])
	else
		damage = damage + root.evalFunction2("protection", damageRequest.damage, config.getParameter("protection"))
	end
  end
  
  --if damageRequest.damageType == "Damage" then
    --damage = damage + root.evalFunction2("protection", damageRequest.damage, self.protection)
 --elseif damageRequest.damageType == "IgnoresDef" then
    --damage = damage + damageRequest.damage
  --else
    --return {}
  --end
  
  --sb.logInfo(sb.printJson(damageRequest.statusEffects))
  --sb.logInfo(sb.printJson(damageRequest.statusEffects[1].effect == "gic_wrench"))
 -- sb.logInfo(sb.printJson((not damageRequest.statusEffects == nil) and damageRequest.statusEffects[1].effect == "gic_wrench"))
  if damageRequest.statusEffects and damageRequest.statusEffects[1] and damageRequest.statusEffects[1].effect == "gic_wrench" and storage.health > 0 then
	damage = 0
	if storage.health < self.maxHealth then
		local healthGained = math.min(100, self.maxHealth - storage.health)
		storage.health = storage.health + healthGained
	
		self.repairedHealth = healthGained
		self.queRepairText = true
	end
  end

  updateDamageEffects(damage, false)
  
  --sb.logInfo(sb.printJson(damageRequest.damageSourceKind))
  --sb.logInfo(damage)

  local healthLost = math.min(damage, storage.health)
  storage.health = storage.health - healthLost

  return {{
    sourceEntityId = damageRequest.sourceEntityId,
    targetEntityId = entity.id(),
    position = mcontroller.position(),
    damageDealt = damage,
    healthLost = healthLost,
    hitType = "Hit",
    damageSourceKind = damageRequest.damageSourceKind,
    targetMaterialKind = self.materialKind,
    killed = storage.health <= 0
  }}
end

function setDamageEmotes()
  local damageTakenEmote = config.getParameter("damageTakenEmote")
  self.damageEmoteTimer = config.getParameter("damageEmoteTime")
  vehicle.setLoungeEmote("drivingSeat", damageTakenEmote)
end

function updateDamageEffects(damage, initialise)
  local maxDamageState = #self.damageStateNames
  local healthFactor = (storage.health - damage) / self.maxHealth
  local prevhealthFactor = storage.health / self.maxHealth

  local prevDamageStateIndex = util.clamp(maxDamageState - math.ceil(prevhealthFactor * maxDamageState) + 1, 1, maxDamageState)
  self.damageStateIndex = util.clamp(maxDamageState - math.ceil(healthFactor * maxDamageState) + 1, 1, maxDamageState)

  if ((self.damageStateIndex > prevDamageStateIndex) or initialise == true) then
    animator.setGlobalTag("damageState", self.damageStateNames[self.damageStateIndex])

    local settingsNameList = config.getParameter("damageMovementSettingNames")
    local settingsObject = config.getParameter(settingsNameList[self.damageStateIndex])

    self.maxBuoyancy = mcontroller.parameters().liquidBuoyancy

    mcontroller.applyParameters(settingsObject)
  end

  if (self.damageStateIndex > prevDamageStateIndex) then
    setDamageEmotes(healthFactor)

    animator.burstParticleEmitter("damageShards")
    animator.playSound("changeDamageState")
  end
end


function calcGroundCollisionAngle(waterSurface)
  local frontDistance = math.min(distanceToGround(self.frontGroundTestPoint), waterSurface)
  local backDistance = math.min(distanceToGround(self.backGroundTestPoint), waterSurface)

  if frontDistance == self.maxGroundSearchDistance and backDistance == self.maxGroundSearchDistance then
	frontDistance = math.min(distanceToGround(self.frontGroundTestPoint2, self.maxGroundSearchDistance * 3), waterSurface)
	backDistance = math.min(distanceToGround(self.backGroundTestPoint2, self.maxGroundSearchDistance * 3), waterSurface)
	
	if frontDistance == self.maxGroundSearchDistance and backDistance == self.maxGroundSearchDistance then
		return 0--self.angle
	else
		return -math.atan(backDistance - frontDistance)
	end
  else
    return -math.atan(backDistance - frontDistance)
  end
end

function distanceToGround(point,maximum)
  -- to worldspace
  if not maximum then maximum = self.maxGroundSearchDistance end
  point = vec2.rotate(point, self.angle)
  point = vec2.add(point, mcontroller.position())

  local endPoint = vec2.add(point, {0, -maximum})
  local intPoint = world.lineCollision(point, endPoint)

  if intPoint then
     world.debugPoint(intPoint, {255, 255, 0, 255})
    return point[2] - intPoint[2]
  else
     world.debugPoint(endPoint, {255, 0, 0, 255})
    return maximum
  end
end
