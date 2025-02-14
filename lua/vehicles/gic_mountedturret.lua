require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.reactionTime = 0
  self.hadTarget = false

  vehicle.setPersistent(true)
  self.specialLast = false
  self.rockingTimer = 0
  self.facingDirection = 1
  self.angle = 0
  --animator.setParticleEmitterActive("bubbles", false)
  self.damageEmoteTimer = 0
  self.jammedRepairReq = 0 --once build process hits is equal to this, unjam. will be set dynamically down below.
  
  vehicle.setPersistent(true)
  --if not mcontroller.onGround() then --fix summon positions
	--mcontroller.setYPosition(mcontroller.yPosition()-1)
  --end
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
  self.headlightCanToggle = false -- disabled headlight for now, may reenable with a proper flashlight thing on the turret
  self.headlightsOff = true
  animator.setAnimationState("headlights", "off")
    
  local bounds = mcontroller.localBoundBox()
  self.frontGroundTestPoint = {bounds[1], bounds[2]}
  self.backGroundTestPoint = {bounds[3], bounds[2]}

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
	  
   -- setup boarding follower functionality (largely ripped from the shuttlecraft mod)
  message.setHandler("gic_boardTurret",
      function(_, _, uuid, npcId)
  			if vehicle.entityLoungingIn("drivingSeat") == nil then 
				--if world.entityUniqueId(vehicle.entityLoungingIn("drivingSeat")) == uuid then
					self.boardGunner = npcId
				--end
			end
	  end)
  self.gunnerAimPos = vehicle.aimPosition("drivingSeat");

  if (storage.health) then
    animator.setAnimationState("base", "idle")
  else
    local startHealthFactor = config.getParameter("startHealthFactor")

    if (startHealthFactor == nil) then
        storage.health = self.maxHealth
    else
       storage.health = math.min(startHealthFactor * self.maxHealth, self.maxHealth)
    end
	
	storage.jammed = false
	storage.deterioration = 0
	storage.wrenchHit = config.getParameter("startingWrenchHit",0)
    animator.setAnimationState("base", "warpInPart1")
  end
  
  
  
  -- for building turret stuff
  if storage.wrenchHit < 7 then
	vehicle.setLoungeEnabled("drivingSeat", false)
  end
  animator.resetTransformationGroup("unattachedGun")
  animator.rotateTransformationGroup("unattachedGun", math.rad(-20))

  if storage.wrenchHit >= 7 then
	animator.setAnimationState("turret", "attached")			
	vehicle.setLoungeEnabled("drivingSeat", true)
	if storage.wrenchHit >= 10 then
		animator.setAnimationState("turret", "loaded")
	end
  end
  
  
  updateDamageEffects(0, true)
end

-- basically ripped from the shuttlecraft mod, edited and such for this vehicle's purposes though.
function gunnerEmbark(npcId)
			local driverSeat = "drivingSeat"
			local boardSeat = nil

			if world.entityType(npcId) == "npc" then
				if vehicle.entityLoungingIn(driverSeat) == nil and boardSeat == nil then
					boardSeat = 0
				end 
				if boardSeat ~= nil then 
					local beamin = false 
					if world.magnitude(world.entityPosition(npcId), mcontroller.position()) >= 20 then beamin = true end
					world.callScriptedEntity(npcId, "setShuttlecraftLounge", entity.id(), boardSeat, beamin )
				end
			end
	self.boardGunner = nil
end


