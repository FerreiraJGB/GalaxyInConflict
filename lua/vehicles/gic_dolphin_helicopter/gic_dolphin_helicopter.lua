require("/scripts/vec2.lua")
require "/scripts/util.lua"

function init()
  vehicle.setPersistent(true)
  --self.levelApproachFactor = config.getParameter("levelApproachFactor")
  self.angleApproachFactor = config.getParameter("angleApproachFactor")
  --self.maxGroundSearchDistance = config.getParameter("maxGroundSearchDistance")
  self.maxAngle = config.getParameter("maxAngle") * math.pi / 180
  --self.hoverTargetDistance = config.getParameter("hoverTargetDistance")
  --self.hoverVelocityFactor = config.getParameter("hoverVelocityFactor")
  --self.hoverControlForce = config.getParameter("hoverControlForce")
  --self.targetHorizontalVelocity = config.getParameter("targetHorizontalVelocity")
  self.horizontalControlForce = config.getParameter("horizontalControlForce")
  self.nearGroundDistance = config.getParameter("nearGroundDistance")
  self.jumpVelocity = config.getParameter("jumpVelocity")
  self.jumpTimeout = config.getParameter("jumpTimeout")
  --self.backSpringPositions = config.getParameter("backSpringPositions")
  --self.frontSpringPositions = config.getParameter("frontSpringPositions")
  --self.bodySpringPositions = config.getParameter("bodySpringPositions")
  
  self.movementSettings = config.getParameter("movementSettings")
  self.movementSettingsFlip = config.getParameter("movementSettingsFlip")
  self.occupiedMovementSettings = config.getParameter("occupiedMovementSettings")
  self.occupiedMovementSettingsFlip = config.getParameter("occupiedMovementSettingsFlip")
  
  self.protection = config.getParameter("protection")
  self.maxHealth = config.getParameter("maxHealth")

  self.smokeThreshold =  config.getParameter("smokeParticleHealthThreshold")
  self.fireThreshold =  config.getParameter("fireParticleHealthThreshold")
  self.maxSmokeRate = config.getParameter("smokeRateAtZeroHealth")
  self.maxFireRate = config.getParameter("fireRateAtZeroHealth")

  self.onFireThreshold =  config.getParameter("onFireHealthThreshold")
  self.damagePerSecondWhenOnFire =  config.getParameter("damagePerSecondWhenOnFire")

  self.engineDamageSoundThreshold =  config.getParameter("engineDamageSoundThreshold")
  self.intermittentDamageSoundThreshold = config.getParameter("intermittentDamageSoundThreshold")

  --this is a range
  self.maxDamageSoundInterval = config.getParameter("maxDamageSoundInterval")
  self.minDamageSoundInterval = config.getParameter("minDamageSoundInterval")


  self.minDamageCollisionAccel = config.getParameter("minDamageCollisionAccel")
  self.minNotificationCollisionAccel = config.getParameter("minNotificationCollisionAccel")
  self.terrainCollisionDamage = config.getParameter("terrainCollisionDamage")
  self.materialKind = config.getParameter("materialKind")
  self.terrainCollisionDamageSourceKind = config.getParameter("terrainCollisionDamageSourceKind")
  self.accelerationTrackingCount = config.getParameter("accelerationTrackingCount")

  self.damageStateNames = config.getParameter("damageStateNames")

  --self.engineIdlePitch = config.getParameter("engineIdlePitch")
  --self.engineRevPitch = config.getParameter("engineRevPitch")
  --self.engineIdleVolume = config.getParameter("engineIdleVolume")
  --self.engineRevVolume = config.getParameter("engineRevVolume")


  self.damageStatePassengerDances = config.getParameter("damageStatePassengerDances")
  self.damageStatePassengerEmotes = config.getParameter("damageStatePassengerEmotes")
  self.damageStateDriverEmotes = config.getParameter("damageStateDriverEmotes")

  self.loopPlaying = nil;
  self.enginePitch = self.engineRevPitch;
  self.engineVolume = self.engineIdleVolume;
  
  if not storage.angle then storage.angle = 0 end
  if not storage.facingDirection then storage.facingDirection = 1 end
  
  self.driver = nil;
  self.facingDirection = 1
  self.angle = storage.angle
  self.angularVelocityInterval = 0.08 --in radians
  self.angularVelocityMultiplier = 0.93 --keep in range between (0,1)! greater number is, more "floaty" the feel.
  self.jumpTimer = 0
  self.engineRevTimer = 0.0
  self.revEngine = false
  self.damageSoundTimer = 0.0

  self.damageEmoteTimer = 0.0

  self.lastPosition = mcontroller.position()
  self.collisionDamageTrackingVelocities = {}
  self.collisionNotificationTrackingVelocities = {}
  self.selfDamageNotifications = {}

  self.worldBottomDeathLevel = 5

  --initial state
  self.headlightCanToggle = true
  self.headlightsOn = false
  self.hornPlaying = false

  animator.setGlobalTag("rearThrusterFrame", 1)
  animator.setGlobalTag("bottomThrusterFrame", 1)

  animator.setAnimationState("rearThruster", "off")
  animator.setAnimationState("bottomThruster", "off")

  animator.setAnimationState("headlights", "off")

  --this comes in from the controller.
  self.ownerKey = config.getParameter("ownerKey")
  vehicle.setPersistent(self.ownerKey)

  --LEFLS STUFF
   self.targetVerticalVelocity = config.getParameter("targetVerticalVelocity")
   self.fireTimer = 0
   self.rocketpodTimer = 0
   targetAngle = 80 * math.pi / 180
   AimLimit = config.getParameter("AimLimit") * math.pi / 180
   shuttleProjectile = config.getParameter("shuttleProjectile")
   shuttleProjectileConfig = config.getParameter("shuttleProjectileConfig")
   shuttleFireCycle = config.getParameter("shuttleFireCycle")

  --assume maxhealth
  if (storage.health) then
    animator.setAnimationState("movement", "idle")
  else
    local startHealthFactor = config.getParameter("startHealthFactor")

    if (startHealthFactor == nil) then
        storage.health = self.maxHealth
    else
       storage.health = math.min(startHealthFactor * self.maxHealth, self.maxHealth)
    end
    animator.setAnimationState("movement", "warpInPart1")
	animator.setAnimationState("rotors", "warpIn")
  end

  --setup the store functionality
  message.setHandler("store",
      function(_, _, ownerKey)
        if (self.ownerKey and self.ownerKey == ownerKey and self.driver == nil and animator.animationState("movement") == "idle") then
          animator.setAnimationState("movement", "warpOutPart1")
          switchHeadLights(1, 1, false)
          animator.playSound("returnvehicle")
          return {storable = true, healthFactor = storage.health / self.maxHealth}
        else
          return {storable = false, healthFactor = storage.health / self.maxHealth}
        end
      end)
	
	
  -- setup boarding follower functionality (largely ripped from the shuttlecraft mod)
  message.setHandler("gic_boardFollower",
      function(_, _, uuid, npcId)
  			if vehicle.entityLoungingIn("drivingSeat") ~= nil then 
				if world.entityUniqueId(vehicle.entityLoungingIn("drivingSeat")) == uuid then  
					self.boardFollower = npcId
				end
			end
	  end)
	  
  self.copilotTargetPos = {0,0} --replaced traditionally by [vehicle.aimPosition("copilotSeat")] but overrided when an AI copilot is in action

  updateVisualEffects(storage.health, 0, false)
  
  self.angularVelocity = 0
  self.defaultThrottle = -0.666
  self.throttleInterval = 0.6
  self.verticalThrottle = self.defaultThrottle
  if not storage.engineActive then storage.engineActive = false end
  self.engineStartHeld = false
  
  local limit = 15.0
  self.maxVerticalThrottle = limit + self.defaultThrottle + 10 -- world.gravity(entity.position()) + limit + self.defaultThrottle
  self.minVerticalThrottle = -limit + self.defaultThrottle - 7 -- -world.gravity(entity.position()) - limit + self.defaultThrottle
  
  self.rocketsLoaded = 9
  self.rocketReloadTimer = 2.0
  
  
  self.missileIds = {} --for proper tracking of missile; left as an array to be easy to copy from vanilla scripts, and as a somewhat safeguard in case multiple rockets exist.
  self.missileTimer = 5.0
  if not storage.missileLoaded then storage.missileLoaded = 1 end
  if storage.missileLoaded == 1 then 
	animator.setGlobalTag("missilestatus","missile")
	animator.setGlobalTag("doorstatus","")
  else 
	animator.setGlobalTag("missilestatus","nomissile")
	animator.setGlobalTag("doorstatus","_nomissile")
  end
  
  if storage.engineLocked then
	storage.engineActive = false
  end
  if storage.engineActive then
	animator.stopAllSounds("rotorSpin")
	animator.playSound("rotorSpin",-1)
	animator.setSoundVolume("rotorSpin", 0.25)
  end
  
  self.doorOpen = false
  self.headlightState = animator.animationState("headlights")
  self.headlightCanToggle = true
  
  if self.headlightState == "on" then
		animator.setLightActive("headlightBeam", true)
		animator.setAnimationState("headlights", "on")
		self.headlightState = animator.animationState("headlights")
	else
		animator.setLightActive("headlightBeam", false)
		animator.setAnimationState("headlights", "off")
		self.headlightState = animator.animationState("headlights")
	end
