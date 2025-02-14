require "/items/active/weapons/ranged/ews_weapon_throwables.lua"

WiredExplosive = GunFire:new()

function WiredExplosive:init()
  GunFire.init(self)
end


function WiredExplosive:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  
  if shiftHeld and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) then
	self:setState(self.reload)
  end
  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end
  
  if self.fireMode == (self.activatingFireMode or self.abilitySlot) 
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0 then
    --and (not status.resourceLocked("energy") or self:useEnergy())
    --and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
		if (self.weapon.ammoAmount > 0) then
			if self.fireType == "auto" then
				self:setState(self.auto)
			elseif self.fireType == "semi" then
				if not self.fireHeld then
					self:setState(self.semi)
				end
			end
		end
		if (self.weapon.ammoAmount == 0) then
			if self.fireType == "auto" then
				self:setState(self.reload)
			elseif self.fireType == "semi" then
				if not self.fireHeld then
					self:setState(self.reload)
				end
			end
		end
		
  end
end

function WiredExplosive:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
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
  if projectileId then
    --storage.activeProjectiles[#storage.activeProjectiles + 1] = projectileId
	activeItem.callOtherHandScript("addNewProjectile", projectileId)
  end
  
end