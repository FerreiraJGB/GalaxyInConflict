require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/vec2.lua"

function init()
  self.projectileType = config.getParameter( "projectileType" )
  self.projectileTypeMiss = config.getParameter( "projectileTypeMiss" )
  self.mainOffset = config.getParameter( "offset")
  --self.xOffset = config.getParameter( "xOffset", 0)
  --self.yOffset = config.getParameter( "yOffset", 0)
  self.xOffset = self.mainOffset[1]
  self.yOffset = self.mainOffset[2]
  self.muzzleOffset = config.getParameter( "muzzleOffset")
  self.xMuzzleOffset = self.muzzleOffset[1]
  self.yMuzzleOffset = self.muzzleOffset[2]
  
  self.muzzleOffset2 = config.getParameter( "muzzleOffset2")
  self.xMuzzleOffset2 = self.muzzleOffset2[1]
  self.yMuzzleOffset2 = self.muzzleOffset2[2]
  
  --self.rotationOffset = config.getParameter( "rotationOffset")
  --self.xOffsetRotationPoint = self.rotationOffset[1]
  --self.yOffsetRotationPoint = self.rotationOffset[2]
  self.inaccuracyAngle = config.getParameter( "inaccuracyAngle" )
  self.fireTimer = config.getParameter( "fireRate" )
  self.baseDamage = config.getParameter( "baseDamage" )
  self.projectileCount = config.getParameter( "projectileCount" )
  --self.energyPerShot = config.getParameter("energyPerShot", 50)
  self.ammoCount = config.getParameter("ammoCountMax",50)
  self.textProjectileParams = config.getParameter("textProjectileParams")
  
  self.trackingDistance = config.getParameter("trackingDistance", 30)
  self.trackingAngle = config.getParameter("trackingAngle", 30)
  self.sourceEntity = entity.id()
  self.queryParameters = {
    withoutEntityId = self.sourceEntity,
    includedTypes = {"creature"},
    order = "nearest"
  }
  self.reloadTimer = 0
  self.reloadQuery = false
  self.autoReloadTimer = 0
  --animator.addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)
  
  --self.totalOffset = [0,0]
  self.totalOffsetX = 0
  self.maxTotalOffsetX = config.getParameter( "maxDriftOffset", 100 )
  self.movementMultiplier = config.getParameter( "driftMultiplier", 10 )
end

