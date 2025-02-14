require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Base gun fire ability
FireBreath = WeaponAbility:new()

function FireBreath:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime

  if (config.getParameter("shouldConsume") == true) then
	item.consume(1)
	activeItem.setInstanceValue("shouldConsume",false)
  end
  self.weapon.onLeaveAbility = function()
	if (self.shouldConsume == true) then
		--item.consume(1)
	end
	
    self.weapon:setStance(self.stances.idle)
  end
end

function FireBreath:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  --if animator.animationState("firing") ~= "fire" then
    --animator.setLightActive("muzzleFlash", false)
  --end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    --and not status.resourceLocked("energy")
    --and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
	then

    --if status.overConsumeResource("energy", self:energyPerShot()) then
      self:setState(self.windup)
    --end
  end
end

function FireBreath:windup()
	self.weapon:setStance(self.stances.idle)
	local progress = 0
	util.wait(self.stances.idle.duration, function()
		local from = self.stances.idle.weaponOffset or {0,0}
		local to = self.stances.windup.weaponOffset or {0,0}
		self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.idle.weaponRotation, self.stances.windup.weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.idle.armRotation, self.stances.windup.armRotation))

		progress = math.min(1.0, progress + (self.dt / self.stances.idle.duration))
	end)
	
	self.weapon:setStance(self.stances.windup)
	animator.playSound("drink")
	if self.stances.windup.duration then
		util.wait(self.stances.windup.duration)
	end
	
	self.weapon:setStance(self.stances.windupFin)
	if self.stances.windupFin.duration then
		util.wait(self.stances.windupFin.duration)
	end
	
	self:setState(self.fire)
end

function FireBreath:fire()
  self.weapon:setStance(self.stances.fire)

  self:fireProjectile()
  animator.playSound("fire")
  --self:muzzleFlash()

  activeItem.setInstanceValue("shouldConsume",true)
  if self.stances.fire.duration then
	local cd = 0.0
	local maxcd = 0.1
    util.wait(self.stances.fire.duration, function ()
		cd = math.max(0,cd-self.dt)
		
		if cd == 0 then
			self:fireProjectile()
			cd = maxcd
		end
	end)
  end
  item.consume(1)
  activeItem.setInstanceValue("shouldConsume",false)

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function FireBreath:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  local progress = 0
  util.wait(self.stances.cooldown.duration, function()
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.cooldown.duration))
  end)
end

function FireBreath:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end

function FireBreath:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  --params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    projectileId = world.spawnProjectile(
        projectileType,
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(inaccuracy or self.inaccuracy),
        false,
        params
      )
  end
  return projectileId
end

function FireBreath:firePosition()
  local crouching = 0
  if mcontroller.crouching() == true then
	crouching = 1
  else
	crouching = 0
  end
  
  --ignore actual muzzle offset position based off weapon rotation for now because that's easier to do atm.
  local muzzleOffset = {}
  muzzleOffset[1] = self.weapon.muzzleOffset[1]
  muzzleOffset[2] = self.weapon.muzzleOffset[2]
  
  if mcontroller.facingDirection() == 1 then
	muzzleOffset[1] = muzzleOffset[1] * -1
  end
  muzzleOffset[2] = muzzleOffset[2] - crouching
  
  return vec2.add(mcontroller.position(), muzzleOffset)--activeItem.handPosition(self.weapon.muzzleOffset))
end

function FireBreath:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function FireBreath:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function FireBreath:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier")-- / self.projectileCount
end

function FireBreath:uninit()
end
