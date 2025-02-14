require("/scripts/vec2.lua")

-- world.spawnVehicle(`String` vehicleName, `Vec2F` position, [`Json` overrides])

function init()

   message.setHandler("pauseCoin",
      function()
		--storage.startingVelocity = mcontroller.velocity()
		
		local params = config.getParameter("movementSettings")
		params.gravityEnabled = false
		mcontroller.applyParameters(params)
		mcontroller.setVelocity({0,0})
		storage.countTime = false
		
		animator.setAnimationState("coin", "frozen", true)
		--sb.logInfo("pausedCoin")
      end)
	  
  self.sourceEntity = entity.id()
  self.queryParametersPrime = {
    withoutEntityId = self.sourceEntity,
    includedTypes = {"vehicle"},
    order = "nearest"
  }
  
  self.selfDamageNotifications = {}
  
  self.materialKind = config.getParameter("materialKind") --very important you dumbass
  --having a material kind set up resolves following error:
  -- [Error] Exception while invoking lua function 'applyDamage'. (LuaConversionException) Error converting LuaValue to type 'class Star::List<struct Star::DamageNotification,class std::allocator<struct Star::DamageNotification> >'
  -- for future reference

  self.maxHealth = config.getParameter("maxHealth")
  self.protection = config.getParameter("protection")
  --assume maxhealth
  if (storage.health) then
    --animator.setAnimationState("movement", "idle")
  else
        storage.health = self.maxHealth
  end
  --sb.logInfo(storage.health)
  
  vehicle.setInteractive(false)
  vehicle.setDamageTeam({type = "indiscriminate"})
  
  storage.setVelocityYet = false;
  
  local startingVelocity = config.getParameter("startingVelocity")
  if startingVelocity and not storage.setVelocityYet then
	mcontroller.setVelocity(startingVelocity)
	storage.setVelocityYet = true
  end
  
  self.damagedEntity = nil
  self.damageReceived = 0
  
  storage.takeDamage = true
  storage.ticks = 0
  storage.timeAlive = 0
  storage.countTime = true
  storage.splitCoin = false
  
  script.setUpdateDelta(1)
  
  --to spawn a coin with proper velocity and whatnot:
  -- world.spawnVehicle("gic_coin", [position], {startingVelocity = {10,50}})
end

function update()
  if mcontroller.atWorldLimit() then
    vehicle.destroy()
	animator.stopAllSounds("coinFlash")
	animator.stopAllSounds("coinSing")
    return
  end
  
  if mcontroller.onGround() then
	vehicle.destroy()
	animator.stopAllSounds("coinFlash")
	animator.stopAllSounds("coinSing")
  end
  
  
  -- splitcoin activation
  if storage.countTime then
	storage.timeAlive = storage.timeAlive + script.updateDt()
  end
  
  if not storage.splitCoin and (storage.timeAlive > 0.33 and storage.timeAlive < 0.53) then
	storage.splitCoin = true
	animator.setAnimationState("flash", "on", true)
	animator.playSound("coinFlash")
  end
  
  if storage.splitCoin and (storage.timeAlive > 0.53 and storage.timeAlive < 1.0) then
	storage.splitCoin = false
	animator.setAnimationState("flash", "off", true)
	animator.stopAllSounds("coinFlash")
  end
  
  if not storage.splitCoin and (storage.timeAlive > 1.0) then
	storage.splitCoin = true
	animator.setAnimationState("sing", "on", true)
	animator.setSoundVolume("coinSing",0.5)
	animator.playSound("coinSing")
  end
  
  
  
  if (storage.ticks > 0) then
	storage.ticks = storage.ticks + 1 
	--sb.logInfo(sb.printJson(storage.ticks))
  end
  
  if (storage.health <= 0) and (storage.ticks == 0) then
    storage.takeDamage = false
	storage.startingVelocity = mcontroller.velocity()
	
	--vehicle.destroy()
	local foundCoins = findCoins()
	storage.ticks = storage.ticks + 1
	--sb.logInfo(sb.printJson(storage.ticks))
	
	local params = config.getParameter("movementSettings")
	mcontroller.setVelocity({0,0})
	params.gravityEnabled = false
	mcontroller.applyParameters(params)
	
	animator.setSoundVolume("coinHit",2.0)
	animator.playSound("coinHit")
	--animator.playSound("coinHit")
  end
	
	--vehicle.setDamageTeam({type = "passive"})
	--self.stopDamage = true
	--sb.logInfo(self.damageReceived)
  
  if storage.ticks == 5 then
	vehicle.destroy()
	animator.stopAllSounds("coinFlash")
	animator.stopAllSounds("coinSing")
	self.damageReceived = self.maxHealth - storage.health
	world.spawnProjectile("gic_null_coinbuffer", mcontroller.position(), self.damagedEntity, {0,0}, false, {startingVelocity = storage.startingVelocity, power = 1.75*self.damageReceived, damagedKind = self.damagedKind, damagedType = self.damagedType, ignoreCoin = entity.id(), splitCoin = storage.splitCoin, ownerCoin = entity.id()})
	--world.spawnProjectile(`String` projectileName, `Vec2F` position, [`EntityId` sourceEntityId], [`Vec2F` direction], [`bool` trackSourceEntity], [`Json` parameters])
  end
