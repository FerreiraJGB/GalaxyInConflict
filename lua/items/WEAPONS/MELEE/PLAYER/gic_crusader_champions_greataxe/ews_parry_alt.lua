require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/weapon.lua"

Parry = WeaponAbility:new()

function Parry:init()
  self.cooldownTimer = 0
  --self.parryTimeTemp = self.parryTime
end

function Parry:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and fireMode == "alt"
	and not self.parryActive
    and self.cooldownTimer == 0 
	and status.resourcePositive("shieldStamina") then
    --and status.overConsumeResource("energy", self.energyUsage) then

    self.weapon:setStance(self.stances.parry)
	self.weapon:updateAim()
	self:setState(self.parry)

 
  elseif self.weapon.currentAbility == nil
    and shiftHeld
    and self.cooldownTimer == 0 then
	self:setState(self.heavyslash)
  end
  
  if fireMode == "alt" then
	self.fireModeTmp = 1
  else
	self.fireModeTmp = 0
  end
end

function Parry:heavyslash()
	animator.playSound("heavyAttack")
	status.addEphemeralEffect("gic_superarmor", self.stances.windup.duration + self.stances.windup2.duration +  self.stances.windup3.duration + self.stances.preslash.duration + self.stances.fire.duration + 0.1 + 0.15)
	
	self.weapon:setStance(self.stances.windup)
	util.wait(self.stances.windup.duration, function()
		mcontroller.controlModifiers({runningSuppressed = true})
	end)
	
	local progress = 0
	util.wait(self.stances.windup2.duration, function()
		local from = self.stances.windup.weaponOffset or {0,0}
		local to = self.stances.windup2.weaponOffset or {0,0}
		self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.windup.weaponRotation, self.stances.windup2.weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.windup.armRotation, self.stances.windup2.armRotation))

		progress = math.min(1.0, progress + (self.dt / self.stances.windup2.duration))
		
		mcontroller.controlModifiers({runningSuppressed = true})
	end)
	
	local progress = 0
	util.wait(self.stances.windup3.duration, function()
		local from = self.stances.windup2.weaponOffset or {0,0}
		local to = self.stances.windup3.weaponOffset or {0,0}
		self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.windup2.weaponRotation, self.stances.windup3.weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.windup2.armRotation, self.stances.windup3.armRotation))

		progress = math.min(1.0, progress + (self.dt / self.stances.windup3.duration))
		
		mcontroller.controlModifiers({runningSuppressed = true})
	end)
	
	util.wait(0.1, function()
		mcontroller.controlModifiers({runningSuppressed = true})
	end)
	
	animator.playSound("shing")
	local progress = 0
	util.wait(self.stances.preslash.duration, function()
		local from = self.stances.windup3.weaponOffset or {0,0}
		local to = self.stances.preslash.weaponOffset or {0,0}
		self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.windup3.weaponRotation, self.stances.preslash.weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.windup3.armRotation, self.stances.preslash.armRotation))

		progress = math.min(1.0, progress + (self.dt / self.stances.preslash.duration))
		
		mcontroller.controlModifiers({runningSuppressed = true})
	end)
	
	util.wait(0.15, function()
		mcontroller.controlModifiers({movementSuppressed = true})
	end)
	
	
	--self.weapon:setStance(self.stances.windup2)
	--util.wait(self.stances.windup2.duration)
	
	--self.weapon:setStance(self.stances.windup3)
	--util.wait(self.stances.windup3.duration)
	
	self.weapon:setStance(self.stances.preslash)
	util.wait(self.stances.preslash.duration)
	
	self.weapon:setStance(self.stances.fire)
	animator.setAnimationState("swoosh", "fire")
	animator.playSound("heavyAttackSwing")

  --status.addEphemeralEffect("invulnerable", self.stances.fire.duration + 0.05)
	self.damageListener = damageListener("inflictedDamage", function(notifications)
      for _, notification in pairs(notifications) do
        if notification.healthLost > 0 and notification.damageSourceKind == self.damageConfig.damageSourceKind then
          animator.playSound("heavyAttackHit")
          return
        end
      end
    end)

	mcontroller.setVelocity({mcontroller.facingDirection()*35,5})
	util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("swoosh")
		mcontroller.controlModifiers({movementSuppressed = true})
    
		self.weapon:setDamage(self.damageConfig, damageArea)
		self.damageListener:update()
	end)
	
	self.damageListener = nil
	
	self.cooldownTimer = self.cooldownTime * 0.5
end

function Parry:parry()
  self.parryActive = true
  self.weapon:setStance(self.stances.parry)
  self.weapon:updateAim()
  self.parryTime = 999999

  status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = self.shieldHealth}})

  local blockPoly = animator.partPoly("parryShield", "shieldPoly")
  activeItem.setItemShieldPolys({blockPoly})

  animator.setAnimationState("parryShield", "active")
  --coroutine.yield()
  
  animator.playSound("guard")
  
  --
  
  local damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 then
        animator.playSound("parry")
        animator.setAnimationState("parryShield", "block")
        return
      end
    end
  end)
  
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

  damageListener:update()
  end)

  
  
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
  self.parryActive = false
end

function Parry:reset()
  animator.setAnimationState("parryShield", "inactive")
  status.clearPersistentEffects("broadswordParry")
  activeItem.setItemShieldPolys({})
end

function Parry:uninit()
  self:reset()
end
