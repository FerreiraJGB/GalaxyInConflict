--require "/scripts/util.lua"
--require "/scripts/status.lua"

Charge = {}

function Charge:init()
  self.cooldownTimer = self.cooldownTime
end

function Charge:update()


  self.cooldownTimer = 0
  
  
  if self.cooldownTimer == 0
    and shiftHeld then
    
    self:setState(self.charge)
  end
 
  self.shiftHeld = shiftHeld
end

function Charge:charge()
	status.addEphemeralEffect("gic_superarmor", 1)
    local progress = 0
--	animator.playSound("shing")
	
	
	if mcontroller.onGround() and not mcontroller.zeroG() then 
		mcontroller.setVelocity({mcontroller.facingDirection()*-20,0}) 
		mcontroller.controlParameters({
			airFriction = 0,
			groundFriction = 0,
			liquidFriction = 0
		})
	end
	util.wait(0.75, function()
		mcontroller.controlModifiers({movementSuppressed = true})
	end)
	
	animator.playSound("heavyAttackSwing")
	
	if mcontroller.onGround() and not mcontroller.zeroG() then 
		mcontroller.controlParameters({
			airFriction = 0,
			groundFriction = 0,
			liquidFriction = 0
		})
		mcontroller.setXVelocity(mcontroller.facingDirection()*200)
	end
	
	util.wait(1, function()
    local damageArea = partDamageArea("swoosh")
		--mcontroller.controlModifiers({movementSuppressed = true})
		if mcontroller.onGround() and not mcontroller.zeroG() then 
			mcontroller.controlParameters({
				airFriction = 0,
				groundFriction = 0,
				liquidFriction = 0
			})
		end
	end)
	
	self.cooldownTimer = self.cooldownTime * 1
end

function Charge:uninit()
end
