require("/scripts/vec2.lua")
require "/scripts/util.lua"

function init()
  self.levelApproachFactor = config.getParameter("levelApproachFactor")
  self.angleApproachFactor = config.getParameter("angleApproachFactor")
  self.maxGroundSearchDistance = config.getParameter("maxGroundSearchDistance")
  self.maxAngle = config.getParameter("maxAngle") * math.pi / 180
  self.hoverTargetDistance = config.getParameter("hoverTargetDistance")
  self.hoverVelocityFactor = config.getParameter("hoverVelocityFactor")
  self.hoverControlForce = config.getParameter("hoverControlForce")
  self.targetHorizontalVelocity = config.getParameter("targetHorizontalVelocity")
  self.horizontalControlForce = config.getParameter("horizontalControlForce")
  self.zeroGTargetVelocity = config.getParameter("zeroGTargetVelocity")
  self.zeroGSpinRate = config.getParameter("zeroGSpinRate")
  self.spinFriction = config.getParameter("spinFriction")
  self.nearGroundDistance = config.getParameter("nearGroundDistance")
  self.jumpVelocity = config.getParameter("jumpVelocity")
  self.jumpTimeout = config.getParameter("jumpTimeout")
  self.backSpringPositions = config.getParameter("backSpringPositions")
  self.frontSpringPositions = config.getParameter("frontSpringPositions")
  self.bodySpringPositions = config.getParameter("bodySpringPositions")
  self.movementSettings = config.getParameter("movementSettings")
  self.occupiedMovementSettings = config.getParameter("occupiedMovementSettings")
  self.zeroGMovementSettings = config.getParameter("zeroGMovementSettings")
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

  self.engineIdlePitch = config.getParameter("engineIdlePitch")
  self.engineRevPitch = config.getParameter("engineRevPitch")
  self.engineIdleVolume = config.getParameter("engineIdleVolume")
  self.engineRevVolume = config.getParameter("engineRevVolume")


  self.damageStatePassengerDances = config.getParameter("damageStatePassengerDances")
  self.damageStatePassengerEmotes = config.getParameter("damageStatePassengerEmotes")
  self.damageStateDriverEmotes = config.getParameter("damageStateDriverEmotes")

  self.loopPlaying = nil;
  self.enginePitch = self.engineRevPitch;
  self.engineVolume = self.engineIdleVolume;

  self.driver = nil;
  self.facingDirection = 1
  self.angle = 0
  self.jumpTimer = 0
  self.engineRevTimer = 0.0
  self.revEngine = false
  self.damageSoundTimer = 0.0
  self.spin = 0
  
  animator.rotateGroup("guns", 0, true)
  self.fireTimer = 0

  self.damageEmoteTimer = 0.0

  self.lastPosition = mcontroller.position()
  self.collisionDamageTrackingVelocities = {}
  self.collisionNotificationTrackingVelocities = {}
  self.selfDamageNotifications = {}

  --initial state
  self.headlightCanToggle = true
  self.headlightsOn = false
  self.hornPlaying = false

  animator.setGlobalTag("rearThrusterFrame", 1)
  animator.setGlobalTag("bottomThrusterFrame", 1)

  animator.setAnimationState("rearThruster", "off")
  animator.setAnimationState("bottomThruster", "off")

  animator.setAnimationState("headlights", "off")
  animator.setAnimationState("fullbright", "off")

  --this comes in from the controller.
  self.ownerKey = config.getParameter("ownerKey")
  vehicle.setPersistent(self.ownerKey)

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
  message.setHandler("gic_boardGunnerFollower",
      function(_, _, uuid, npcId)
  			if vehicle.entityLoungingIn("drivingSeat") ~= nil then 
				if world.entityUniqueId(vehicle.entityLoungingIn("drivingSeat")) == uuid then
					self.boardGunnerFollower = npcId
				end
			end
	  end)
  self.gunnerAimPos = vehicle.aimPosition("passengerSeat");

  updateVisualEffects(storage.health, 0, false)
end

function update()
  if mcontroller.atWorldLimit() then
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
    elseif vehicle.entityLoungingIn("passengerSeat") ~= nil then
		vehicle.setDamageTeam(world.entityDamageTeam(vehicle.entityLoungingIn("passengerSeat")))
	else
      vehicle.setDamageTeam({type = "passive"})
    end
	
	if (driverThisFrame ~= nil) and self.boardGunnerFollower then gunnerFollowerEmbark(self.boardGunnerFollower) end 

    local healthFactor = storage.health / self.maxHealth

    if mcontroller.zeroG() then
      moveZeroG()
    else
      move()
    end
	aiTargeting()
    controls()
    animate()
    updateDamage()
    updateDriveEffects(healthFactor, driverThisFrame)

    updatePassengers(healthFactor)

    self.driver = driverThisFrame
  end
