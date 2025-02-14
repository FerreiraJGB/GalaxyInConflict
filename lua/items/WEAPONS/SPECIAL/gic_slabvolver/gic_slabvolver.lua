require "/items/active/weapons/ranged/ews_weapon.lua"

ULTRAKILL = GunFire:new()

function ULTRAKILL:init()
  GunFire.init(self)
end

function ULTRAKILL:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
  
  if (self.weapon.ammoAmount == 0) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) 
	and not self.switchingGuns == true then--this one is so guns don't reload when you "switch" it.
		self:setState(self.reload)
	end
end