end

function update()
  vehicle.setPersistent(true)
  if mcontroller.position()[2] < self.worldBottomDeathLevel then
    vehicle.destroy()
    return
  end

  if (animator.animationState("movement") == "invisible") then
    vehicle.destroy()
  elseif (animator.animationState("movement") == "warpInPart1" or animator.animationState("movement") == "warpOutPart2") then
    mcontroller.setPosition(self.lastPosition)
    mcontroller.setVelocity({0, 0})
  else
    local driverThisFrame = vehicle.entityLoungingIn("drivingSeat")

    if (driverThisFrame ~= nil) then
      vehicle.setDamageTeam(world.entityDamageTeam(driverThisFrame))
    elseif vehicle.entityLoungingIn("copilotSeat") then
	  vehicle.setDamageTeam(world.entityDamageTeam(vehicle.entityLoungingIn("copilotSeat")))
	else
      vehicle.setDamageTeam({type = "passive"})
    end

    local healthFactor = storage.health / self.maxHealth
	
	-- ripped (and edited) from shuttlecraft mod's code
	if (driverThisFrame) and self.boardFollower then followerEmbark(self.boardFollower) end 
	
	aiTargeting()
    move()
    controls()
    animate()
    updateDamage()
    updateDriveEffects(healthFactor, driverThisFrame)

    updatePassengers(healthFactor)

    self.driver = driverThisFrame
  end
  
  
  if self.queRepairText == true then
	local configDat = config.getParameter("repairTextConfig")
	
	--sb.logInfo(sb.printJson(configDat.actionOnReap[1].action))
	configDat.actionOnReap[1].specification.text = "^green;+"..math.floor(self.repairedHealth+0.5).."/"..math.floor(self.maxHealth-storage.health+0.5).." HP^reset;"
	world.spawnProjectile("gic_null",mcontroller.position(),entity.id(),{0,0},false,configDat)
	self.queRepairText = false
  end
  
  
  if mcontroller.liquidPercentage() > 0.75 and not storage.engineLocked then
	--sb.logInfo("SINK")
	storage.health = 0
	
	self.verticalThrottle = self.defaultThrottle--world.gravity(entity.position())
	animator.setAnimationState("rotors", "off")
	storage.engineActive = false
	storage.engineLocked = true
	
	animator.stopAllSounds("rotorSpin")
	--animator.playSound("rotorSpin",-1)
	--animator.setSoundVolume("rotorSpin", 0)
	--animator.setSoundVolume("rotorSpin", 0.25, 2.0)
  end
  
   updateDoor()
   
   if not storage.engineActive and mcontroller.onGround() then
	idleRotate()
   end
   
   storage.facingDirection = self.facingDirection
   storage.angle = self.angle
end

-- basically ripped from the shuttlecraft mod, edited and such for this vehicle's purposes though.
function followerEmbark(npcId)
			local driverSeat = "drivingSeat"
			--local copilotSeat = "copilotSeat"
			local boardSeat = nil

			if world.entityType(npcId) == "npc" then
				if vehicle.entityLoungingIn(driverSeat) ~= nil then 
					if vehicle.entityLoungingIn("copilotSeat") == nil and boardSeat == nil then 
						boardSeat = 0
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

