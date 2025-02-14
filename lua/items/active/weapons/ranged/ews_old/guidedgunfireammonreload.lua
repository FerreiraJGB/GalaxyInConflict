require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/weaponammo.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)

  self.rocketIds = {}

  self.cooldownTimer = self.fireTime
  self.fireHeld = false
  self.weapon.cocked = not( self.fireType == "bolt" )
  
  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.rocketIds = util.filter(self.rocketIds, world.entityExists)
  local rocketTargetPosition = activeItem.ownerAimPosition()
  local rocketTargetDirection = nil
  
  if self.laserGuideLength then
    -- Shoot a ray through the rocketTargetPosition and aim the rocket towards
    -- the nearest collision
    local target = self:findLaserTarget()
    rocketTargetPosition = target.position
    rocketTargetDirection = target.direction
  end
  
  for _,rocketId in pairs(self.rocketIds) do
    world.callScriptedEntity(rocketId, "setTarget", rocketTargetPosition)
    world.callScriptedEntity(rocketId, "setTargetDirection", rocketTargetDirection)
  end
  

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  
  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot) 
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and (not status.resourceLocked("energy") or self:useEnergy())
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
		if (self.weapon.ammoAmount > 0) and (self.weapon.cocked) then
			if self.fireType == "auto" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
				self:setState(self.auto)
			elseif not self.fireHeld then
				if self.fireType == "semi" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
					self:setState(self.semi)
				end
			elseif self.fireType == "bolt" then
				self.weapon.cocked = false
				self:setState(self.semi)
			elseif self.fireType == "burst" then
				self:setState(self.burst)
			end
		else
			if not self.fireHeld and self.weapon.cocked then
				if self.fireType == "bolt" and self.weapon.cocked then
					self.weapon.cocked = false
				end
				animator.playSound("empty")	
				self:setState(self.cooldown)
			end
		end
		
		if (self.weapon.ammoAmount == 0) then
			if self.fireType == "auto" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
				self:setState(self.reload)
			elseif not self.fireHeld then
				if self.fireType == "semi" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
					self:setState(self.reload)
				end
			elseif self.fireType == "bolt" then
				self.weapon.cocked = false
				self:setState(self.reload)
			elseif self.fireType == "burst" then
				self:setState(self.reload)
			end
			end
		
  end
  self.fireHeld = self.fireMode == (self.activatingFireMode or self.abilitySlot)
end

function GunFire:findLaserTarget()
  local ownerPosition = world.entityPosition(activeItem.ownerEntityId())
  local muzzlePosition = vec2.add(ownerPosition, activeItem.handPosition(self.weapon.muzzleOffset))

  local aimVector = vec2.norm(world.distance(activeItem.ownerAimPosition(), muzzlePosition))
  local lineEnd = vec2.mul(aimVector, self.laserGuideLength)
  local blocks = world.collisionBlocksAlongLine(muzzlePosition, vec2.add(muzzlePosition, lineEnd))

  if #blocks == 0 then
    return { direction = aimVector }
  end

  local minDistance = self.laserGuideLength
  local nearestCollision = nil
  for _,block in pairs(blocks) do
    local distance = vec2.mag(world.distance(block, muzzlePosition))
    if distance < minDistance then
      minDistance = distance
      nearestCollision = block
    end
  end
  return { position = nearestCollision }
end

function GunFire:auto()
	self.weapon:setStance(self.stances.fire)

  table.insert(self.rocketIds, self:fireProjectile())
    self:muzzleFlash()
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	if self.weapon.ammoCasing then
		world.spawnItem(self.weapon.ammoCasing,mcontroller.position(),1,_)
	end
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	animator.setAnimationState("gunState","firing")
  
  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.motion1)
end

function GunFire:motion1()
  self.weapon:setStance(self.stances.motion1)

  if self.stances.motion1.duration then
    util.wait(self.stances.motion1.duration)
  end

  self:setState(self.motion2)
end

