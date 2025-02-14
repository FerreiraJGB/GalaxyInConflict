require "/items/active/weapons/ranged/ews_weapon.lua"

ULTRAKILL = GunFire:new()

function ULTRAKILL:init()
  GunFire.init(self)
  
  if not storage.currentTime then storage.currentTime = world.time() end
  
  if math.abs(world.time() - storage.currentTime) > 0.9 and self:checkAmmoStatus() and (self.weapon.ammoAmount == 0) then --automatic reloading
	self:setState(self.reload6)
  end
end

function ULTRAKILL:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
  
  storage.currentTime = world.time()
  
  if (self.weapon.ammoAmount == 0) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) 
	and not self.switchingGuns == true then--this one is so guns don't reload when you "switch" it.
		self:setState(self.reload)
	end
end