function aiTargeting()
	--world.debugLine(vec2.add(animator.partPoint("frontGun", "firePoint"), mcontroller.position()), self.copilotTargetPos, {255,0,0,255})
	
	self.aiFireMachineguns = false
	self.missileTarget = nil
	if vehicle.entityLoungingIn("copilotSeat") == nil or world.entityType(vehicle.entityLoungingIn("copilotSeat")) ~= "npc" then
		self.copilotTargetPos = vehicle.aimPosition("copilotSeat")
		return
	else
		local npcId = vehicle.entityLoungingIn("copilotSeat")
		
		-- ok most of this is my own stuff but the base targeting code is ripped from the shuttlecraft mod
		-- anyways just also wanted to say that this stuff is cool, since *you can pull many functions from the NPC*, many more than I had thought possible!
		-- cool stuff since yeah main thing is that the AI targeting priorities here will be based off the targeting priorities of the NPC itself!
		
		local range = 100 -- this is GiC, crank that range number way up boyo
		local targetList = world.entityQuery(mcontroller.position(), range, {withoutEntityId = npcId,includedTypes = {"npc", "monster", "player"}, order = "nearest"})
		local validTarget = nil
		if targetList[1] ~= nil then -- were we able to find valid targets?
			for i = 1, #targetList do 
				if world.callScriptedEntity(npcId, "entity.isValidTarget", targetList[i]) and world.callScriptedEntity(npcId, "entity.entityInSight", targetList[i]) then 
					--if not checkSeatsForEntity(targetList[i]) then
						validTarget = targetList[i]
						--sb.logInfo(sb.printJson(world.entityHealth(targetList[i])[2]))
						--sb.logInfo(sb.printJson(validTarget))
						break
					--end
				end
			end
			
			
			if validTarget ~= nil then
				self.aiFireMachineguns = true --trigger firing of machine guns
				
				self.copilotTargetPos = world.entityPosition(validTarget)
				--sb.logInfo(sb.printJson(validTarget))
				--world.debugLine(vec2.add(animator.partPoint("frontGun", "firePoint"), mcontroller.position()), world.entityPosition(validTarget), {0,255,0,255})
			end
		end
		
		
		
		local range = 300 -- missile range - VERY FAR
		if storage.missileLoaded == 1 then --prevent excess calculating of possible targets; long range calculations is performance intensive, so limit this!
			local targetList = world.entityQuery(mcontroller.position(), range, {withoutEntityId = npcId,includedTypes = {"monster", "player"}, order = "nearest"})
			if targetList[1] ~= nil then -- were we able to find valid targets?
				for i = 1, #targetList do 
					if world.callScriptedEntity(npcId, "entity.isValidTarget", targetList[i]) and world.callScriptedEntity(npcId, "entity.entityInSight", targetList[i]) then 
						--if not checkSeatsForEntity(targetList[i]) then
							validTarget = targetList[i]
							--sb.logInfo(sb.printJson(world.entityHealth(targetList[i])[2]))
							--sb.logInfo(sb.printJson(validTarget))
							break
						--end
					end
				end
				
				-- this may be slightly inefficient, but i doubt there'll be any instances where there's *too* many enemies
				-- targeting code for firing missiles and etc
				for i = 1, #targetList do
					--sb.logInfo(sb.printJson(world.entityType(targetList[i])))
					if world.entityType(targetList[i]) ~= "npc" then -- don't target NPCs with the seeker missiles, waste of ammo (99% of time)
					
						--local monsterParams = root.monsterParameters(world.entityTypeName(targetList[i]))
						--sb.logInfo(sb.printJson(monsterParams.behaviorConfig))
						--sb.logInfo(sb.printJson(world.entityHealth(targetList[i])))
						if world.callScriptedEntity(npcId, "entity.isValidTarget", targetList[i]) 
						and world.callScriptedEntity(npcId, "entity.entityInSight", targetList[i]) 
						and (world.entityHealth(targetList[i])[2] >= 500) then 
							--if not checkSeatsForEntity(targetList[i]) then
								self.missileTarget = targetList[i]
								
								--world.debugLine(mcontroller.position(), world.entityPosition(self.missileTarget), {255,255,0,255})
								--sb.logInfo("validMissileTarget")
								--sb.logInfo(sb.printJson(validTarget))
								break
							--end
						end
					end
				end
			end
		end
	end

end

function idleRotate()
	self.maxGroundSearchDistance = 10
	local bounds = mcontroller.localBoundBox()
	
	if self.facingDirection == 1 then
		self.frontGroundTestPoint = {bounds[1]+11.0,bounds[2]+4.5} --"back" wheel
		self.frontGroundTestPoint2 = {bounds[1]+11.0,bounds[2]+4.5}
		self.backGroundTestPoint = {bounds[3]-6.0, bounds[2]+4.5} --"front" wheel
		self.backGroundTestPoint2 = {bounds[3]-8.0, bounds[2]+4.5}
	else
		self.frontGroundTestPoint = {bounds[1]+6.0,bounds[2]+4.5} --"front" wheel
		self.frontGroundTestPoint2 = {bounds[1]+8.0,bounds[2]+4.5}
		self.backGroundTestPoint = {bounds[3]-11.0, bounds[2]+4.5} --"back" wheel
		self.backGroundTestPoint2 = {bounds[3]-11.0, bounds[2]+4.5}
	end
	
	local surface = self.maxGroundSearchDistance
    self.surfaceBounds = mcontroller.localBoundBox()

    self.surfaceBounds[2] = surface - 0.5
    self.surfaceBounds[4] = surface - 0.5
	
	local targetAngle = calcGroundCollisionAngle(self.surfaceBounds[2])
	self.angle = self.angle + (targetAngle - self.angle) * self.angleApproachFactor
end

function updateDoor()
	local players = world.playerQuery(vec2.add(mcontroller.position(), animator.partPoint("foreground", "centerPosition")), 20, {
      --boundMode = "CollisionArea"
    })
	
	local pilot = vehicle.entityLoungingIn("drivingSeat")
	local copilot = vehicle.entityLoungingIn("copilotSeat")
	local passenger1 = vehicle.entityLoungingIn("passengerSeat")
	local passenger2 = vehicle.entityLoungingIn("passengerSeat2")
	
	local openDoor = false
	for key, value in pairs(players) do
		--sb.logInfo(sb.printJson(value))
		--sb.logInfo(sb.printJson(pilot))
		--sb.logInfo(sb.printJson(not value == pilot))
		
		if not ((pilot == value) or (value == copilot) or (value == passenger1) or (value == passenger2)) then
			openDoor = true
		end
	end
	
	if openDoor == true and self.doorOpen == false then
		self.doorOpen = true
		animator.setAnimationState("dolphindoor", "opening", false)
	elseif openDoor == false and self.doorOpen == true then
		self.doorOpen = false
		animator.setAnimationState("dolphindoor", "closing", false)
	end
end

--make the driver and passenger dance and emote according to the damage state of the vehicle
function updatePassengers(healthFactor)
  if healthFactor > 0 then
    local maxDamageState = #self.damageStatePassengerDances
    local damageStateIndex = maxDamageState
    damageStateIndex = (maxDamageState - math.ceil(healthFactor * maxDamageState)) + 1

    local dance = self.damageStatePassengerDances[damageStateIndex]
    if (dance ~= "") then
      vehicle.setLoungeDance("passengerSeat",dance)
    end

    --if we have a scared face on because of taking damage
    if self.damageEmoteTimer > 0 then
      self.damageEmoteTimer = self.damageEmoteTimer - script.updateDt()
    else
      maxDamageState = #self.damageStatePassengerEmotes
      damageStateIndex = maxDamageState
      damageStateIndex = (maxDamageState - math.ceil(healthFactor * maxDamageState)) + 1
      vehicle.setLoungeEmote("passengerSeat", self.damageStatePassengerEmotes[damageStateIndex])

      maxDamageState = #self.damageStateDriverEmotes
      damageStateIndex = maxDamageState
      damageStateIndex = (maxDamageState - math.ceil(healthFactor * maxDamageState)) + 1
      vehicle.setLoungeEmote("drivingSeat", self.damageStateDriverEmotes[damageStateIndex])
    end
  end
