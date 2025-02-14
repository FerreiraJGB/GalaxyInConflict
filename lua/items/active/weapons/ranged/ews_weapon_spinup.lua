require "/items/active/weapons/ranged/ews_weapon.lua"

SpinupFire = GunFire:new()

function SpinupFire:init()
  GunFire.init(self)
  self.spinupFireRate = 0.05
  self.spinupTimerMax = 0.25 + 0
  self.spinupTimer = self.spinupTimerMax

  --mcontroller.controlModifiers({runningSuppressed = false}) exp. feature
end

function SpinupFire:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
  
  self.spinupTimer = math.max(0, self.spinupTimer - self.dt)

  
  if self.spinupTimer == 0 then
	--self.spinupFireRate = 0
	if self.spinupFireRate > 0 then
		self.spinupFireRate = self.spinupFireRate - 0.025
	end
	if self.spinupFireRate < 0 then
		self.spinupFireRate = 0
		--mcontroller.controlModifiers({runningSuppressed = false}) exp. feature
	end
	self.spinupTimer = self.spinupTimerMax
  end

end

function SpinupFire:auto()
  GunFire.auto(self)
  
  --if not self.spinupFireRate == 0.2 or not self.spinupFireRate > 0.2 then
  self.spinupFireRate = self.spinupFireRate + 0.0125
  --end
  if self.spinupFireRate > 0.15 then
  self.spinupFireRate = 0.15
  end
  self.spinupTimer = self.spinupTimerMax + 0.1
  --mcontroller.controlModifiers({runningSuppressed = true}) exp. feature
  self.cooldownTimer = self.fireTime - self.spinupFireRate
end
