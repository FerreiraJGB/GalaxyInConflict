require "/items/active/weapons/ranged/ews_weapon.lua"

GunFire10 = GunFire:new()

function GunFire10:init()
  GunFire.init(self)
end

function GunFire10:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
end

function GunFire10:partReload5()
  self.lasersightData = self.weapon:setStance(self.stances.partreload5)
  self:laserSightConfig()

  if self.stances.partreload5.duration then
    util.wait(self.stances.partreload5.duration)
  end

  self:setState(self.partReload6modif)
end

function GunFire10:partReload6modif()
  self.lasersightData = self.weapon:setStance(self.stances.partreload6)
  self:laserSightConfig()

  if self.stances.partreload6.duration then
    util.wait(self.stances.partreload6.duration)
  end

  self:setState(self.partReload7)
end

function GunFire10:partReload7()
  self.lasersightData = self.weapon:setStance(self.stances.partreload7)
  self:laserSightConfig()

  if self.stances.partreload7.duration then
    util.wait(self.stances.partreload7.duration)
  end

  self:setState(self.partReload8)
end

function GunFire10:partReload8()
  self.lasersightData = self.weapon:setStance(self.stances.partreload8)
  self:laserSightConfig()

  if self.stances.partreload8.duration then
    util.wait(self.stances.partreload8.duration)
  end

  self:setState(self.partReload9)
end

function GunFire10:partReload9()
  self.lasersightData = self.weapon:setStance(self.stances.partreload9)
  self:laserSightConfig()

  if self.stances.partreload9.duration then
    util.wait(self.stances.partreload9.duration)
  end

  self:setState(self.partReload10)
end

function GunFire10:partReload10()
  -- actually "loads" in the bullets into the magazine here so you can't start the reload, double tap q, and have a fully loaded gun.
  self.lasersightData = self.weapon:setStance(self.stances.partreload10)
  self:laserSightConfig()
  
  self:reloadFunction(1)
  
  --gimped bugfix
  --sb.logInfo(config.getParameter("ammoAmount"))
  --if config.getParameter("ammoAmount") == config.getParameter("ammoMax") then
	--self.weapon.ammoAmount = config.getParameter("ammoMax",1) + (1 or 0)
	--activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	--sb.logInfo(config.getParameter("ammoAmount"))
  --end
  --sb.logInfo(config.getParameter("ammoAmount"))
  -----------------------
  
  if type(config.getParameter("consumeAmmoType")) == "table" and self.consumeAmmoModule and config.getParameter("magazineImages") then
	local magazineImages = config.getParameter("magazineImages")
	local activeIndex = config.getParameter("activeIndex",1)
	
	if self.npcGun == true or self.infAmmo then
		magazineImages = magazineImages[config.getParameter("defaultAmmoIndexValue") or 1]
	else
		magazineImages = magazineImages[activeIndex]
	end
	animator.setGlobalTag("magazineImage", magazineImages)
  
	if not (self.oldIndex == activeIndex) then
		if (not self.singleBulletLoad) or (self.singleBulletLoad and magazineImages) then
			self:setupInventoryIcon()
		end
	end
	self.oldIndex = activeIndex
  end

  self.weapon.reloading = 0
  animator.setAnimationState("gunState","armed")
  animator.setParticleEmitterActive("hotsmoke", false )
  animator.setParticleEmitterActive("muzzleFlash", false)
  self.lasersightData = self.weapon:setStance(self.stances.idle)
  --self:setState(self.cooldown)
end

function GunFire10:reload5()
  self.lasersightData = self.weapon:setStance(self.stances.reload5)
  self:laserSightConfig()

  if self.stances.reload5.duration then
    util.wait(self.stances.reload5.duration)
  end

  self:setState(self.reload6modif)
end

function GunFire10:reload6modif()
  self.lasersightData = self.weapon:setStance(self.stances.reload6)
  self:laserSightConfig()

  if self.stances.reload6.duration then
    util.wait(self.stances.reload6.duration)
  end

  self:setState(self.reload7)
end

function GunFire10:reload7()
  self.lasersightData = self.weapon:setStance(self.stances.reload7)
  self:laserSightConfig()

  if self.stances.reload7.duration then
    util.wait(self.stances.reload7.duration)
  end

  self:setState(self.reload8)
end

function GunFire10:reload8()
  self.lasersightData = self.weapon:setStance(self.stances.reload8)
  self:laserSightConfig()

  if self.stances.reload8.duration then
    util.wait(self.stances.reload8.duration)
  end

  self:setState(self.reload9)
end

function GunFire10:reload9()
  self.lasersightData = self.weapon:setStance(self.stances.reload9)
  self:laserSightConfig()

  if self.stances.reload9.duration then
    util.wait(self.stances.reload9.duration)
  end

  self:setState(self.reload10)
end

function GunFire10:reload10()
  -- actually "loads" in the bullets into the magazine here so you can't start the reload, double tap q, and have a fully loaded gun.
  self.lasersightData = self.weapon:setStance(self.stances.reload10)
  self:laserSightConfig()
  
  if not config.getParameter( "singleBulletLoad" ) == true then -- prevents extra ammo being consumed
  self:reloadFunction()
  end
  
  if type(config.getParameter("consumeAmmoType")) == "table" and self.consumeAmmoModule and config.getParameter("magazineImages") then
	local magazineImages = config.getParameter("magazineImages")
	local activeIndex = config.getParameter("activeIndex",1)
	
	if self.npcGun == true or self.infAmmo then
		magazineImages = magazineImages[config.getParameter("defaultAmmoIndexValue") or 1]
	else
		magazineImages = magazineImages[activeIndex]
	end
	animator.setGlobalTag("magazineImage", magazineImages)
  
	if not (self.oldIndex == activeIndex) then
		if (not self.singleBulletLoad) or (self.singleBulletLoad and magazineImages) then
			self:setupInventoryIcon()
		end
	end
	self.oldIndex = activeIndex
  end
  

  if self.stances.reload10.duration then
    util.wait(self.stances.reload10.duration)
  end

  self.weapon.reloading = 0
  animator.setAnimationState("gunState","armed")
  animator.setParticleEmitterActive("hotsmoke", false )
  animator.setParticleEmitterActive("muzzleFlash", false)
  self.lasersightData = self.weapon:setStance(self.stances.idle)
  self:laserSightConfig()
  --self:setState(self.cooldown)
end
