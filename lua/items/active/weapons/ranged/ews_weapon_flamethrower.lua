require "/items/active/weapons/ranged/ews_weapon.lua"

FlamethrowerAttack = GunFire:new()

function FlamethrowerAttack:init()
  GunFire.init(self)

  self.active = false
end

function FlamethrowerAttack:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot) and not (self.weapon.reloading == 1) and (self.weapon.ammoAmount > 0) then
		if not self.active then 
			self:activate() 
		end
	elseif self.active then
		self:deactivate()
	end
end

function FlamethrowerAttack:activate()
  self.active = true
  animator.playSound("fireStart")
  animator.playSound("fireLoop", -1)
end

function FlamethrowerAttack:deactivate()
  self.active = false
  animator.stopAllSounds("fireStart")
  animator.stopAllSounds("fireLoop")
  animator.playSound("fireEnd")
end