function GunFire:motion2()
  self.weapon:setStance(self.stances.motion2)

  if self.stances.motion2.duration then
    util.wait(self.stances.motion2.duration)
  end

  self:setState(self.motion3)
end

function GunFire:motion3()
  self.weapon:setStance(self.stances.motion3)

  if self.stances.motion3.duration then
    util.wait(self.stances.motion3.duration)
  end

  self:setState(self.motion4)
end

function GunFire:motion4()
  self.weapon:setStance(self.stances.motion4)

  if self.stances.motion4.duration then
    util.wait(self.stances.motion4.duration)
  end

  self:setState(self.motion5)
end

function GunFire:motion5()
  self.weapon:setStance(self.stances.motion5)

  if self.stances.motion5.duration then
    util.wait(self.stances.motion5.duration)
  end

  self:setState(self.motion6)
end

function GunFire:motion6()
  self.weapon:setStance(self.stances.motion6)

  if self.stances.motion6.duration then
    util.wait(self.stances.motion6.duration)
  end

  self:setState(self.cooldown)
end
function GunFire:semi()
	self.weapon:setStance(self.stances.fire)

  table.insert(self.rocketIds, self:fireProjectile())
    self:muzzleFlash()
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	if self.weapon.ammoCasing then
		world.spawnItem(self.weapon.ammoCasing,mcontroller.position(),1,_)
	end
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	animator.setAnimationState("gunState","firing")
  
  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime/10
  self:setState(self.motion1)
end

function GunFire:burst()
  self.weapon:setStance(self.stances.fire)

  local shots = math.min(self.burstCount,self.weapon.ammoAmount)
  while shots > 0 and (status.overConsumeResource("energy", self:energyPerShot())or self:useEnergy()) do
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	if self.weapon.ammoCasing then
		world.spawnItem(self.weapon.ammoCasing,mcontroller.position(),1,_)
	end
  table.insert(self.rocketIds, self:fireProjectile())
    self:muzzleFlash()
    shots = shots - 1

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))
	
	animator.setAnimationState("gunState","firing")

    util.wait(self.burstTime)
  end

  self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function GunFire:reload()
	self.weapon:setStance(self.stances.reload)
	animator.setAnimationState("gunState","reloading")
	animator.playSound("switchAmmo")
	self.weapon.ammoAmount = config.getParameter("ammoMax",1)
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
  if self.stances.reload.duration then
    util.wait(self.stances.reload.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.reload1)
end

function GunFire:reload1()
  self.weapon:setStance(self.stances.reload1)

  if self.stances.reload1.duration then
    util.wait(self.stances.reload1.duration)
  end

  self:setState(self.reload2)
end

function GunFire:reload2()
  self.weapon:setStance(self.stances.reload2)

  if self.stances.reload2.duration then
    util.wait(self.stances.reload2.duration)
  end

  self:setState(self.reload3)
end

function GunFire:reload3()
  self.weapon:setStance(self.stances.reload3)

  if self.stances.reload3.duration then
    util.wait(self.stances.reload3.duration)
  end

  self:setState(self.reload4)
end

function GunFire:reload4()
  self.weapon:setStance(self.stances.reload4)

  if self.stances.reload4.duration then
    util.wait(self.stances.reload4.duration)
  end

  self:setState(self.reload5)
end

function GunFire:reload5()
  self.weapon:setStance(self.stances.reload5)

  if self.stances.reload5.duration then
    util.wait(self.stances.reload5.duration)
  end

  self:setState(self.reload6)
end

function GunFire:reload6()
  self.weapon:setStance(self.stances.reload6)

  if self.stances.reload6.duration then
    util.wait(self.stances.reload6.duration)
  end

  self:setState(self.cooldown)
end
function GunFire:cooldown()
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

function GunFire:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end


function GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
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

function GunFire:useEnergy()
	return not self.energyUsage
end

function GunFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function GunFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function GunFire:energyPerShot()
  return (self.energyUsage or 0) * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function GunFire:damagePerShot()
  return ((self.baseDamage or (self.baseDps * self.fireTime))+self.bonusDps) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function GunFire:uninit()
end