end

function updateDriveEffects(healthFactor, driverThisFrame)
  --local startSoundName = "engineStart"
  --local loopSoundName = "engineLoop"

  --if (healthFactor < self.engineDamageSoundThreshold) then
   -- startSoundName = "engineStartDamaged"
    --loopSoundName = "engineLoopDamaged"
  --end

  --do we have a driver ?
  --if (driverThisFrame ~= nil) then
    --has someone got in ?
    --if (self.driver == nil) then
      --animator.playSound(startSoundName)
    --end

    --is the sound we want different to the sound we have ?
    --if (loopSoundName ~= self.loopPlaying) then
      --if (self.loopPlaying ~= nil) then
        --animator.playSound("damageIntermittent")
        --animator.stopAllSounds(self.loopPlaying, 0.5)
      --end
      --animator.playSound(loopSoundName, -1)
      --self.loopPlaying = loopSoundName
    --end
  --else
    --no driver, stop the engine
    --if (self.loopPlaying ~= nil) then
      --animator.stopAllSounds(self.loopPlaying, 0.5)
      --self.loopPlaying = nil
    --end
  --end

  --local rearThrusterFrame = 0
  --local ventralThrusterFrame = 0

  -- is the engine sound playing ?
  --if (self.loopPlaying ~= nil) then
    --if (self.engineVolume == self.engineIdleVolume) then
      --animator.setParticleEmitterActive("rearThrusterIdle", true)
      --animator.setParticleEmitterActive("rearThrusterDrive", false)
    --else
      --animator.setParticleEmitterActive("rearThrusterIdle", false)
      --animator.setParticleEmitterActive("rearThrusterDrive", true)
      --rearThrusterFrame = 3
    --end

    -- a brief burst of power
    --if (self.revEngine == true)  then
      -- instantly set them to full power.
      --self.engineRevTimer = 0.5
      --animator.setSoundPitch(self.loopPlaying, self.engineRevPitch, self.engineRevTimer)
      --animator.setSoundVolume(self.loopPlaying, self.engineRevVolume, self.engineRevTimer)

     -- animator.setParticleEmitterActive("ventralThrusterIdle", false)
      --animator.setParticleEmitterActive("ventralThrusterJump", true)
      --animator.burstParticleEmitter("ventralThrusterJump")
      --ventralThrusterFrame = 3

      --self.revEngine = false
    --else
      --if (self.engineRevTimer > 0.0)  then
       -- self.engineRevTimer = self.engineRevTimer - script.updateDt()
        --ventralThrusterFrame = 3
      --else
       --animator.setParticleEmitterActive("ventralThrusterIdle", true)
        --animator.setParticleEmitterActive("ventralThrusterJump", false)

        --settling to the normal engine pitch and volume
        --animator.setSoundPitch(self.loopPlaying, self.enginePitch, 1.5)
        --animator.setSoundVolume(self.loopPlaying, self.engineVolume, 1.5)
      --end
    --end

    --animator.setAnimationState("rearThruster", "on")
    --animator.setAnimationState("bottomThruster", "on")
  --else
    --animator.setParticleEmitterActive("rearThrusterIdle", false)
    --animator.setParticleEmitterActive("rearThrusterDrive", false)
    --animator.setParticleEmitterActive("ventralThrusterIdle", false)
    --animator.setParticleEmitterActive("ventralThrusterJump", false)

    --animator.setAnimationState("rearThruster", "off")
    --animator.setAnimationState("bottomThruster", "off")
  --end

  --if burning, takew dammage intermittantly.
  if (self.loopPlaying ~= nil or (self.onFireThreshold and healthFactor < self.onFireThreshold)) then
    --time to go snap crackle or pop ?
    if (healthFactor < self.intermittentDamageSoundThreshold) then
      self.damageSoundTimer = self.damageSoundTimer - script.updateDt()

      if (self.damageSoundTimer <= 0) then
        animator.playSound("damageIntermittent")

        --a random time that changes depending on how damaged the vehicle is.
        local randomMax = (healthFactor * self.maxDamageSoundInterval) + ((1.0 - healthFactor) * self.minDamageSoundInterval)

        animator.burstParticleEmitter("damageIntermittent")
        self.damageEmoteTimer = config.getParameter("damageEmoteTime")

        if not (mcontroller.zeroG() or mcontroller.liquidPercentage() > 0.75) and storage.engineActive then
			local BackfireMomentum = {0, -self.jumpVelocity * 0.5}
			mcontroller.addMomentum(BackfireMomentum)
		end

        self.damageSoundTimer = math.random() * randomMax;
      end
    end
  end

  --rearThrusterFrame = rearThrusterFrame + math.random(3)
  --animator.setGlobalTag("rearThrusterFrame", rearThrusterFrame)

  --ventralThrusterFrame = ventralThrusterFrame + math.random(3)
  --animator.setGlobalTag("bottomThrusterFrame", ventralThrusterFrame)
end

function updateVisualEffects(currentHealth, damage, headlights)

  local maxDamageState = #self.damageStateNames
  local prevHealthFactor = currentHealth / self.maxHealth

  --work out the factor after damage occurs.
  local newHealthFactor = (currentHealth - damage) / self.maxHealth

  --work out what damage state we are in before damage occurs
  local previousDamageStateIndex = maxDamageState
  if prevHealthFactor > 0 then
    previousDamageStateIndex = (maxDamageState - math.ceil(prevHealthFactor * maxDamageState)) + 1
  end

  --now the damage state after damage occurs
  local damageStateIndex = maxDamageState
  if newHealthFactor > 0 then
    damageStateIndex = (maxDamageState - math.ceil(newHealthFactor * maxDamageState)) + 1
  end

  --if we've changed damage state make some danaged effects.
  if (damageStateIndex > previousDamageStateIndex) then
    animator.burstParticleEmitter("damageShards")
    animator.playSound("changeDamageState")
  end

  --switchHeadLights(previousDamageStateIndex, damageStateIndex, headlights)

  animator.setGlobalTag("damageState", self.damageStateNames[damageStateIndex])

  --smoke particles and fire
  if newHealthFactor < 0.5 then
    if (self.smokeThreshold > 0 and newHealthFactor < self.smokeThreshold) then
      local smokeFactor = 1.0 - (newHealthFactor / self.smokeThreshold)
      animator.setParticleEmitterActive("smoke", true)
      animator.setParticleEmitterEmissionRate("smoke", smokeFactor * self.maxSmokeRate)
    end

    if (self.fireThreshold > 0 and newHealthFactor < self.fireThreshold) then
      local fireFactor = 1.0 - (newHealthFactor / self.fireThreshold)
      animator.setParticleEmitterActive("fire", true)
      animator.setParticleEmitterEmissionRate("fire", fireFactor * self.maxFireRate)
    end

    if (self.onFireThreshold and newHealthFactor < self.onFireThreshold) then
      animator.setAnimationState("onfire", "on")
    else
      animator.setAnimationState("onfire", "off")
    end
  else
    animator.setParticleEmitterActive("smoke", false)
    animator.setParticleEmitterActive("fire", false)
    animator.setAnimationState("onfire", "off")
  end