function update(dt)
  self.fireTimer = math.max(0, self.fireTimer - dt)
  
  if mcontroller.crouching() == true then
  self.crouchingQuery = 1
  else
  self.crouchingQuery = 0
  end
  
  if mcontroller.facingDirection() == 1 then
  --self.totalOffsetX = self.totalOffsetX * 0.9
  self.totalOffsetX = math.max(-1 * self.maxTotalOffsetX, self.totalOffsetX - (self.movementMultiplier * dt))
  self.totalOffsetX = math.max(-1 * self.maxTotalOffsetX, self.totalOffsetX * 0.9)
  else
  --self.totalOffsetX = self.totalOffsetX * 0.9
  self.totalOffsetX = math.min(self.maxTotalOffsetX, self.totalOffsetX + (self.movementMultiplier * dt))
  self.totalOffsetX = math.min(self.maxTotalOffsetX, self.totalOffsetX * 0.9)
  end
  
  findTargets()
  if self.fireTimer == 0 and self.shouldFire == true
	and self.ammoCount > 0
	and self.reloadTimer == 0
	--and status.overConsumeResource("energy", energyPerShot())
	then
	--if mcontroller.crouching() == true then
	--status.setResource("energy", 10)
	--findTargets()
	self.autoReloadTimer = 5
	self.ammoCount = self.ammoCount - 1
	animator.playSound("fire")
	animator.burstParticleEmitter("muzzleFlash", true)
	animator.burstParticleEmitter("hotsmoke", true)
	for i = 1, (self.projectileCount) do
		if config.getParameter("missChance") then
			self.missChanceResultVar = math.random(100)
		if self.missChanceResultVar <= config.getParameter("missChance") then
			projectileType = self.projectileTypeMiss
		else
			projectileType = self.projectileType
		end
	else
	projectileType = self.projectileType
	end
	world.spawnProjectile(projectileType, vec2.add(mcontroller.position(), {self.totalOffsetX + self.xMuzzleOffset * mcontroller.facingDirection(), self.yMuzzleOffset - (1 * self.crouchingQuery)}), entity.id(), {1 * self.distPosX, (self.toTargetAngle * 1) + determineInaccuracy()}, false, { power = damagePerShot() })
	
	world.spawnProjectile(projectileType, vec2.add(mcontroller.position(), {self.totalOffsetX + self.xMuzzleOffset2 * mcontroller.facingDirection(), self.yMuzzleOffset2 - (1 * self.crouchingQuery)}), entity.id(), {1 * self.distPosX, (self.toTargetAngle * 1) + determineInaccuracy()}, false, { power = damagePerShot() })
	
	self.fireTimer = config.getParameter( "fireRate" )
	end
  end
  
  animator.resetTransformationGroup("turret")
  animator.resetTransformationGroup("turret2")
  if self.shouldFire == false then
  self.toTarget = {mcontroller.facingDirection(),0}
  self.toTarget2 = {mcontroller.facingDirection(),0}
  end
  
  self.tmpoffset = {self.totalOffsetX + self.xMuzzleOffset * mcontroller.facingDirection(),self.yMuzzleOffset - (1 * self.crouchingQuery)}
  self.tmpoffset2 = {self.totalOffsetX + self.xMuzzleOffset2 * mcontroller.facingDirection(),self.yMuzzleOffset2 - (1 * self.crouchingQuery)}
  
  animator.translateTransformationGroup("turret",{self.totalOffsetX + self.xMuzzleOffset * mcontroller.facingDirection(), self.yMuzzleOffset - (1 * self.crouchingQuery)})
  animator.translateTransformationGroup("turret2",{self.totalOffsetX + self.xMuzzleOffset2 * mcontroller.facingDirection(), self.yMuzzleOffset2 - (1 * self.crouchingQuery)})
  
  if self.shouldFire == true then
  animator.rotateTransformationGroup("turret", vec2.angle(world.distance(self.canPos, vec2.add(mcontroller.position(), self.tmpoffset))), {self.totalOffsetX + self.xMuzzleOffset * mcontroller.facingDirection(),self.yMuzzleOffset - (1 * self.crouchingQuery)})
  
  animator.rotateTransformationGroup("turret2", vec2.angle(world.distance(self.canPos, vec2.add(mcontroller.position(), self.tmpoffset2))), {self.totalOffsetX + self.xMuzzleOffset2 * mcontroller.facingDirection(),self.yMuzzleOffset2 - (1 * self.crouchingQuery)})
  else
  animator.rotateTransformationGroup("turret",vec2.angle(self.toTarget),{self.totalOffsetX + self.xMuzzleOffset * mcontroller.facingDirection(), self.yMuzzleOffset - (1 * self.crouchingQuery)})
  
  animator.rotateTransformationGroup("turret2",vec2.angle(self.toTarget2),{self.totalOffsetX + self.xMuzzleOffset2 * mcontroller.facingDirection(), self.yMuzzleOffset2 - (1 * self.crouchingQuery)})
  end
  
  animator.resetTransformationGroup("body")
  animator.translateTransformationGroup("body",{self.totalOffsetX + self.xOffset * mcontroller.facingDirection(), self.yOffset - (1 * self.crouchingQuery)})
  
  if mcontroller.facingDirection() == -1 then 
	animator.setGlobalTag("facingDirection", "?flipx") 
  else 
	animator.setGlobalTag("facingDirection", "")
  end
  
  if self.ammoCount == 0  or
   self.ammoCount < config.getParameter("ammoCountMax",50) 
   and self.autoReloadTimer == 0 then
   if self.reloadTimer == 0 
   and self.reloadQuery == false
   then
   self.reloadTimer = config.getParameter("reloadTimer", 3)
   self.reloadQuery = true
   animator.playSound("reload")
   else
   local params = sb.jsonMerge(self.textProjectileParams, projectileParams or {})
   world.spawnProjectile("invisibleprojectile", vec2.add(mcontroller.position(), {self.totalOffsetX + self.xMuzzleOffset * mcontroller.facingDirection(), self.yMuzzleOffset - (1 * self.crouchingQuery)}), entity.id(), {0,0}, false, params)
   self.ammoCount = config.getParameter("ammoCountMax",50)
   self.reloadQuery = false
   end
  end
  self.reloadTimer = math.max(0, self.reloadTimer - dt)
  
  self.autoReloadTimer = math.max(0, self.autoReloadTimer - dt)
  
  --animator.rotateTransformationGroup("turret",vec2.angle(self.toTarget),{self.xOffsetRotationPoint * mcontroller.facingDirection(),self.yOffsetRotationPoint - (1 * self.crouchingQuery)})
  
  --if mcontroller.crouching() == true then
	--animator.translateTransformationGroup("turret",{0,-1})
  --end
  
  
  world.debugText("target found? " .. sb.printJson(self.targetFound), vec2.add(mcontroller.position(), {0,1.5}), "yellow")
  world.debugText("angle " .. sb.printJson({self.distPosX, self.toTargetAngle}), vec2.add(mcontroller.position(), {0,1}), "yellow")
  --world.debugText("angle vec'd " .. sb.printJson(vec2.angle(self.toTarget)), vec2.add(mcontroller.position(), {0,2}), "yellow")
  world.debugText("angle diff " .. sb.printJson(self.toTargetAngleTmp), vec2.add(mcontroller.position(), {0,2.5}), "yellow")
  world.debugText("facing " .. sb.printJson(mcontroller.facingDirection()), vec2.add(mcontroller.position(), {0,3}), "yellow")
  world.debugText("offset " .. sb.printJson(self.mainOffset), vec2.add(mcontroller.position(), {0,3.5}), "yellow")
  world.debugText("timer  " .. sb.printJson(self.reloadTimer), vec2.add(mcontroller.position(), {0,4}), "yellow")
  world.debugText("ammoCount  " .. sb.printJson(self.ammoCount), vec2.add(mcontroller.position(), {0,4.5}), "yellow")
  world.debugText("dt " .. sb.printJson(dt), vec2.add(mcontroller.position(), {0,5}), "yellow")
  --world.debugText("offset " .. sb.printJson(world.distance(self.canPos, vec2.add(mcontroller.position(), self.tmpoffset))), vec2.add(mcontroller.position(), {0,4}), "yellow")
  --world.distance(self.canPos, vec2.add(mcontroller.position(), {self.xOffsetRotationPoint * mcontroller.facingDirection(),self.yOffsetRotationPoint - (1 * self.crouchingQuery)}))
  --world.debugText("distance" .. sb.printJson(self.toTargetAngle), vec2.add(mcontroller.position(), {0,2.5}), "yellow")