function update()
  vehicle.setPersistent(true)
  
  -- optimizations, i.e. if AI controlled and no nearby targets, reduce updates per second until there are actually targets
  -- also triggers if there's no one on the turret
  local driverThisFrame = vehicle.entityLoungingIn("drivingSeat")
  if not self.possibleTargets or vehicle.entityLoungingIn("drivingSeat") == nil then
	if vehicle.entityLoungingIn("drivingSeat") == nil then
		script.setUpdateDelta(5) --can't have updates per tick reduced too low, otherwise turret repair will be profoundly laggy
	else script.setUpdateDelta(10) end
	
	self.dt = script.updateDt()
  elseif self.possibleTargets then
	script.setUpdateDelta(1)
	self.dt = script.updateDt()
  end
  
  
  local animState = animator.animationState("base")
  local waterFactor = mcontroller.liquidPercentage()

  if (animState == "warpedOut") then
    vehicle.destroy()
  elseif (animState == "warpInPart1" or animState == "warpOutPart2") then
    -- world.debugText("warping",mcontroller.position(),"red")

    mcontroller.setPosition(self.spawnPosition)
    mcontroller.setVelocity({0, 0})
  elseif (animState == "sinking") then
    -- world.debugText("sinking", mcontroller.position(), "red")

    self.angle = updateSinking(waterFactor, self.angle, -math.pi * 0.4)
  elseif (animState == "idle") then
    -- world.debugText("idle", mcontroller.position(), "green")
	
	if self.boardGunner then gunnerEmbark(self.boardGunner) end 

    local healthFactor = storage.health / self.maxHealth
    local waterSurface = self.maxGroundSearchDistance
    self.waterBounds = mcontroller.localBoundBox()

    --work out water surface
    if (waterFactor > 0) then
      waterSurface = (self.waterBounds[4] * waterFactor) + (self.waterBounds[2] * (1.0 - waterFactor))
    end

    self.waterBounds[2] = waterSurface + 0.25
    self.waterBounds[4] = waterSurface + 0.5

    -- world.debugText(string.format("WaterSurface=%s", self.waterBounds[2]), mcontroller.position(), "yellow")

  local moving, facing = updateDriving()
  aiTargeting()
  
    --Rocking in the wind, and rotating up when moving
    local floating = updateFloating(waterFactor, moving,facing)
    --updateMovingEffects(floating,moving)
    updatePassengers(healthFactor)

    if storage.health <= 0 then
      --vehicle.setLoungeEnabled("titanicPose", false)
	  animator.playSound("upgrade")
      animator.setAnimationState("base", "sinking")
      self.sinkTimer = 0--config.getParameter("maxSinkTime")
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
  
  
  --building turret code stuff
  updateBuilding()
  updateBuildingAi()
  
  if self.queRepairText == true then
	local configDat = config.getParameter("repairTextConfig")
	
	--sb.logInfo(sb.printJson(configDat.actionOnReap[1].action))
	configDat.actionOnReap[1].specification.text = "^green;+"..math.floor(self.repairedHealth+0.5).."/"..math.floor(self.maxHealth-storage.health+0.5).." HP^reset;"
	world.spawnProjectile("gic_null",mcontroller.position(),entity.id(),{0,0},false,configDat)
	self.queRepairText = false
  end
end


function aiTargeting()
	--world.debugLine(vec2.add(animator.partPoint("frontGun2", "firePoint2"), mcontroller.position()), self.gunnerAimPos, {255,0,0,255})
	
	self.possibleTargets = false
	self.aiFire = false
	if vehicle.entityLoungingIn("drivingSeat") == nil or world.entityType(vehicle.entityLoungingIn("drivingSeat")) ~= "npc" then
		self.gunnerAimPos = vehicle.aimPosition("drivingSeat")
		self.possibleTargets = true
		return
	else
		local npcId = vehicle.entityLoungingIn("drivingSeat")
		self.reactionTime = self.reactionTime - self.dt
		
		-- ok most of this is my own stuff but the base targeting code is ripped from the shuttlecraft mod
		-- anyways just also wanted to say that this stuff is cool, since *you can pull many functions from the NPC*, many more than I had thought possible!
		-- cool stuff since yeah main thing is that the AI targeting priorities here will be based off the targeting priorities of the NPC itself!
		
		local range = 60
		local targetList = world.entityQuery(mcontroller.position(), range, {withoutEntityId = npcId,includedTypes = {"npc", "monster", "player"}, order = "nearest"})
		local validTarget = nil
		if targetList[1] ~= nil then -- were we able to find valid targets?
			
			for i = 1, #targetList do 
				if world.callScriptedEntity(npcId, "entity.isValidTarget", targetList[i]) and world.callScriptedEntity(npcId, "entity.entityInSight", targetList[i]) then 
					if self.hadTarget == false then self.reactionTime = 0.5 end --ai has 0.5s to react
					self.possibleTargets = true
					validTarget = targetList[i]
					break
				end
			end
			
			self.hadTarget = self.possibleTargets
			
			
			if validTarget ~= nil then
				
				if self.reactionTime > 0 then return end
				
				local pos = vec2.add(mcontroller.position(),animator.partPoint("frontGun2", "firePoint2"))
				local canPos = world.entityPosition(validTarget)
				local diff = world.distance(vec2.add({0,3.2},canPos), pos)
				local aimAngle = math.atan(diff[2], diff[1])
				
				local facing = 0
				if world.distance(self.gunnerAimPos, mcontroller.position())[1] > 0 and storage.health > 0 then
					facing = 1
				else
					facing = -1
				end
				
				local gunAngle = animator.currentRotationAngle("guns")
				if facing < 0 then 
					gunAngle = math.pi - gunAngle + self.angle
				else
					gunAngle = gunAngle + self.angle
				end
				--world.debugLine(pos, vec2.add(pos,{100*math.cos(gunAngle),100*math.sin(gunAngle)}), {0,0,255,255})
				
				local toTarget = vec2.angle(world.distance(canPos, pos))
				--world.debugLine(pos, vec2.add(pos,{100*math.cos(toTarget),100*math.sin(toTarget)}), {255,0,255,255})
				local toTargetAngle = util.angleDiff(gunAngle, toTarget % (2*math.pi))
				
				if math.abs(toTargetAngle) <= (5 * math.pi / 180) then --5 degrees of lenience
					self.aiFire = true --trigger firing of machine guns
				end
				
				self.gunnerAimPos = world.entityPosition(validTarget)
				--sb.logInfo(sb.printJson(validTarget))
				--world.debugLine(vec2.add(animator.partPoint("frontGun2", "firePoint2"), mcontroller.position()), world.entityPosition(validTarget), {0,255,0,255})
			end
		end
	end

