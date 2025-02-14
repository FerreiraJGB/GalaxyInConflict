require "/scripts/vec2.lua"

function init()
  self.active = false
  self.fireTimer = 0
  animator.rotateGroup("guns", 0, true)
  self.level = config.getParameter("mechLevel", 6)
  
  self.groundFrames = 1
  self.walkCycle = 0
  self.walkCycleTime = config.getParameter("walkCycleTime")
  self.rocketTimer = 0
  
  --this comes in from the controller.
  self.ownerKey = config.getParameter("ownerKey")
  --vehicle.setPersistent(self.ownerKey)

  self.maxHealth = config.getParameter("maxHealth")
  self.maxShields = config.getParameter("maxShields",200)
  --self.shields = 0.0--self.maxShields
  self.shieldCooldown = 0.0
  
  --assume maxhealth
  if (storage.health) then
    --animator.setAnimationState("movement", "idle")
  else
    --local startHealthFactor = config.getParameter("startHealthFactor")

    --if (startHealthFactor == nil) then
        storage.health = config.getParameter("maxHealth")
		storage.shields = 0
		--sb.logInfo(sb.printJson(storage.health))
    --else
	   --sb.logInfo("set new health")
       --storage.health = math.min(startHealthFactor * self.maxHealth, self.maxHealth)
   -- end
    --animator.setAnimationState("movement", "warpInPart1")
  end
  --sb.logInfo(sb.printJson(storage.health))

  --setup the store functionality
  message.setHandler("store",
      function(_, _, ownerKey)
        if (self.ownerKey and self.ownerKey == ownerKey and self.driver == nil and animator.animationState("movement") == "idle") then
          --animator.setAnimationState("movement", "warpOutPart1")
          --switchHeadLights(1, 1, false)
          --animator.playSound("returnvehicle")
          return {storable = true, healthFactor = storage.health / self.maxHealth}
        else
          return {storable = false, healthFactor = storage.health / self.maxHealth}
        end
      end)
end