end

-- basically ripped from the shuttlecraft mod, edited and such for this vehicle's purposes though.
function gunnerFollowerEmbark(npcId)
			local driverSeat = "drivingSeat"
			local boardSeat = nil

			if world.entityType(npcId) == "npc" then
				if vehicle.entityLoungingIn(driverSeat) ~= nil then 
					if vehicle.entityLoungingIn("passengerSeat") == nil and boardSeat == nil then 
						boardSeat = 1
					end 
				end 
				if boardSeat ~= nil then 
						local beamin = false 
						if world.magnitude(world.entityPosition(npcId), mcontroller.position()) >= 20 then beamin = true end
						world.callScriptedEntity(npcId, "setShuttlecraftLounge", entity.id(), boardSeat, beamin )
				end
			end
	self.boardGunnerFollower = nil
end

function aiTargeting()
	--world.debugLine(vec2.add(animator.partPoint("turretGun", "firePoint"), mcontroller.position()), self.gunnerAimPos, {255,0,0,255})
	
	self.aiFireMachineguns = false
	if vehicle.entityLoungingIn("passengerSeat") == nil or world.entityType(vehicle.entityLoungingIn("passengerSeat")) ~= "npc" then
		self.gunnerAimPos = vehicle.aimPosition("passengerSeat")
		return
	else
		local npcId = vehicle.entityLoungingIn("passengerSeat")
		
		-- ok most of this is my own stuff but the base targeting code is ripped from the shuttlecraft mod
		-- anyways just also wanted to say that this stuff is cool, since *you can pull many functions from the NPC*, many more than I had thought possible!
		-- cool stuff since yeah main thing is that the AI targeting priorities here will be based off the targeting priorities of the NPC itself!
		
		local range = 60
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
				local pos = vec2.add(mcontroller.position(),animator.partPoint("turretGun", "firePoint"))
				local canPos = world.entityPosition(validTarget)
				local diff = world.distance(vec2.add({0,3.2},canPos), pos)
				local aimAngle = math.atan(diff[2], diff[1])
				
				local facing = self.facingDirection
				
				local gunAngle = animator.currentRotationAngle("guns")
				if facing < 0 then gunAngle = math.pi - gunAngle + self.angle
				else
					gunAngle = gunAngle + self.angle
				end
				
				local toTarget = vec2.angle(world.distance(canPos, pos))
				local toTargetAngle = util.angleDiff(gunAngle, toTarget % (2*math.pi))
				
				if math.abs(toTargetAngle) <= (15 * math.pi / 180) then --15 degrees of lenience
					self.aiFireMachineguns = true --trigger firing of machine guns
				end
				
				self.gunnerAimPos = world.entityPosition(validTarget)
				--sb.logInfo(sb.printJson(validTarget))
				--world.debugLine(vec2.add(animator.partPoint("turretGun", "firePoint"), mcontroller.position()), world.entityPosition(validTarget), {0,255,0,255})
			end
		end
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
      --vehicle.setLoungeEmote("passengerSeat", self.damageStatePassengerEmotes[damageStateIndex])

      maxDamageState = #self.damageStateDriverEmotes
      damageStateIndex = maxDamageState
      damageStateIndex = (maxDamageState - math.ceil(healthFactor * maxDamageState)) + 1
      --vehicle.setLoungeEmote("drivingSeat", self.damageStateDriverEmotes[damageStateIndex])
    end
  end
end