end

-- equivalent "controls" function (compared to other later GiC vehicles)
function updateDriving()
  local moving = false
  local facing = self.facingDirection
  local diff = world.distance(self.gunnerAimPos, vec2.add(mcontroller.position(),animator.partPoint("frontGun2", "rotationCenter")))
  local aimAngle = math.atan(diff[2], diff[1])
  local facingDirection = (aimAngle > math.pi / 2 or aimAngle < -math.pi / 2) and -1 or 1
  local mechAimLimit = config.getParameter("mechAimLimit") * math.pi / 180
  local mechProjectile = config.getParameter("mechProjectile")
  local mechProjectile2 = config.getParameter("mechProjectile2")
  local mechProjectileConfig = config.getParameter("mechProjectileConfig")
  local mechProjectile2Config = config.getParameter("mechProjectile2Config")
  local mechFireCycle = config.getParameter("mechFireCycle")
  local mechFireCycle2 = config.getParameter("mechFireCycle2")
	
  local driverThisFrame = vehicle.entityLoungingIn("drivingSeat")
  
  
  
  
  
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

    if aimAngle > 0 then
      aimAngle = math.min(aimAngle, mechAimLimit + self.angle)
    else
      aimAngle = math.max(aimAngle, -mechAimLimit + self.angle)
    end

    animator.rotateGroup("guns", aimAngle - self.angle)
  end
	
    -- if vehicle.controlHeld("drivingSeat", "left") then
      -- mcontroller.approachXVelocity(-self.targetMoveSpeed, self.moveControlForce)
      -- moving = true
    -- end

    -- if vehicle.controlHeld("drivingSeat", "right") then
      -- mcontroller.approachXVelocity(self.targetMoveSpeed, self.moveControlForce)
      -- moving = true
    -- end
	
	--disable the alt fire function
    --if vehicle.controlHeld("drivingSeat", "altFire") then
      --if self.fireTimer <= 0 then
        --world.spawnProjectile(mechProjectile, vec2.add(mcontroller.position(), animator.partPoint("frontGun", "firePoint")), entity.id(), {math.cos(aimAngle), math.sin(aimAngle)}, false, mechProjectileConfig)
        --self.fireTimer = self.fireTimer + mechFireCycle
        --animator.setAnimationState("frontFiring", "fire")
      --else
        --local oldFireTimer = self.fireTimer
        --self.fireTimer = self.fireTimer - script.updateDt()
        --if oldFireTimer > mechFireCycle / 2 and self.fireTimer <= mechFireCycle / 2 then
          --world.spawnProjectile(mechProjectile, vec2.add(mcontroller.position(), animator.partPoint("frontGun", "firePoint")), entity.id(), {math.cos(aimAngle), math.sin(aimAngle)}, false, mechProjectileConfig)
          --animator.setAnimationState("frontFiring", "fire")
        --end
      --end
    --end
	
	
	local inaccuracy = config.getParameter("inaccuracy",0.02)
	local deteriorationMult = config.getParameter("deteriorationMultiplier",0.75)
	--gun will only function if turret is "loaded"
    if (vehicle.controlHeld("drivingSeat", "primaryFire") or self.aiFire) and animator.animationState("turret") == "loaded" and storage.jammed == false then
	  local projectile = ""
	  local missChanceRoll = math.random(0,100)
	  local missChance = config.getParameter("missChance",20)
	  
	  if missChanceRoll <= missChance then
		projectile = config.getParameter("missProjectile")
	  else
		projectile = mechProjectile2
	  end
	  
	  local jamChanceRoll = 1000 --will be within (0-1000)
	  local jamChance = storage.deterioration - 75 --make this slowly bump up with firing, cap it at 100
	  
      if self.fireTimer2 <= 0 then
		jamChanceRoll = math.random(0,jamChanceRoll)
        world.spawnProjectile(projectile, vec2.add(mcontroller.position(), animator.partPoint("frontGun2", "firePoint2")), entity.id(), aimVector(aimAngle,inaccuracy), false, mechProjectile2Config)
        self.fireTimer2 = self.fireTimer2 + mechFireCycle2
        animator.setAnimationState("frontFiring2", "fire")
		animator.playSound("fire")
		
		storage.deterioration = math.min(storage.deterioration+1*deteriorationMult,100)
		
		--animator.burstParticleEmitter("muzzleFlash")
		--animator.burstParticleEmitter("hotsmoke")
      else
        local oldFireTimer2 = self.fireTimer2
        self.fireTimer2 = self.fireTimer2 - script.updateDt()
        if oldFireTimer2 > mechFireCycle2 / 2 and self.fireTimer2 <= mechFireCycle2 / 2 then
		  jamChanceRoll = math.random(0,jamChanceRoll)
          world.spawnProjectile(projectile, vec2.add(mcontroller.position(), animator.partPoint("frontGun2", "firePoint2")), entity.id(), aimVector(aimAngle,inaccuracy), false, mechProjectile2Config)
          animator.setAnimationState("frontFiring2", "fire")
		  animator.playSound("fire")
		  
		  storage.deterioration = math.min(storage.deterioration+1*deteriorationMult,100)
		  
		  --animator.burstParticleEmitter("muzzleFlash")
		  --animator.burstParticleEmitter("hotsmoke")
        end
      end
	  
	  if storage.jammed == false and jamChanceRoll <= jamChance then
		local spawnPos = vec2.add(mcontroller.position(),{0,2})
		
		animator.playSound("jam")
		world.spawnProjectile(config.getParameter("textProjectile"),spawnPos,entity.id(),{0,0},false,config.getParameter("jammedTextConfig"))
		storage.jammed = true
		self.jammedRepairReq = storage.wrenchHit + 5
	  end
    end
	
	
    -- if vehicle.controlHeld("drivingSeat", "up") then
      -- if self.headlightCanToggle then

        -- if self.headlightsOff then
          -- animator.playSound("headlightSwitchOn")
		  -- animator.setLightActive("headlightBeam", true)
		  -- animator.setAnimationState("headlights", "on")
		  -- self.headlightsOff = false
        -- else
          -- animator.playSound("headlightSwitchOff")
		  -- animator.setLightActive("headlightBeam", false)
		  -- animator.setAnimationState("headlights", "off")
		  -- self.headlightsOff = true
        -- end

        -- self.headlightCanToggle = false
        -- end
      -- else
      -- self.headlightCanToggle = true;
    -- end
	
	
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

  
  --custom code regarding "building" the turret n etc