function update(dt)
  if mcontroller.atWorldLimit() then
    vehicle.destroy()
    return
  end

  local mechAimLimit = config.getParameter("mechAimLimit") * math.pi / 180
  local mechHorizontalMovement = config.getParameter("mechHorizontalMovement")
  local mechJumpVelocity = config.getParameter("mechJumpVelocity")
  local mechFireCycle = config.getParameter("mechFireCycle")
  local mechProjectile = config.getParameter("mechProjectile")
  local mechProjectileConfig = config.getParameter("mechProjectileConfig")
  local rocketProjectile = config.getParameter("rocketProjectile")
  local rocketProjectileConfig = config.getParameter("rocketProjectileConfig")
  local rocketAimLimit = config.getParameter("rocketAimLimit",40) * math.pi / 180
  local offGroundFrames = config.getParameter("offGroundFrames")
  local rocketReloadTime = config.getParameter("rocketReloadTime",5)

  local mechCollisionPoly = mcontroller.collisionPoly()
  local position = mcontroller.position()

  if mechProjectileConfig.power then
    mechProjectileConfig.power = root.evalFunction("weaponDamageLevelMultiplier", self.level) * mechProjectileConfig.power
  end

  local entityInSeat = vehicle.entityLoungingIn("seat")
  if entityInSeat then
    vehicle.setDamageTeam(world.entityDamageTeam(entityInSeat))
	animator.setGlobalTag("barScale", "")
  else
	animator.setGlobalTag("barScale", "crop=0;0;0;0;")
    vehicle.setDamageTeam({type = "passive"})
  end

  local diff = world.distance(vehicle.aimPosition("seat"), mcontroller.position())
  local aimAngle = math.atan(diff[2], diff[1])
  local facingDirection = (aimAngle > math.pi / 2 or aimAngle < -math.pi / 2) and -1 or 1
  
  local diff2 = vec2.add(diff,{0.0,-5.0})
  local aimAngleRocket = math.atan(diff2[2], diff2[1])

  if facingDirection < 0 then
    animator.setFlipped(true)
	animator.setGlobalTag("flipBar", "?flipx;")

    if aimAngle > 0 then
      aimAngle = math.max(aimAngle, math.pi - mechAimLimit)
    else
      aimAngle = math.min(aimAngle, -math.pi + mechAimLimit)
    end
	
	if aimAngleRocket > 0 then
	  aimAngleRocket = math.max(aimAngleRocket, math.pi - rocketAimLimit)
    else
	  aimAngleRocket = math.min(aimAngleRocket, -math.pi + rocketAimLimit)
    end

	animator.rotateGroup("rockets", math.pi - aimAngleRocket)
    animator.rotateGroup("guns", math.pi - aimAngle)
  else
    animator.setFlipped(false)
	animator.setGlobalTag("flipBar", "")

    if aimAngle > 0 then
      aimAngle = math.min(aimAngle, mechAimLimit)
    else
      aimAngle = math.max(aimAngle, -mechAimLimit)
    end
	
	if aimAngleRocket > 0 then
      aimAngleRocket = math.min(aimAngleRocket, rocketAimLimit)
    else
      aimAngleRocket = math.max(aimAngleRocket, -rocketAimLimit)
    end
	
	animator.rotateGroup("rockets", aimAngleRocket)
    animator.rotateGroup("guns", aimAngle)
  end

  local onGround = mcontroller.onGround()
  local movingDirection = 0

  if vehicle.controlHeld("seat", "left") and onGround then-- and onGround then
    mcontroller.setXVelocity(-mechHorizontalMovement)
    movingDirection = -1
  end

  if vehicle.controlHeld("seat", "right") and onGround then-- and onGround then
    mcontroller.setXVelocity(mechHorizontalMovement)
    movingDirection = 1
  end

  if onGround then
    self.groundFrames = offGroundFrames
  else
    self.groundFrames = self.groundFrames - 1
  end

  self.walkCycle = math.max(0,self.walkCycle - dt)
  
  if vehicle.controlHeld("seat", "jump") and onGround then
    mcontroller.setXVelocity(mechJumpVelocity[1] * movingDirection)
    mcontroller.setYVelocity(mechJumpVelocity[2])
    animator.setAnimationState("movement", "jump")
    self.groundFrames = 0
  end

  self.walkingDir = 0
  
  if self.groundFrames <= 0 then
    if mcontroller.velocity()[2] > 0 then
      animator.setAnimationState("movement", "jump")
    else
      animator.setAnimationState("movement", "fall")
    end
  elseif movingDirection ~= 0 then
    if facingDirection ~= movingDirection then
      animator.setAnimationState("movement", "backWalk")
	  
	  --if self.walkingDir == -1 then --reset walking direction
		--self.walkCycle = 0
		--animator.stopAllSounds("walk")
	  --end
	  --self.walkingDir = 1
	  
	  if self.walkCycle == 0 then
		animator.playSound("walk")
		self.walkCycle = self.walkCycleTime
	  end
    else
      animator.setAnimationState("movement", "walk")
	  
	  --if self.walkingDir == 1 then --reset walking direction
		--self.walkCycle = 0
		--animator.stopAllSounds("walk")
	  --end
	  --self.walkingDir = -1
	  
	  
	  if self.walkCycle == 0 then
		animator.playSound("walk")
		self.walkCycle = self.walkCycleTime
	  end
    end
  elseif onGround then
	--animator.stopAllSounds("walk")
    animator.setAnimationState("movement", "idle")
	self.walkingDir = 0
  end

  if vehicle.controlHeld("seat", "primaryFire") then
    if self.fireTimer <= 0 then
	  --animator.playSound("fire")
	  
	  local inaccuracy = config.getParameter("mechFireInaccuracy",0)
	  local angle = {math.cos(aimAngle), math.sin(aimAngle)}
	  local aimVector = vec2.rotate(angle,sb.nrand(inaccuracy, 0))
	  aimVector[1] = aimVector[1]
	  
      world.spawnProjectile(mechProjectile, vec2.add(mcontroller.position(), animator.partPoint("frontGun", "firePoint")), entity.id(), aimVector, false, mechProjectileConfig)
      self.fireTimer = self.fireTimer + mechFireCycle
      animator.setAnimationState("frontFiring", "fire")
    else
      local oldFireTimer = self.fireTimer
      self.fireTimer = self.fireTimer - script.updateDt()
      if oldFireTimer > mechFireCycle / 2 and self.fireTimer <= mechFireCycle / 2 then
		--animator.playSound("fire")
		
		local inaccuracy = config.getParameter("mechFireInaccuracy",0)
		local angle = {math.cos(aimAngle), math.sin(aimAngle)}
		local aimVector = vec2.rotate(angle,sb.nrand(inaccuracy, 0))
		aimVector[1] = aimVector[1]
		
        world.spawnProjectile(mechProjectile, vec2.add(mcontroller.position(), animator.partPoint("backGun", "firePoint")), entity.id(), aimVector, false, mechProjectileConfig)
        animator.setAnimationState("backFiring", "fire")
      end
    end
  end
  
  
  --rocket stuff
  self.rocketTimer = math.max(self.rocketTimer - dt,0)
  
  if vehicle.controlHeld("seat", "altFire") then
    if self.rocketTimer <= 0 then
	  --animator.playSound("fire")
      
      self.rocketTimer = rocketReloadTime
	  self.fireRocket = true
      animator.setAnimationState("rocketPod", "open")
    end
  end
  
  if self.rocketTimer <= (rocketReloadTime - 0.25) and self.fireRocket == true then
	self.fireRocket = false
	animator.setAnimationState("rocketPod", "fire")
	world.spawnProjectile(rocketProjectile, vec2.add(mcontroller.position(), animator.partPoint("rocketPod", "firePoint")), entity.id(), {math.cos(aimAngleRocket), math.sin(aimAngleRocket)}, false, rocketProjectileConfig)
  end
  
  
  self.shieldCooldown = math.max(self.shieldCooldown - dt,0)
  if self.shieldCooldown == 0 and storage.shields < self.maxShields then
	storage.shields = math.min(storage.shields + 0.5,self.maxShields)
  end
  
  updateDamage();
