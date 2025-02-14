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
    and fireMode == "alt"
    and self.cooldownTimer == 0
	and not self.parryActive
	and status.resourcePositive("shieldStamina") then
    --and status.overConsumeResource("energy", self.energyUsage) then

    self.weapon:setStance(self.stances.parry)
	self.weapon:updateAim()
	self:setState(self.parry)

 
  elseif self.weapon.currentAbility == nil
    and self.cooldownTimer == 0
    --and not status.resourceLocked("energy")
    and shiftHeld then
    
    self:setState(self.charge)
  end
  
  if fireMode == "alt" then
	self.fireModeTmp = 1
  else
	self.fireModeTmp = 0
  end
 
  self.shiftHeld = shiftHeld
end

function Charge:parry()
  self.parryActive = true
  self.weapon:setStance(self.stances.parry)
  self.weapon:updateAim()
  self.parryTime = 999999
  status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = 99999}})
  status.setResource("shieldStamina", 1)
  --self.perfectBlockTime = 20 --ticks

  --status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = self.shieldHealth}})

  local blockPoly = animator.partPoly("parryShield", "shieldPoly")
  activeItem.setItemShieldPolys({blockPoly})

  animator.setAnimationState("parryShield", "active")
  --coroutine.yield()
  
  animator.playSound("guard")
  
  --
  local shieldHp = status.resource("shieldStamina")
  local damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 then
		if self.shieldTime <= self.perfectBlockTime and status.resource("shieldStamina") < shieldHp then
			animator.playSound("perfectBlock")
			
			self.shieldTime = 0
			status.setResource("shieldStamina", 1)
		else
			animator.playSound("parry")
		end
        --animator.playSound("parry")
        animator.setAnimationState("parryShield", "block")
        return
      end
    end
	
	shieldHp = status.resource("shieldStamina")
  end)
  
  
  
  local perfectParryGone = false
  self.shieldTime = 0
  self.fireModeTmp = 1
  util.wait(self.parryTime, function(dt)
  
	--Interrupt when running out of shield stamina
	if not status.resourcePositive("shieldStamina") then 
		self.cooldownTimer = 1.5
		animator.playSound("break") 
		return true 
	end
	if self.fireModeTmp == 0 then 
		self.cooldownTimer = self.cooldownTime
		return true 
	end
  
	self.shieldTime = self.shieldTime + self.dt
	if self.shieldTime <= self.perfectBlockTime then
		animator.setGlobalTag("directives", "?border=2;AACCFFFF;00000000")
	else
		animator.setGlobalTag("directives", "")
		if perfectParryGone == false then
			status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = self.shieldHealth}})
			perfectParryGone = true
		end
	end
	
	damageListener:update()
  end)
  self.parryActive = false
  animator.setGlobalTag("directives", "")

  
  
  --while self.fireModeTmp == 1 and status.resourcePositive("shieldStamina") do
  --  self.damageListener = damageListener("damageTaken", function(notifications)
  --  for _,notification in pairs(notifications) do
      --if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 then
	--  if notification.hitType == "ShieldHit" then
    --    animator.playSound("parry")
	--	animator.playSound("guard")
   --     animator.setAnimationState("parryShield", "block")
   --     return
   --   end
  --  end
  --end)
	--local blockPoly = animator.partPoly("parryShield", "shieldPoly")
   -- activeItem.setItemShieldPolys({blockPoly})
    --coroutine.yield()
  --end
  
  --self.cooldownTimer = self.cooldownTime
  activeItem.setItemShieldPolys({})
end

function Charge:charge()
	status.addEphemeralEffect("gic_superarmor", self.stances.windup.duration + 0.10 +  self.stances.fire.duration + 0.25) --0.75 + 0.2
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

		progress = math.min(1.0, progress + (self.dt / self.stances.windup.duration)) --1.0
		
		mcontroller.controlModifiers({runningSuppressed = true})
	end)
	self.weapon:setStance(self.stances.windup)
	self.weapon:updateAim()
	animator.playSound("shing")
	
	
	if mcontroller.onGround() and not mcontroller.zeroG() then 
		mcontroller.setVelocity({mcontroller.facingDirection()*-200,0}) -- negative20 
		mcontroller.controlParameters({
			airFriction = 0,
			groundFriction = 0,
			liquidFriction = 0--,
			--gravityEnabled = false
		})
	end
	util.wait(0.75, function()
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
		mcontroller.setXVelocity(mcontroller.facingDirection()*200) --200
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

function Charge:reset()
  animator.setAnimationState("parryShield", "inactive")
  status.clearPersistentEffects("broadswordParry")
  activeItem.setItemShieldPolys({})
end

function Charge:uninit()
  self:reset()
end