function updateBuilding()
	--world.debugText("hit by wrench times: " .. storage.wrenchHit, vec2.add(mcontroller.position(), {0,1.5}), "yellow")
	--world.debugText("deterioration: " .. storage.deterioration, vec2.add(mcontroller.position(), {0,2.5}), "yellow")
	
	if self.showJammedText == true then
		self.showJammedText = false
		
		local spawnPos = vec2.add(mcontroller.position(),{0,2})
		world.spawnProjectile(config.getParameter("textProjectile"),spawnPos,entity.id(),{0,0},false,config.getParameter("unjammedTextConfig"))
	end
	
	if self.fullyRepaired == true then
		self.fullyRepaired = false
		
		local spawnPos = vec2.add(mcontroller.position(),{0,2})
		world.spawnProjectile(config.getParameter("textProjectile"),spawnPos,entity.id(),{0,0},false,config.getParameter("repairedTextConfig"))
	end
	
	--localAnimator.addDrawable({line = {vec2.add(mcontroller.position(), {-1,1.5}), vec2.add(mcontroller.position(), {1,1.5})}, width = 10, color = "red", position = mcontroller.position(), fullbright = true})
end

-- AI for repairing
function updateBuildingAi()	
	if (vehicle.entityLoungingIn("drivingSeat") ~= nil) and (world.entityType(vehicle.entityLoungingIn("drivingSeat")) == "npc") then
		if not self.aiTime then self.aiTime = 0 end
		self.aiTime = math.max(0,self.aiTime - self.dt)
		
		if not self.aiBufferTime then self.aiBufferTime = 0 end
		self.aiBufferTime = math.max(0,self.aiBufferTime - self.dt)
		
		if self.aiFire then self.aiBufferTime = 5 end --seconds; buffer time between engagements and repairing
		
		local canRepair = (storage.health > 0 and storage.health < self.maxHealth) or (storage.deterioration > 0)
		
		if storage.jammed then -- unjamming repairs
			if self.aiTime == 0 then 
				self.aiTime = 1.5 --seconds to repair
				storage.wrenchHit = storage.wrenchHit + 1
				
				if storage.wrenchHit >= self.jammedRepairReq then
					storage.jammed = false
					self.showJammedText = true
					animator.playSound("upgrade")
					storage.deterioration = 0
				else
					animator.playSound("repair")
				end
			end
		elseif not self.aiFire then -- standard repairs
			if self.aiTime == 0 and self.aiBufferTime == 0 and canRepair then 
				self.aiTime = 1.5 --seconds between repairs
				
				local healthGained = math.min(100, self.maxHealth - storage.health)
				storage.health = storage.health + healthGained
	
				self.repairedHealth = healthGained
				animator.playSound("repair")
					
				storage.wrenchHit = storage.wrenchHit + 1
				storage.deterioration = math.max(storage.deterioration - 20,0)
				
				
				local configDat = config.getParameter("repairTextConfig")
				
				configDat.actionOnReap[1].specification.text = "^green;+"..math.floor(self.repairedHealth+0.5).."/"..math.floor(self.maxHealth-storage.health+0.5).." HP^reset;"
				world.spawnProjectile("gic_null",mcontroller.position(),entity.id(),{0,0},false,configDat)
			end
		end
	end