end

-- function switchHeadLights(oldIndex, newIndex, activate)
  -- if (activate ~= self.headlightsOn or oldIndex ~= newIndex) then
    -- local listOfLists = config.getParameter("lightsInDamageState")

    -- if (listOfLists ~= nil) then
      -- if (oldIndex ~= newIndex) then
        -- local listToSwitchOff = listOfLists[oldIndex]
        -- for i, name in ipairs(listToSwitchOff) do
          -- animator.setLightActive(name, false)
        -- end
      -- end

        -- local listToSwitchOn = listOfLists[newIndex]
        -- for i, name in ipairs(listToSwitchOn) do
        -- animator.setLightActive(name, activate)
      -- end
    -- end
    -- self.headlightsOn = activate

    -- if (self.headlightsOn) then
      -- animator.setAnimationState("headlights", "on")
    -- else
      -- animator.setAnimationState("headlights", "off")
    -- end
  -- end
-- end

function setDamageEmotes()
  local damageTakenEmote = config.getParameter("damageTakenEmote")
  self.damageEmoteTimer = config.getParameter("damageEmoteTime")
  vehicle.setLoungeEmote("drivingSeat", damageTakenEmote)
  vehicle.setLoungeEmote("passengerSeat", damageTakenEmote)
end

function applyDamage(damageRequest)
  local damage = 0
  
  local resistancesParam = config.getParameter("resistances")
  
  if damageRequest.damageSourceKind == "ews_melee" or damageRequest.damageType == "IgnoresDef" then
	if resistancesParam[damageRequest.damageSourceKind] then
		damage = damage + damageRequest.damage * (1 - resistancesParam[damageRequest.damageSourceKind])
	else
		damage = damage + damageRequest.damage
	end
  else
	
	if resistancesParam[damageRequest.damageSourceKind] then
		damage = damage + root.evalFunction2("protection", damageRequest.damage, config.getParameter("protection")) * (1 - resistancesParam[damageRequest.damageSourceKind])
	else
		damage = damage + root.evalFunction2("protection", damageRequest.damage, config.getParameter("protection"))
	end
  end
  if damageRequest.statusEffects and damageRequest.statusEffects[1] and damageRequest.statusEffects[1].effect == "gic_wrench" and storage.health > 0 then
	damage = 0
	if storage.health < self.maxHealth then
		local healthGained = math.min(100, self.maxHealth - storage.health)
		storage.health = storage.health + healthGained
	
		self.repairedHealth = healthGained
		self.queRepairText = true
	end
  end

	setDamageEmotes()
	updateVisualEffects(storage.health, damage, self.headlightsOn)


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

function selfDamageNotifications()
  local sdn = self.selfDamageNotifications
  self.selfDamageNotifications = {}
  return sdn
end

