require "/items/active/weapons/ranged/ews_weapon.lua"

LeverAction = GunFire:new()

function LeverAction:init()
  GunFire.init(self)
end

function LeverAction:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
end

function LeverAction:motion2()
  self.lasersightData = self.weapon:setStance(self.stances.motion2)
  self:laserSightConfig()
  

  if self.stances.motion2.duration then
    util.wait(self.stances.motion2.duration)
  end
  
  -- delayed projectile spawn for things like shotguns and bolt actions
  -- spawns delayed projectile after motion2's animation is done
  if self.ejectProjectileQuery == true then
  --self:setupNewValuesPostAmmo()
	if self:checkNeedRefreshAmmoList() then
		self:determineSingleLoadedAmmoVars(self.indexedValueHolder)
	end

  local shellOffset = config.getParameter("shellOffset")
  
  if shellOffset then
	local baseOffset = config.getParameter("baseOffset")
	local addedPos = vec2.add(shellOffset, baseOffset)
	world.spawnProjectile(config.getParameter( "ejectProjectileType" ), vec2.add(mcontroller.position(), activeItem.handPosition(addedPos)), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.inaccuracy),false,config.getParameter( "ejectProjectileTypeConfig" ) or {})
  else
	world.spawnProjectile(config.getParameter( "ejectProjectileType" ), self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.inaccuracy),false,config.getParameter( "ejectProjectileTypeConfig" ) or {})
  end
    if self:checkNeedRefreshAmmoList() then
		self:determineSingleLoadedAmmoVars()
    end
  end

  self:setState(self.motion3)
end

function LeverAction:motion3()
  self.lasersightData = self.weapon:setStance(self.stances.motion3)
  self:laserSightConfig()

  if self.stances.motion3.duration then
    util.wait(self.stances.motion3.duration)
  end

  self:setState(self.motion4)
end

function LeverAction:uninit()
	GunFire.uninit(self)
end