end
	
function updateSinking(waterFactor, currentAngle, sinkAngle)
  self.sinkTimer = self.sinkTimer - script.updateDt()
  if self.sinkTimer <= 0 or mcontroller.onGround() then
    animator.playSound("changeDamageState")
    --animator.setParticleEmitterBurstCount("damageShards", config.getParameter("destroyParticleBurstCount"))
    --animator.burstParticleEmitter("damageShards")
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

      --local splashEmitter=self.splashParticleNames[floatingLiquid]

      --animator.setParticleEmitterOffsetRegion(splashEmitter,self.waterBounds)

      --animator.burstParticleEmitter(splashEmitter)
    end
  end
  return floating
end

function updateMovingEffects(floating, moving)
  if moving then
    --animator.setAnimationState("propeller", "turning")
	if floating then
      local floatingLiquid = mcontroller.liquidId()
      if (floatingLiquid > 0) then
        if (floatingLiquid > #self.bowWaveParticleNames) then
          floatingLiquid = 1 --off the end, go to "water" as a default
        end

        local bowWaveEmitter = self.bowWaveParticleNames[floatingLiquid]

        local rateFactor = math.abs(mcontroller.xVelocity()) / self.targetMoveSpeed
        rateFactor = rateFactor * self.bowWaveMaxEmissionRate
        --animator.setParticleEmitterEmissionRate(bowWaveEmitter, rateFactor)

        local bowWaveBounds = self.waterBounds
        --animator.setParticleEmitterOffsetRegion(bowWaveEmitter, bowWaveBounds)

        --animator.setParticleEmitterActive(bowWaveEmitter, true)
      end
    end
  else
    --animator.setAnimationState("propeller", "still")
    --for i, emitter in ipairs(self.bowWaveParticleNames) do
       --animator.setParticleEmitterActive(emitter, false)
    --end
  end
  
  --if moving then
     -- animator.setParticleEmitterActive("smoke", true)
  --else
    --animator.setParticleEmitterActive("smoke", false)
  --end
  
  --if moving then
      --animator.setParticleEmitterActive("smoke3", true)
  --else
    --animator.setParticleEmitterActive("smoke3", false)
  --end
  --if moving then
      --animator.setParticleEmitterActive("smoke3a", true)
  --else
    --animator.setParticleEmitterActive("smoke3a", false)
  --end
  
  --if moving then
      --animator.setParticleEmitterActive("smoke2", true)
  --end
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
  --self.takeDamage = false
  
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
  
  
  if damageRequest.statusEffects then
	if damageRequest.statusEffects[1] then
		if damageRequest.statusEffects[1].effect == "gic_wrench" then
			damage = 0
			
			if storage.health > 0 and storage.health < self.maxHealth then
				local healthGained = math.min(100, self.maxHealth - storage.health)
				storage.health = storage.health + healthGained
				--sb.logInfo(storage.health)
	
				self.repairedHealth = healthGained
				self.queRepairText = true
			end
			
			--self.takeDamage = true
			storage.wrenchHit = storage.wrenchHit + 1
			storage.deterioration = math.max(storage.deterioration - 20,0)
			
			if storage.deterioration == 0 and storage.wrenchHit > 10 and not storage.jammed == true then
				self.fullyRepaired = true
			end
			
			if storage.wrenchHit == 7 and animator.animationState("turret") == "idle" then
				animator.setAnimationState("turret", "attached")
				
				vehicle.setLoungeEnabled("drivingSeat", true)
				animator.playSound("upgrade")
			end
			
			if storage.wrenchHit == 10 and animator.animationState("turret") == "attached" then
				animator.setAnimationState("turret", "loaded")
				animator.playSound("upgrade")
			end
			
			if storage.jammed == true and storage.wrenchHit >= self.jammedRepairReq then
				storage.jammed = false
				self.showJammedText = true
				animator.playSound("upgrade")
				storage.deterioration = 0
			end
		end
	end
  end
  
  
  
  --if self.takeDamage == false then
	--damageRequest.damageSourceKind = "noDamage"
  --end
  
  --if config.getParameter("canBeHit") then
	--if damageRequest.damageType == "Damage" then
		--damage = damage + root.evalFunction2("protection", damageRequest.damage, self.protection)
	--elseif damageRequest.damageType == "IgnoresDef" then
		--damage = damage + damageRequest.damage
	--else
		--return {}
	--end
  --end

  --updateDamageEffects(damage, false)

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
    --setDamageEmotes(healthFactor)

    --animator.burstParticleEmitter("damageShards")
    --animator.playSound("changeDamageState")
  end
end


function calcGroundCollisionAngle(waterSurface)
  local frontDistance = math.min(distanceToGround(self.frontGroundTestPoint), waterSurface)
  local backDistance = math.min(distanceToGround(self.backGroundTestPoint), waterSurface)

  if frontDistance == self.maxGroundSearchDistance and backDistance == self.maxGroundSearchDistance then
    return 0
  else
    return -math.atan(backDistance - frontDistance)
  end
end

function distanceToGround(point)
  -- to worldspace
  point = vec2.rotate(point, self.angle)
  point = vec2.add(point, mcontroller.position())

  local endPoint = vec2.add(point, {0, -self.maxGroundSearchDistance})
  local intPoint = world.lineCollision(point, endPoint)

  if intPoint then
    -- world.debugPoint(intPoint, {255, 255, 0, 255})
    return point[2] - intPoint[2]
  else
    -- world.debugPoint(endPoint, {255, 0, 0, 255})
    return self.maxGroundSearchDistance
  end
end
