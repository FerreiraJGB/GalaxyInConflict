require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime
  self.fireHeld = false
  self.weapon.cocked = not( self.fireType == "bolt" )
  
  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot) 
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and (not status.resourceLocked("energy") or self:useEnergy())
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
		if (self.weapon.altAmmoAmount > 0) and (self.weapon.cocked) then
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
		
		if (self.weapon.altAmmoAmount == 0) then
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

function GunFire:auto()
	self.weapon:setStance(self.stances.fire)

  animator.setPartTag("altMuzzleFlash", "variant", math.random(1, 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("altMuzzleFlash")
  animator.playSound("altFire")

  animator.setLightActive("muzzleFlash", true)
    self:fireProjectile()
	self.weapon.altAmmoAmount = self.weapon.altAmmoAmount - 1
	if self.weapon.ammoCasing then
		world.spawnItem(self.weapon.ammoCasing,mcontroller.position(),1,_)
	end
	activeItem.setInstanceValue("altAmmoAmount",self.weapon.altAmmoAmount)
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

  animator.setPartTag("altMuzzleFlash", "variant", math.random(1, 3))
  animator.setAnimationState("firing", "firing2", "fire")
  animator.burstParticleEmitter("altMuzzleFlash")
  animator.playSound("altFire")

  animator.setLightActive("muzzleFlash", true)
    self:fireProjectile()
	self.weapon.altAmmoAmount = self.weapon.altAmmoAmount - 1
	if self.weapon.ammoCasing then
		world.spawnItem(self.weapon.ammoCasing,mcontroller.position(),1,_)
	end
	activeItem.setInstanceValue("altAmmoAmount",self.weapon.altAmmoAmount)
	animator.setAnimationState("gunState","firing")
	
  
  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime/10
  self:setState(self.motion1)
end

function GunFire:burst()
  self.weapon:setStance(self.stances.fire)

  local shots = math.min(self.burstCount,self.weapon.altAmmoAmount)
  while shots > 0 and (status.overConsumeResource("energy", self:energyPerShot())or self:useEnergy()) do
	self.weapon.altAmmoAmount = self.weapon.altAmmoAmount - 1
	activeItem.setInstanceValue("altAmmoAmount",self.weapon.altAmmoAmount)
	if self.weapon.ammoCasing then
		world.spawnItem(self.weapon.ammoCasing,mcontroller.position(),1,_)
	end
    self:fireProjectile()
	
  animator.setPartTag("altMuzzleFlash", "variant", math.random(1, 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("altMuzzleFlash")
  animator.playSound("altFire")

  animator.setLightActive("muzzleFlash", true)
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
	animator.setAnimationState("gunState","reloading2")
	animator.playSound("switchAmmo2")
	self.weapon.altAmmoAmount = config.getParameter("altAmmoMax",1)
	
	self.altMagazineProjectile = config.getParameter("altMagazineProjectile")
	activeItem.setInstanceValue("altAmmoAmount",self.weapon.altAmmoAmount)
  if self.stances.reload.duration then
    util.wait(self.stances.reload.duration)
	world.spawnProjectile(self.altMagazineProjectile, firePosition or self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.inaccuracy),false,params)
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