function move()
  --local groundDistance = minimumSpringDistance(self.bodySpringPositions)
  --local nearGround = groundDistance < self.nearGroundDistance

  --assume idle pitch
  self.enginePitch = self.engineIdlePitch;
  self.engineVolume = self.engineIdleVolume;
  
  
  if self.driver then
	--animator.setAnimationState("rotors", "on")
	--if self.facingDirection == 1 then
		--mcontroller.applyParameters(self.occupiedMovementSettings)
	--else
		--mcontroller.applyParameters(self.occupiedMovementSettingsFlip)
	--end
    --if groundDistance <= self.hoverTargetDistance then
      --mcontroller.approachYVelocity((self.hoverTargetDistance - groundDistance) * self.hoverVelocityFactor, self.hoverControlForce)
    --end
	if storage.engineActive then
		if world.distance(vehicle.aimPosition("drivingSeat"), mcontroller.position())[1] > 0 and storage.health > 0 then
			self.facingDirection = 1
		else
			self.facingDirection = -1
		end
	end
	
	
	if vehicle.controlHeld("drivingSeat","altFire") and not self.engineStartHeld and storage.health > 0 then
		storage.engineActive = (not storage.engineActive)
		
		if storage.engineActive then
			animator.stopAllSounds("rotorSpin")
			animator.playSound("rotorSpin",-1)
			animator.setSoundVolume("rotorSpin", 0)
			animator.setSoundVolume("rotorSpin", 0.25, 2.0)
		else
			animator.stopAllSounds("rotorSpin")
			animator.playSound("rotorSpin",-1)
			animator.setSoundVolume("rotorSpin", 1.5)
			animator.setSoundVolume("rotorSpin", 0, 2.0)
		end
	end
	self.engineStartHeld = vehicle.controlHeld("drivingSeat","altFire")
	
	if self.rocketsLoaded < 9 then
		if not vehicle.controlHeld("drivingSeat","primaryFire") then self.rocketReloadTimer = self.rocketReloadTimer - script.updateDt() end
		
		if self.rocketReloadTimer <= 0 then
			self.rocketsLoaded = self.rocketsLoaded + 1
			self.rocketReloadTimer = 0.75 --2.0
			animator.setSoundVolume("rocketpodReload",2)
			animator.playSound("rocketpodReload")
		end
	end
  else
	--self.verticalThrottle = -0.67--world.gravity(entity.position())
	--animator.setAnimationState("rotors", "off")
  end
  
  local ignorePlatformCollision = false
  if storage.engineActive then
	animator.setAnimationState("rotors", "on")
	local throttle = self.verticalThrottle+world.gravity(entity.position())
	local pi2 = math.pi/2
	if storage.health >= 0 and not mcontroller.zeroG() and not (mcontroller.liquidPercentage() > 0.75) then
		mcontroller.accelerate({math.cos(self.angle+pi2)*throttle*0.8,math.sin(self.angle+pi2)*throttle})
	end
	ignorePlatformCollision = true
  else
	self.verticalThrottle = self.defaultThrottle--world.gravity(entity.position())
	animator.setAnimationState("rotors", "off")
  end
  
  
  
  if self.facingDirection == 1 then
	mcontroller.resetParameters()
	
	local moveConfig = self.movementSettings
	moveConfig.ignorePlatformCollision = ignorePlatformCollision
	mcontroller.applyParameters(moveConfig)
  else
	mcontroller.resetParameters()
	
	local moveConfig = self.movementSettingsFlip
	moveConfig.ignorePlatformCollision = ignorePlatformCollision
	mcontroller.applyParameters(moveConfig)
  end

  
  
  if vehicle.controlHeld("drivingSeat", "left") and storage.engineActive and not mcontroller.zeroG() then
    --mcontroller.approachXVelocity(-self.targetHorizontalVelocity, self.horizontalControlForce)
	
	--self.angle = self.angle + (targetAngle - self.angle) * self.angleApproachFactor
	self.angularVelocity = self.angularVelocity + self.angularVelocityInterval
    self.enginePitch = self.engineRevPitch;
    self.engineVolume = self.engineRevVolume;
    --leftispressed = true
    --self.facingDirection = -1
	--mcontroller.applyParameters(self.occupiedMovementSettingsFlip)

  elseif vehicle.controlHeld("drivingSeat", "right") and storage.engineActive and not mcontroller.zeroG() then
    --mcontroller.approachXVelocity(self.targetHorizontalVelocity, self.horizontalControlForce)
	
	--self.angle = self.angle + (-targetAngle - self.angle) * self.angleApproachFactor
	self.angularVelocity = self.angularVelocity - self.angularVelocityInterval
    self.enginePitch = self.engineRevPitch;
    self.engineVolume = self.engineRevVolume;
    --rightispressed = true
    --self.facingDirection = 1
	--mcontroller.applyParameters(self.occupiedMovementSettings)
  else
    --rightispressed = false
    --leftispressed = false
  end
  
  if storage.health <= 0 then
	local val = 2
	if (mcontroller.liquidPercentage() > 0.75) then val = 1 end
	
	self.angle = self.angle + (-self.facingDirection * targetAngle * val - self.angle) * self.angleApproachFactor
  end
  self.angularVelocity = self.angularVelocity * self.angularVelocityMultiplier
  self.angle = self.angle + (self.angularVelocity * math.pi / 180)
  
  local degToRad = math.pi / 180
  --if self.angle > 90 * degToRad then
	--self.angle = self.angle - math.pi
	--sb.logInfo("GREATER THAN 90 DEGREES")
  --end
  --if self.angle < -90 * degToRad then
	--self.angle = self.angle + math.pi
	--sb.logInfo("LESS THAN -90 DEGREES")
  --end
  
  if self.angle > math.pi * 2 then
	self.angle = self.angle - 2 * math.pi
	--sb.logInfo("GREATER THAN 360 DEGREES")
  end
  
  if self.angle < -math.pi * 2 then
	self.angle = self.angle + 2 * math.pi
	--sb.logInfo("GREATER THAN -360 DEGREES")
  end
  
  --self.angle = self.angle + (0 - self.angle) * self.angleApproachFactor
  
	--if self.driver then
	--mcontroller.approachYVelocity(self.verticalThrottle-world.gravity(entity.position())/2, self.horizontalControlForce)
	--mcontroller.force({0,self.verticalThrottle})
	--mcontroller.accelerate({0,self.verticalThrottle+world.gravity(entity.position())*0.75})
	--end
  
  local throttle_ = self.verticalThrottle--self.maxVerticalThrottle - self.defaultThrottle --self.maxVerticalThrottle + world.gravity(entity.position())
  local pi2_ = math.pi/2
  
  if storage.engineActive then
  if vehicle.controlHeld("drivingSeat", "up") then
	  self.verticalThrottle = math.min(self.verticalThrottle + self.throttleInterval, self.maxVerticalThrottle)
	  
	  if (self.verticalThrottle < self.defaultThrottle) then
		--self.verticalThrottle = math.min(self.verticalThrottle + self.throttleInterval, self.maxVerticalThrottle)
		--mcontroller.accelerate({math.cos(self.angle+pi2_)*throttle_,math.sin(self.angle+pi2_)*throttle_})
		mcontroller.approachVelocity({0,0},80)
	  end
	  --self.enginePitch = self.engineRevPitch;
	  --self.engineVolume = self.engineRevVolume;
    
  elseif vehicle.controlHeld("drivingSeat", "down") then
		self.verticalThrottle = math.max(self.verticalThrottle - self.throttleInterval, self.minVerticalThrottle)
		
		if (self.verticalThrottle > self.defaultThrottle) then
			--self.verticalThrottle = math.max(self.verticalThrottle - self.throttleInterval, self.minVerticalThrottle)
			--mcontroller.accelerate({math.cos(self.angle+pi2_)*-throttle_,math.sin(self.angle+pi2_)*-throttle_})
			mcontroller.approachVelocity({0,0},80)
		end
		--self.enginePitch = self.engineRevPitch;
		--self.engineVolume = self.engineRevVolume;
  else
    --self.angle = self.angle + (0 - self.angle) * self.angleApproachFactor
  end
  end
  --animator.setSoundPitch("rotorSpin", 1.0 + self.verticalThrottle / 3)


  if vehicle.controlHeld("drivingSeat", "jump") and storage.engineActive then
   self.verticalThrottle = self.defaultThrottle
   --mcontroller.approachXVelocity(0, self.horizontalControlForce)
   self.angularVelocity = 0
   mcontroller.approachYVelocity(0, 20)
   self.angle = self.angle + (0 - self.angle) * 0.02
   
  end

  mcontroller.setRotation(self.angle)
end

