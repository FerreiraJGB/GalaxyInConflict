require "/scripts/util.lua"
require "/scripts/status.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/interp.lua"

Charge = WeaponAbility:new()

function Charge:init()
  self.cooldownTimer = self.cooldownTime
end

function Charge:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  
  if self.weapon.currentAbility == nil
    and self.cooldownTimer == 0
    --and not status.resourceLocked("energy")
    and shiftHeld then
    
    self:setState(self.charge)
  end
 
  self.shiftHeld = shiftHeld
end

function Charge:charge()
	status.addEphemeralEffect("gic_peacekeeper_rapier_dodge",1)
	status.addEphemeralEffect("gic_superarmor", self.stances.windup.duration + 0.0 +  self.stances.fire.duration + 0.25)
	animator.playSound("heavyAttack")
	self.weapon:setStance(self.stances.idle)
	self.weapon:updateAim()
    local progress = 0
	util.wait(self.stances.windup.duration, function()
		local from = self.stances.idle.weaponOffset or {0,0}
		local to = self.stances.windup.weaponOffset or {0,0}
		self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.idle.weaponRotation, self.stances.windup.weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.idle.armRotation, self.stances.windup.armRotation))

		progress = math.min(1.0, progress + (self.dt / self.stances.windup.duration))
		
		mcontroller.controlModifiers({runningSuppressed = true})
	end)
	self.weapon:setStance(self.stances.windup)
	self.weapon:updateAim()
	animator.playSound("shing")
	
	
	if mcontroller.onGround() and not mcontroller.zeroG() then 
		mcontroller.setVelocity({mcontroller.facingDirection()*200,0}) 
		mcontroller.controlParameters({
			airFriction = 0,
			groundFriction = 0,
			liquidFriction = 0--,
			--gravityEnabled = false
		})
	end
	util.wait(0.25, function()
		mcontroller.controlModifiers({movementSuppressed = true})
	end)
	
	self.weapon:setStance(self.stances.fire)
	self.weapon:updateAim()
	
	self.damageListener = damageListener("inflictedDamage", function(notifications)
      for _, notification in pairs(notifications) do
        if notification.healthLost > 0 and notification.damageSourceKind == self.damageConfig.damageSourceKind then
          animator.playSound("heavyAttackHit")
          return
        end
      end
    end)
	
	animator.setAnimationState("swoosh", "fire")
	animator.playSound("heavyAttackSwing")
	
	if mcontroller.onGround() and not mcontroller.zeroG() then 
		--mcontroller.setVelocity({mcontroller.facingDirection()*55,0})
		mcontroller.controlParameters({
			airFriction = 0,
			groundFriction = 0,
			liquidFriction = 0--,
			--gravityEnabled = false
		})
		mcontroller.setXVelocity(mcontroller.facingDirection()*150) --200
	end
	
	util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("swoosh")
		--mcontroller.controlModifiers({movementSuppressed = true})
		if mcontroller.onGround() and not mcontroller.zeroG() then 
			--mcontroller.setVelocity({mcontroller.facingDirection()*10,0})
			--mcontroller.setXVelocity(mcontroller.facingDirection()*50)
			mcontroller.controlParameters({
				airFriction = 0,
				groundFriction = 0,
				liquidFriction = 0--,
				--gravityEnabled = false
			})
		end
    
		self.weapon:setDamage(self.damageConfig, damageArea)
		self.damageListener:update()
	end)
	
	self.damageListener = nil
	
	self.cooldownTimer = self.cooldownTime * 1
end

function Charge:uninit()
end