end

function updateDamage()

	if storage.health <= 0 then
		world.spawnProjectile("gic_mechrocket", mcontroller.position(), entity.id(), {0,0}, false, {power=50,timeToLive=0})
		vehicle.destroy()
	end
	
	local hp66 = self.maxHealth*0.6666
	local hp33 = self.maxHealth*0.3333
	
	if storage.health <= hp66 then --at 66% smoke starts occuring
		animator.setParticleEmitterActive("smoke", true)
	else
		animator.setParticleEmitterActive("smoke", false)
	end
	
	if storage.health <= hp33 then --at 33% fire starts occuring
		animator.setParticleEmitterActive("fire", true)
	else
		animator.setParticleEmitterActive("fire", false)
	end
	
	local firstHealthBar = storage.health - hp66;
	local secondHealthBar = storage.health - hp33;
	--local thirdHealthBar = storage.health;
	
	local ratioHp1 = math.min(1.0,firstHealthBar / hp33)
	
	local ratioHp2 = math.min(2.0,secondHealthBar / hp33)
	
	local ratioHp3 = storage.health / hp33
	
	local shieldHp = storage.shields / self.maxShields
	
	
	--sb.logInfo(sb.printJson(mathTmp))
	
	if firstHealthBar > 0 then
		animator.setGlobalTag("hbar1", "fade=000000;" .. (1 - round(1,ratioHp1)))
		animator.setGlobalTag("hbar2", "fade=000000;0")
		animator.setGlobalTag("hbar3", "fade=000000;0")
	elseif secondHealthBar > 0 then
		animator.setGlobalTag("hbar1", "fade=000000;1.0")
		animator.setGlobalTag("hbar2", "fade=000000;" .. (1 - round(1,ratioHp2)))
		animator.setGlobalTag("hbar3", "fade=000000;0")
	else
		animator.setGlobalTag("hbar1", "fade=000000;1.0")
		animator.setGlobalTag("hbar2", "fade=000000;1.0")
		animator.setGlobalTag("hbar3", "fade=000000;" .. (1 - round(1,ratioHp3)))
	end
	
	if shieldHp > 0 then
		animator.setGlobalTag("shieldbar", "fade=000000;" .. (1 - round(1,shieldHp)))
	else
		animator.setGlobalTag("shieldbar", "fade=000000;1.0")
	end
end

function round(decimalPlaces,exact)
	return tonumber(string.format("%."..(decimalPlaces or 1).."f", exact))
end

function checkResistances(resistance)
	local resistancesParam = config.getParameter("resistances")
	for i,v in pairs(resistancesParam) do
		--sb.logInfo(resistance)
		--sb.logInfo(i)
		--sb.logInfo("")
		if i == resistance then
		return v end
	end
	return false
end

function applyDamage(damageRequest)
  local damage = 0
  
  
  --shield damage stuff, only triggers if shield is up.
  if storage.shields > 0 then
	local healthLost = math.min(damageRequest.damage, storage.shields)
	storage.shields = storage.shields - healthLost
	self.shieldCooldown = 2.0
	
	if storage.shields == 0 then self.shieldCooldown = 5.0 end
	
	return {{
		sourceEntityId = damageRequest.sourceEntityId,
		targetEntityId = entity.id(),
		position = mcontroller.position(),
		damageDealt = damageRequest.damage,
		healthLost = healthLost,
		hitType = "Hit",
		damageSourceKind = damageRequest.damageSourceKind,
		targetMaterialKind = "robotic",
		killed = storage.health <= 0
	}}
  end
  
  --note- ex damageRequest
  --{"hitType":"Hit","statusEffects":{},"knockbackMomentum":[5.82374,8.12921],"damageSourceKind":"dagger","sourceEntityId":2089,"damageType":"Damage","damage":4.4275}
  
  
  
  --custom code for damage resistances for GiC stuff.
  --cool beans yeah?
  
  --local damageResist = checkResistances(damageRequest.damageSourceKind)
	--sb.logInfo(sb.printJson(damageResist))
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

  --sb.logInfo(sb.printJson(storage.health))
  local healthLost = math.min(damage, storage.health)
  storage.health = storage.health - healthLost

  if damage > 0 then
   animator.burstParticleEmitter("damageIntermittent")
  end
  
  return {{
    sourceEntityId = damageRequest.sourceEntityId,
    targetEntityId = entity.id(),
    position = mcontroller.position(),
    damageDealt = damage,
    healthLost = healthLost,
    hitType = "Hit",
    damageSourceKind = damageRequest.damageSourceKind,
    targetMaterialKind = "robotic",
    killed = storage.health <= 0
  }}
end