function controls()
  -- GUN STUFF
 --if self.fireTimer >= 0 then self.fireTimer = self.fireTimer - script.updateDt()end
 
 if (vehicle.controlHeld("copilotSeat","PrimaryFire")) or self.aiFireMachineguns then
   if self.fireTimer <= 0 then
    world.spawnProjectile(shuttleProjectile, vec2.add(mcontroller.position(), animator.partPoint("frontGun", "firePoint")), entity.id(), aimVector(aimAngle,0.02), false, shuttleProjectileConfig)
    self.fireTimer = self.fireTimer + shuttleFireCycle
    animator.setAnimationState("frontFiring", "fire")
   else
    local oldFireTimer = self.fireTimer
    self.fireTimer = self.fireTimer - script.updateDt()
    if oldFireTimer > shuttleFireCycle / 2 and self.fireTimer <= shuttleFireCycle / 2 then
      world.spawnProjectile(shuttleProjectile, vec2.add(mcontroller.position(), animator.partPoint("backGun", "firePoint")), entity.id(), aimVector(aimAngle,0.02), false, shuttleProjectileConfig)
      animator.setAnimationState("backFiring", "fire")
    end
   end
 end
 
 -- Seeker missile controls; pilot can use the seeker with [F], co-pilot can also use the seeker with [M2]. co-pilot takes priority over the pilot in case of controls.
 if vehicle.entityLoungingIn("copilotSeat") then
	
	-- shamelessly stolen from vanilla (guidedrocket ability), not that it even matters.
	self.missileIds = util.filter(self.missileIds, world.entityExists) -- filter out dead missiles
	local rocketTargetPosition = self.copilotTargetPos
	
	for _,missileId in pairs(self.missileIds) do
		world.callScriptedEntity(missileId, "setTarget", rocketTargetPosition)
	end
	-- end custom guided missile stuff
 
	-- standard "seek and destroy" capabilities
	if (vehicle.controlHeld("copilotSeat","Special1") or self.missileTarget ~= nil) and storage.missileLoaded == 1 then
		storage.missileLoaded = 2
		self.missileTimer = 5
		local facingMulti = 0
		if self.facingDirection == -1 then facingMulti = 1 end
		
		local params = {}
		
		if self.missileTarget ~= nil then
			params.initialTarget = findNearbyTarget(self.copilotTargetPos,30)
			params.initialTarget = findNearbyTarget(world.entityPosition(self.missileTarget),30)
		end
		
		world.spawnProjectile("gic_airtoair_missile_sika", vec2.add(mcontroller.position(), animator.partPoint("rocketPodPosition", "missileFirePoint")), entity.id(), {math.cos(self.angle+math.pi*facingMulti), math.sin(self.angle+math.pi*facingMulti)}, false, params)
		animator.playSound("rocketpodFire")
		animator.playSound("missileReload")
		
		animator.setGlobalTag("missilestatus","nomissile")
		animator.setGlobalTag("doorstatus","_nomissile")
		
	-- alternatively, right click to fire a missile that homes in on the copilot's cursor position! mfw TOW missile
	elseif (vehicle.controlHeld("copilotSeat","AltFire")) and storage.missileLoaded == 1 then
		
		storage.missileLoaded = 2
		self.missileTimer = 5
		local facingMulti = 0
		if self.facingDirection == -1 then facingMulti = 1 end
		
		local params = {}
		params.initialTarget = findNearbyTarget(self.copilotTargetPos,30)
		
		local spawnedMissile = world.spawnProjectile("gic_airtoair_guided_missile_sika", vec2.add(mcontroller.position(), animator.partPoint("rocketPodPosition", "missileFirePoint")), entity.id(), {math.cos(self.angle+math.pi*facingMulti), math.sin(self.angle+math.pi*facingMulti)}, false, params)
		
		table.insert(self.missileIds,spawnedMissile)
		--sb.logInfo(sb.printJson(spawnedMissile))
		
		animator.playSound("rocketpodFire")
		animator.playSound("missileReload")
		
		animator.setGlobalTag("missilestatus","nomissile")
		animator.setGlobalTag("doorstatus","_nomissile")
	
	end
	 
	if self.missileTimer > 0 then self.missileTimer = self.missileTimer - script.updateDt() end
	if self.missileTimer <= 0 and storage.missileLoaded == 2 then 
		animator.playSound("missileLoaded")
		storage.missileLoaded = 1
		animator.setGlobalTag("missilestatus","missile")
		animator.setGlobalTag("doorstatus","")
	end
	
 elseif vehicle.entityLoungingIn("drivingSeat") then
 
	if (vehicle.controlHeld("drivingSeat","Special1")) and storage.missileLoaded == 1 then -- press F to fire tracking missile; need to test later.
		storage.missileLoaded = 2
		self.missileTimer = 5
		local facingMulti = 0
		if self.facingDirection == -1 then facingMulti = 1 end
		
		local params = {}
		--params.initialTarget = findNearbyTarget(vehicle.aimPosition("copilotSeat"),30)
		params.initialTarget = findNearbyTarget(vehicle.aimPosition("drivingSeat"),30)
		
		world.spawnProjectile("gic_airtoair_missile_sika", vec2.add(mcontroller.position(), animator.partPoint("rocketPodPosition", "missileFirePoint")), entity.id(), {math.cos(self.angle+math.pi*facingMulti), math.sin(self.angle+math.pi*facingMulti)}, false, params)
		animator.playSound("rocketpodFire")
		animator.playSound("missileReload")
		
		animator.setGlobalTag("missilestatus","nomissile")
		animator.setGlobalTag("doorstatus","_nomissile")
	end
	 
	--if self.missileTimer > 0 and vehicle.entityLoungingIn("copilotSeat") then self.missileTimer = self.missileTimer - script.updateDt() end
	if self.missileTimer > 0 then self.missileTimer = self.missileTimer - script.updateDt() end
	if self.missileTimer <= 0 and storage.missileLoaded == 2 then 
		animator.playSound("missileLoaded")
		storage.missileLoaded = 1
		animator.setGlobalTag("missilestatus","missile")
		animator.setGlobalTag("doorstatus","")
	end
	
 end
 
 
 
  local diff = world.distance(vehicle.aimPosition("drivingSeat"), vec2.add(mcontroller.position(),{-1*self.facingDirection , -4}))
  local podAngle = math.atan(diff[2], diff[1])
  local podLimit = 10 * math.pi / 180
  if self.facingDirection < 0 then

   if podAngle > 0 then
     podAngle = math.max(podAngle, math.pi - podLimit + self.angle)
   else
     podAngle = math.min(podAngle, -math.pi + podLimit + self.angle)
   end
  else
   if podAngle - self.angle > 0 then
     podAngle = math.min(podAngle, podLimit + self.angle)
   else
     podAngle = math.max(podAngle, -podLimit + self.angle)
   end
  end
 
 if (vehicle.controlHeld("drivingSeat","primaryFire") and self.rocketsLoaded > 0) then
	local facingMulti = 0
	if self.facingDirection == -1 then facingMulti = 1 end
	
	if self.rocketpodTimer <= 0 then
		world.spawnProjectile(config.getParameter("rocketpodProjectile"), vec2.add(mcontroller.position(), animator.partPoint("rocketPodPosition", "firePoint")), entity.id(), {math.cos(self.angle+math.pi*facingMulti), math.sin(self.angle+math.pi*facingMulti)}, false, config.getParameter("rocketpodProjectileConfig"))
		self.rocketsLoaded = self.rocketsLoaded - 1
		--world.spawnProjectile(config.getParameter("rocketpodProjectile"), vec2.add(mcontroller.position(), animator.partPoint("rocketPodPosition", "firePoint")), entity.id(), aimVector(podAngle,0.01), false, config.getParameter("rocketpodProjectileConfig"))
		self.rocketpodTimer = config.getParameter("rocketpodCycle")
		animator.playSound("rocketpodFire")
	end
 end
 
 if self.rocketpodTimer > 0 and vehicle.entityLoungingIn("drivingSeat") then self.rocketpodTimer = self.rocketpodTimer - script.updateDt()end
end