function updateDriveEffects(healthFactor, driverThisFrame)
  local startSoundName = "engineStart"
  local loopSoundName = "engineLoop"

  if (healthFactor < self.engineDamageSoundThreshold) then
    startSoundName = "engineStartDamaged"
    loopSoundName = "engineLoopDamaged"
  end

  --do we have a driver ?
  if (driverThisFrame ~= nil) then
    --has someone got in ?
    if (self.driver == nil) then
      animator.playSound(startSoundName)
    end

    --is the sound we want different to the sound we have ?
    if (loopSoundName ~= self.loopPlaying) then
      if (self.loopPlaying ~= nil) then
        animator.playSound("damageIntermittent")
        animator.stopAllSounds(self.loopPlaying, 0.5)
      end
      animator.playSound(loopSoundName, -1)
      self.loopPlaying = loopSoundName
    end
  else
    --no driver, stop the engine
    if (self.loopPlaying ~= nil) then
      animator.stopAllSounds(self.loopPlaying, 0.5)
      self.loopPlaying = nil
    end
  end

  local rearThrusterFrame = 0
  local ventralThrusterFrame = 0

  -- is the engine sound playing ?
  if (self.loopPlaying ~= nil) then
    if (self.engineVolume == self.engineIdleVolume) then
      animator.setParticleEmitterActive("rearThrusterIdle", true)
      animator.setParticleEmitterActive("rearThrusterDrive", false)
    else
      animator.setParticleEmitterActive("rearThrusterIdle", false)
      animator.setParticleEmitterActive("rearThrusterDrive", true)
      rearThrusterFrame = 3
    end

    -- a brief burst of power
    if (self.revEngine == true)  then
      -- instantly set them to full power.
      self.engineRevTimer = 0.5
      animator.setSoundPitch(self.loopPlaying, self.engineRevPitch, self.engineRevTimer)
      animator.setSoundVolume(self.loopPlaying, self.engineRevVolume, self.engineRevTimer)

      animator.setParticleEmitterActive("ventralThrusterIdle", false)
      animator.setParticleEmitterActive("ventralThrusterJump", true)
      animator.burstParticleEmitter("ventralThrusterJump")
      ventralThrusterFrame = 3

      self.revEngine = false
    else
      if (self.engineRevTimer > 0.0)  then
        self.engineRevTimer = self.engineRevTimer - script.updateDt()
        ventralThrusterFrame = 3
      else
        animator.setParticleEmitterActive("ventralThrusterIdle", true)
        animator.setParticleEmitterActive("ventralThrusterJump", false)

        --settling to the normal engine pitch and volume
        animator.setSoundPitch(self.loopPlaying, self.enginePitch, 1.5)
        animator.setSoundVolume(self.loopPlaying, self.engineVolume, 1.5)
      end
    end

    animator.setAnimationState("rearThruster", "on")
    animator.setAnimationState("bottomThruster", "on")
	
	animator.setAnimationState("fullbright", "on")
  else
    animator.setParticleEmitterActive("rearThrusterIdle", false)
    animator.setParticleEmitterActive("rearThrusterDrive", false)
    animator.setParticleEmitterActive("ventralThrusterIdle", false)
    animator.setParticleEmitterActive("ventralThrusterJump", false)

    animator.setAnimationState("rearThruster", "off")
    animator.setAnimationState("bottomThruster", "off")
	
	animator.setAnimationState("fullbright", "off")
  end

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

        local BackfireMomentum = {0, self.jumpVelocity * 0.5}
        mcontroller.addMomentum(BackfireMomentum)

        self.damageSoundTimer = math.random() * randomMax;
      end
    end
  end

  rearThrusterFrame = rearThrusterFrame + math.random(3)
  animator.setGlobalTag("rearThrusterFrame", rearThrusterFrame)

  ventralThrusterFrame = ventralThrusterFrame + math.random(3)
  animator.setGlobalTag("bottomThrusterFrame", ventralThrusterFrame)
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

  switchHeadLights(previousDamageStateIndex, damageStateIndex, headlights)

  animator.setGlobalTag("damageState", self.damageStateNames[damageStateIndex])

  --smoke particles and fire
  if newHealthFactor < 1.0 then
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

function moveZeroG()
  local dt = script.updateDt()
  if self.spin > 0 then
    self.spin = math.max(0, self.spin - self.spinFriction * dt)
  else
    self.spin = math.min(0, self.spin + self.spinFriction * dt)
  end

  self.angle = self.angle + self.spin * dt

  mcontroller.resetParameters(self.movementSettings)
  mcontroller.applyParameters(self.zeroGMovementSettings)

  local controlDirection = 0
  if vehicle.controlHeld("drivingSeat", "right") then
    controlDirection = controlDirection + 1
  end
  if vehicle.controlHeld("drivingSeat", "left") then
    controlDirection = controlDirection - 1
  end

  if controlDirection ~= 0 then
    self.spin = self.spin - self.zeroGSpinRate * controlDirection * dt
    self.facingDirection = controlDirection

    local boostVec = vec2.mul(vec2.withAngle(self.angle, self.zeroGTargetVelocity), controlDirection)
    mcontroller.approachVelocity(boostVec, self.horizontalControlForce)

    self.enginePitch = self.engineRevPitch;
    self.engineVolume = self.engineRevVolume;
  end
end