end

function determineInaccuracy()
	if self.inaccuracyAngle > 0 then
		return math.random(self.inaccuracyAngle) - (self.inaccuracyAngle/2)
	else
		return 0
	end
end

function findTargets()
  local pos = vec2.add(mcontroller.position(),{self.totalOffsetX + self.xMuzzleOffset,self.yMuzzleOffset - (1 * self.crouchingQuery)})
  local candidates = world.entityQuery(pos, self.trackingDistance, self.queryParameters)
  
  self.targetFound = false
  self.shouldFire = false
  self.toTarget = {mcontroller.facingDirection(),0}

  if #candidates == 0 then return end

  --local vel = mcontroller.velocity()
  --local angle = vec2.angle(vel)

  for _, candidate in ipairs(candidates) do
    if world.entityCanDamage(self.sourceEntity, candidate) then
      local canPos = world.entityPosition(candidate)
	  self.canPos = canPos
	  self.candidate = candidate
      if not world.lineTileCollision(pos, canPos) then
        local toTarget = world.distance(canPos, pos)
		self.toTarget = toTarget
		self.toTarget2 = world.distance(canPos, vec2.add(mcontroller.position(),{self.totalOffsetX + self.xMuzzleOffset2,self.yMuzzleOffset - (1 * self.crouchingQuery)}))
		
		local distPosX = toTarget[1]
		self.distPosX = distPosX
		--local sourcePosX = toTarget[2]
		--local distance = math.max(math.sqrt(toTarget[1] * toTarget[1] + toTarget[2] * toTarget[2]))
		--self.distance = distance
		
		--local xDistance = targetPosX - sourcePosX
        --local toTargetAngle = math.deg(math.acos(math.cos(distPosX/distance)))
		local toTargetAngle = toTarget[2]
		--sb.logInfo(sb.printJson(toTarget))
		--sb.logInfo(sb.printJson(distance))
		--sb.logInfo(sb.printJson(toTargetAngle))
		
		self.toTargetAngle = toTargetAngle
		
		self.actualToTargetAngle = vec2.angle(toTarget)
		
		local toTargetAngleTmp = math.deg(math.atan(toTarget[2]/toTarget[1]))
		self.toTargetAngleTmp = toTargetAngleTmp
		
		self.targetFound = true
		
		--if canPos[1] - pos[1] > 0 and mcontroller.facingDirection() > 0 then
		--if math.abs(toTargetAngleTmp) > 6 then
		if math.abs(toTargetAngleTmp) < self.trackingAngle then
		if toTarget[1] > 0 and mcontroller.facingDirection() > 0 then
		self.shouldFire = true
		elseif toTarget[1] < 0 and mcontroller.facingDirection() < 0 then
		self.shouldFire = true
		else
		self.shouldFire = false
		end
		end
		--elseif canPos[1] - pos[1] < 0 and mcontroller.facingDirection() < 0 then
		--self.shouldFire = true
		--else
		--self.shouldFire = false
		--end
		--end

        --if math.abs(toTargetAngle) > self.trackingLimit then
          --return
        --end

        --local rotateAngle = math.max(dt * -self.rotationRate, math.min(toTargetAngle, dt * self.rotationRate))

        --vel = vec2.rotate(vel, rotateAngle)
        --mcontroller.setVelocity(vel)

        break
      end
    end
  end
end

function damagePerShot()
  return ((self.baseDamage) * (self.baseDamageMultiplier or 1.0) )/ self.projectileCount
end

function energyPerShot()
  return self.energyPerShot * (self.energyUsageMultiplier or 1.0)
end

function uninit()

end