end

function applyDamage(damageRequest)
  --sb.logInfo(storage.health)
  local damage = 0
  local healthLost = 0
  
  if storage.takeDamage then
  --self.damageReceived = damage + self.damageReceived
  
  --if damageRequest.damageType == "Damage" then
   -- damage = damage + root.evalFunction2("protection", damageRequest.damage, self.protection)
  --elseif damageRequest.damageType == "IgnoresDef" then
    damage = damage + damageRequest.damage
  --else
    --return
  --end

	healthLost = damage--math.min(damage, storage.health)
	storage.health = storage.health - healthLost
	
	self.damagedEntity = damageRequest.sourceEntityId
	self.damagedKind = damageRequest.damageSourceKind
	self.damagedType = damageRequest.damageType
  else
	--self.damagedEntity = damageRequest.sourceEntityId
	damageRequest.damageSourceKind = "noDamage"
	damageRequest.damageType = "noDamage"
	--self.damagedKind = "noDamage"
	--self.damagedType = "noDamage"
  end


  
  
  -- sb.logInfo(damage)
  -- if damage == 0 then
	-- sb.logInfo("triggerAlt?")
	-- return {{
		-- sourceEntityId = entity.id(),
		-- targetEntityId = entity.id(),
		-- position = mcontroller.position(),
		-- damageDealt = damage,
		-- healthLost = healthLost,
		-- hitType = "Hit",
		-- damageSourceKind = "noDamage",
		-- targetMaterialKind = self.materialKind,
		-- killed = false
	-- }}
  -- end
  
  return {{
    sourceEntityId = damageRequest.sourceEntityId,
    targetEntityId = entity.id(),
    position = mcontroller.position(),
    damageDealt = damage,
    healthLost = healthLost,
    hitType = "Hit",
    damageSourceKind = damageRequest.damageSourceKind,
	damageType = damageRequest.damageType,
    targetMaterialKind = self.materialKind,
    killed = storage.health <= 0
  }}
end

function selfDamageNotifications()
  local sdn = self.selfDamageNotifications
  self.selfDamageNotifications = {}
  return sdn
end

function findCoins()
  local pos = mcontroller.position()
  self.homingDistance = 100
  local candidatesPrime = world.entityQuery(pos, self.homingDistance, self.queryParametersPrime)

  --if #candidates == 0 then return end
  if #candidatesPrime == 0 then return {} end

  --local vel = {1,0}--mcontroller.velocity()
  --local angle = vec2.angle(vel)
  
 --self.foundTarget = false
 --sb.logInfo(sb.printJson(candidatesPrime))
 --sb.logInfo(sb.printJson(candidates))
  local validCandidates = {}
  for _, candidate in ipairs(candidatesPrime) do
    if world.entityCanDamage(self.sourceEntity, candidate) and world.entityName(candidate) == "gic_coin" then
      local canPos = world.entityPosition(candidate)
      if not world.lineTileCollision(pos, canPos) then
        local toTarget = world.distance(canPos, pos)
        --local toTargetAngle = util.angleDiff(angle, vec2.angle(toTarget))
		
		validCandidates[#validCandidates+1] = candidate
		world.sendEntityMessage(candidate, "pauseCoin")
		--sb.logInfo(sb.printJson(candidate))
		
      end
    end
  end
  
  return validCandidates
end