function move()
  self.spin = 0

  local groundDistance = minimumSpringDistance(self.bodySpringPositions)
  local nearGround = groundDistance < self.nearGroundDistance

  --assume idle pitch
  self.enginePitch = self.engineIdlePitch;
  self.engineVolume = self.engineIdleVolume;

  mcontroller.resetParameters(self.movementSettings)
  if self.driver then
    mcontroller.applyParameters(self.occupiedMovementSettings)
    if groundDistance <= self.hoverTargetDistance then
      mcontroller.approachYVelocity((self.hoverTargetDistance - groundDistance) * self.hoverVelocityFactor, self.hoverControlForce)
    end
  end

  if vehicle.controlHeld("drivingSeat", "left") then
    mcontroller.approachXVelocity(-self.targetHorizontalVelocity, self.horizontalControlForce)
    self.facingDirection = -1

    self.enginePitch = self.engineRevPitch;
    self.engineVolume = self.engineRevVolume;
  end

  if vehicle.controlHeld("drivingSeat", "right") then
    mcontroller.approachXVelocity(self.targetHorizontalVelocity, self.horizontalControlForce)
    self.facingDirection = 1

    self.enginePitch = self.engineRevPitch;
    self.engineVolume = self.engineRevVolume;
  end

  if vehicle.controlHeld("drivingSeat", "up") then
    local targetAngle = (self.facingDirection < 0) and -self.maxAngle or self.maxAngle
    self.angle = self.angle + (targetAngle - self.angle) * self.angleApproachFactor

    self.enginePitch = self.engineRevPitch;
    self.engineVolume = self.engineRevVolume;
  elseif vehicle.controlHeld("drivingSeat", "down") then
    local targetAngle = (self.facingDirection < 0) and self.maxAngle or -self.maxAngle
    self.angle = self.angle + (targetAngle - self.angle) * self.angleApproachFactor
  else
    local frontSpringDistance = minimumSpringDistance(self.frontSpringPositions)
    local backSpringDistance = minimumSpringDistance(self.backSpringPositions)
    if frontSpringDistance == self.maxGroundSearchDistance and backSpringDistance == self.maxGroundSearchDistance then
      self.angle = self.angle - self.angle * self.angleApproachFactor
    else
      self.angle = self.angle + math.atan((backSpringDistance - frontSpringDistance) * self.levelApproachFactor)
      self.angle = math.min(math.max(self.angle, -self.maxAngle), self.maxAngle)
    end
  end

  if nearGround then
    if self.jumpTimer <= 0 and vehicle.controlHeld("drivingSeat", "jump") then
      mcontroller.setYVelocity(self.jumpVelocity)
      self.jumpTimer = self.jumpTimeout
      self.revEngine = true;
    else
      self.jumpTimer = self.jumpTimer - script.updateDt()
    end
  else
    self.jumpTimer = self.jumpTimeout
  end

  mcontroller.setRotation(self.angle)
end