function findNearbyTarget(pos,trackingDistance)
  local queryParameters = {
    withoutEntityId = entity.id(),
    includedTypes = {"creature"},
    order = "nearest"
  }

  local candidates = world.entityQuery(pos, trackingDistance, queryParameters)
  for _, candidate in ipairs(candidates) do
    if world.entityCanDamage(entity.id(), candidate) then
      local canPos = world.entityPosition(candidate)
      if not world.lineTileCollision(pos, canPos) then
        return candidate
      end
    end
  end
end

function aimVector(aimAngle,inaccuracy)
  local aimVector = vec2.rotate({1, 0}, (aimAngle + sb.nrand(inaccuracy, 0)))
  --aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end
  -- GUN STUFF ENDING

function animate()
  animator.resetTransformationGroup("flip")
  if self.facingDirection < 0 then
    animator.scaleTransformationGroup("flip", {-1, 1})
  end

  animator.resetTransformationGroup("rotation")
  animator.rotateTransformationGroup("rotation", self.angle)

  -- GUN ANIMATION STUFF
  
  local diff = world.distance(self.copilotTargetPos, vec2.add(mcontroller.position(),{(-4.75+10.625)*self.facingDirection , -4.85}))
  --diff[2] = diff[2] - 0.000366211 + 2.33
  --diff[1] = diff[1] - 4.875
  aimAngle = math.atan(diff[2], diff[1])
  if self.facingDirection < 0 then

   if aimAngle > 0 then
     aimAngle = math.max(aimAngle, math.pi - AimLimit + self.angle)
   else
     aimAngle = math.min(aimAngle, -math.pi + AimLimit + self.angle)
   end
   
   if vehicle.entityLoungingIn("copilotSeat") then
	animator.rotateGroup("guns", math.pi - aimAngle + self.angle)
   end
  else
   if aimAngle - self.angle > 0 then
     aimAngle = math.min(aimAngle, AimLimit + self.angle)
   else
     aimAngle = math.max(aimAngle, -AimLimit + self.angle)
   end
   if vehicle.entityLoungingIn("copilotSeat") then
	animator.rotateGroup("guns", aimAngle - self.angle)
   end
  end
  -- GUN ANIMATION STUFF ENDING
  
  -- LIGHTS
  local copilot = vehicle.entityLoungingIn("copilotSeat")
  if copilot and world.entityType(copilot) == "npc" then
	local daytime = world.timeOfDay()
	self.headlightState = animator.animationState("headlights")
	
	if daytime >= 0.5 and self.headlightState ~= "on" then --AI will turn lights on automatically when night is setting
		animator.playSound("headlightSwitchOff")
		animator.setLightActive("headlightBeam", true)
		animator.setAnimationState("headlights", "on")
	elseif daytime < 0.5 and self.headlightState ~= "off" then
		animator.playSound("headlightSwitchOff")
		animator.setLightActive("headlightBeam", false)
		animator.setAnimationState("headlights", "off")
	end
	
  elseif vehicle.controlHeld("copilotSeat", "up") then
      if self.headlightCanToggle then
	  
		self.headlightState = animator.animationState("headlights")
		if self.headlightState == "on" then
			animator.playSound("headlightSwitchOff")
			animator.setLightActive("headlightBeam", false)
			animator.setAnimationState("headlights", "off")
		else
			animator.playSound("headlightSwitchOn")
			animator.setLightActive("headlightBeam", true)
			animator.setAnimationState("headlights", "on")
			
		end
		self.headlightState = animator.animationState("headlights")
		
        self.headlightCanToggle = false
        end
      else
      self.headlightCanToggle = true
   end
end

function updateDamage()
  if animator.animationState("onfire") == "on" then
    setDamageEmotes()

    local damageThisFrame = self.damagePerSecondWhenOnFire * script.updateDt()
    updateVisualEffects(storage.health, damageThisFrame, self.headlightsOn)
    storage.health = storage.health - damageThisFrame
  end

  if (storage.health <= 0 or self.angle > 120 * math.pi/180 or self.angle < -120 * math.pi/180) and mcontroller.onGround() then
    animator.burstParticleEmitter("damageShards")
    animator.burstParticleEmitter("wreckage")
    animator.playSound("explode")

	world.spawnProjectile(config.getParameter("deathProjectileType"), mcontroller.position(), entity.id(), {0,0}, false, config.getParameter("deathProjectileParameters"))
    vehicle.destroy()
  end

  local newPosition = mcontroller.position()
  local newVelocity = vec2.div(vec2.sub(newPosition, self.lastPosition), script.updateDt())
  self.lastPosition = newPosition

  if mcontroller.isColliding() then
    function findMaxAccel(trackedVelocities)
      local maxAccel = 0
      for _, v in ipairs(trackedVelocities) do
        local accel = vec2.mag(vec2.sub(newVelocity, v))
        if accel > maxAccel then
          maxAccel = accel
        end
      end
      return maxAccel
    end

    if findMaxAccel(self.collisionDamageTrackingVelocities) >= self.minDamageCollisionAccel then
      animator.playSound("collisionDamage")
      setDamageEmotes()

      updateVisualEffects(storage.health, self.terrainCollisionDamage, self.headlightsOn)

	  local diff = (findMaxAccel(self.collisionDamageTrackingVelocities) - self.minDamageCollisionAccel)/(self.minDamageCollisionAccel)
	  storage.health = storage.health - self.terrainCollisionDamage * diff
	  
      self.collisionDamageTrackingVelocities = {}
      self.collisionNotificationTrackingVelocities = {}

      table.insert(self.selfDamageNotifications, {
        sourceEntityId = entity.id(),
        targetEntityId = entity.id(),
        position = mcontroller.position(),
        damageDealt = self.terrainCollisionDamage * diff,
        healthLost = self.terrainCollisionDamage * diff,
        hitType = "Hit",
        damageSourceKind = self.terrainCollisionDamageSourceKind,
        targetMaterialKind = self.materialKind,
        killed = storage.health <= 0
      })
    end

    if findMaxAccel(self.collisionNotificationTrackingVelocities) >= self.minNotificationCollisionAccel then
      animator.playSound("collisionNotification")
      self.collisionNotificationTrackingVelocities = {}
    end
  end

  function appendTrackingVelocity(trackedVelocities, newVelocity)
    table.insert(trackedVelocities, newVelocity)
    while #trackedVelocities > self.accelerationTrackingCount do
      table.remove(trackedVelocities, 1)
    end
  end

  appendTrackingVelocity(self.collisionDamageTrackingVelocities, newVelocity)
  appendTrackingVelocity(self.collisionNotificationTrackingVelocities, newVelocity)
end

function minimumSpringDistance(points)
  local min = nil
  for _, point in ipairs(points) do
    point = vec2.rotate(point, self.angle)
    point = vec2.add(point, mcontroller.position())
    local d = distanceToGround(point)
    if min == nil or d < min then
      min = d
    end
  end
  return min
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