function controls()
  if (vehicle.controlHeld("drivingSeat", "PrimaryFire")) then
    if (self.headlightCanToggle) then
      updateVisualEffects(storage.health, 0, (not self.headlightsOn))

      if (self.headlightsOn) then
        animator.playSound("headlightSwitchOn")
      else
        animator.playSound("headlightSwitchOff")
      end

      self.headlightCanToggle = false
    end
  else
    self.headlightCanToggle = true;
  end

  if (vehicle.controlHeld("drivingSeat", "AltFire")) then
    if not self.hornPlaying then
      animator.playSound("hornLoop", -1)
      self.hornPlaying = true;
    end
  else
    if self.hornPlaying then
      animator.stopAllSounds("hornLoop")
      self.hornPlaying = false;
    end
  end
  
  
  
  -- GUNS --
  
  local facing = self.facingDirection
  local diff = world.distance(self.gunnerAimPos, vec2.add(mcontroller.position(),animator.partPoint("turretGun", "rotationCenter")))
  local aimAngle = math.atan(diff[2], diff[1])
  --local facingDirection = (aimAngle > math.pi / 2 or aimAngle < -math.pi / 2) and -1 or 1
  local facingDirection = facing
  local aimLimit = config.getParameter("aimLimit") * math.pi / 180
  local gunProjectile = config.getParameter("gunProjectile")
  local gunProjectileConfig = config.getParameter("gunProjectileConfig")
  local gunFireCycle = config.getParameter("gunFireCycle")
  
  if vehicle.entityLoungingIn("passengerSeat") ~= nil then
  
  if facingDirection < 0 then
    facing = -1

    if aimAngle > 0 then
      aimAngle = math.max(aimAngle, math.pi - aimLimit + self.angle)
    else
      aimAngle = math.min(aimAngle, -math.pi + aimLimit + self.angle)
    end

    animator.rotateGroup("guns", math.pi - aimAngle + self.angle)
  else
    facing = 1

    if aimAngle > 0 then
      aimAngle = math.min(aimAngle, aimLimit + self.angle)
    else
      aimAngle = math.max(aimAngle, -aimLimit + self.angle)
    end

    animator.rotateGroup("guns", aimAngle - self.angle)
  end
  
  function spawnMuzzle()
	world.spawnProjectile(config.getParameter("muzzleProjectile"), vec2.add(mcontroller.position(), animator.partPoint("turretGun", "firePoint")), entity.id(), aimVector(aimAngle,inaccuracy), false, config.getParameter("muzzleProjectileConfig"))
  end
  
  local inaccuracy = 0.04
    if vehicle.controlHeld("passengerSeat", "primaryFire") or self.aiFireMachineguns then
	  local projectile = ""
	  local missChanceRoll = math.random(0,100)
	  local missChance = config.getParameter("gunMissChance")
	  
	  if missChanceRoll <= missChance then
		projectile = config.getParameter("missProjectile")
	  else
		projectile = gunProjectile
	  end
	  
      if self.fireTimer <= 0 then
        world.spawnProjectile(projectile, vec2.add(mcontroller.position(), animator.partPoint("turretGun", "firePoint")), entity.id(), aimVector(aimAngle,inaccuracy), false, gunProjectileConfig)
        self.fireTimer = self.fireTimer + gunFireCycle
        --animator.setAnimationState("frontFiring2", "fire")
		animator.playSound("fire")
		spawnMuzzle()
		
		--animator.burstParticleEmitter("muzzleFlash")
		--animator.burstParticleEmitter("hotsmoke")
      else
        local oldFireTimer = self.fireTimer
        self.fireTimer = self.fireTimer - script.updateDt()
        if oldFireTimer > gunFireCycle / 2 and self.fireTimer <= gunFireCycle / 2 then
          world.spawnProjectile(projectile, vec2.add(mcontroller.position(), animator.partPoint("turretGun", "firePoint")), entity.id(), aimVector(aimAngle,inaccuracy), false, gunProjectileConfig)
          --animator.setAnimationState("frontFiring2", "fire")
		  animator.playSound("fire")
		  spawnMuzzle()
		  
		  --animator.burstParticleEmitter("muzzleFlash")
		  --animator.burstParticleEmitter("hotsmoke")
        end
      end
	  
	  
	end
	
	end
end

function aimVector(aimAngle,inaccuracy)
  local aimVector = vec2.rotate({1, 0}, (aimAngle + sb.nrand(inaccuracy, 0)))
  --aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function animate()
  animator.resetTransformationGroup("flip")
  if self.facingDirection < 0 then
    animator.scaleTransformationGroup("flip", {-1, 1})
  end

  animator.resetTransformationGroup("rotation")
  animator.rotateTransformationGroup("rotation", self.angle)
end

function updateDamage()
  if animator.animationState("onfire") == "on" then
    setDamageEmotes()

    local damageThisFrame = self.damagePerSecondWhenOnFire * script.updateDt()
    updateVisualEffects(storage.health, damageThisFrame, self.headlightsOn)
    storage.health = storage.health - damageThisFrame
  end

  if storage.health <= 0 then
    animator.burstParticleEmitter("damageShards")
    --animator.burstParticleEmitter("wreckage")
    animator.playSound("explode")

    local projectileConfig = {
      damageTeam = { type = "indiscriminate" },
      power = config.getParameter("explosionDamage"),
      onlyHitTerrain = false,
      timeToLive = 0,
      actionOnReap = {
        {
          action = "config",
          file =  config.getParameter("explosionConfig")
        }
      }
    }
    world.spawnProjectile("invisibleprojectile", mcontroller.position(), 0, {0, 0}, false, projectileConfig)
	world.spawnProjectile(config.getParameter("deathProjectileType"), mcontroller.position(), 0, {0, 0}, false, config.getParameter("deathProjectileParameters"))

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

      storage.health = storage.health - self.terrainCollisionDamage
      self.collisionDamageTrackingVelocities = {}
      self.collisionNotificationTrackingVelocities = {}

      table.insert(self.selfDamageNotifications, {
        sourceEntityId = entity.id(),
        targetEntityId = entity.id(),
        position = mcontroller.position(),
        damageDealt = self.terrainCollisionDamage,
        healthLost = self.terrainCollisionDamage,
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

function distanceToGround(point)
  local endPoint = vec2.add(point, {0, -self.maxGroundSearchDistance})

  world.debugLine(point, endPoint, {255, 255, 0, 255})
  local intPoint = world.lineCollision(point, endPoint)

  if intPoint then
    world.debugPoint(intPoint, {255, 255, 0, 255})
    return point[2] - intPoint[2]
  else
    return self.maxGroundSearchDistance
  end
end
