require "/scripts/util.lua"
require "/scripts/status.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/interp.lua"

Parry = WeaponAbility:new()

function Parry:init()
  self.cooldownTimer = 0
  self.chargeCooldownTimer = 0
  animator.setGlobalTag("directives", "")
  --self.parryTimeTemp = self.parryTime
end

-- local altHeld = false
-- local altHoldTime = 0
-- local altHoldTmp = false

function Parry:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  self.chargeCooldownTimer = math.max(0, self.chargeCooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and fireMode == "alt"
    and self.cooldownTimer == 0 
	and not self.parryActive
	and status.resourcePositive("shieldStamina") then
    --and status.overConsumeResource("energy", self.energyUsage) then

    self.weapon:setStance(self.stances.parry)
	self.weapon:updateAim()
	self:setState(self.parry)

 
  -- elseif self.weapon.currentAbility == nil
    -- and fireMode == "none"
    -- and self.cooldownTimer == 0 
	-- and altHoldTime > 0
	-- and status.stat("gic_hiltbash_cooldown") == 0 then -- tap alt
  
	-- self:setState(self.hiltBash)
	
  elseif -- altHoldTmp == true -- hold alt
	self.weapon.currentAbility == nil
	and self.chargeCooldownTimer == 0
	-- and altHoldTime == 0 
	--and self.fireMode == "alt" then
	and shiftHeld then
  
	-- altHoldTmp = false
	self:setState(self.chargeHiltBash)
  end
  
  -- altHoldTime = math.max(0, altHoldTime - self.dt)
  -- if self.fireMode == "alt" and altHoldTmp == false then
	-- altHoldTime = 0.125 --hold timer
	-- altHoldTmp = true
  -- end
  
  -- if altHoldTmp == true and altHoldTime == 0 and self.fireMode == "none" then
	-- altHoldTmp = false
  -- end
  
  
  
  if self.fireMode == "alt" then
	self.fireModeTmp = 1
  else
	self.fireModeTmp = 0
  end
end

function Parry:parry()
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
  animator.setGlobalTag("directives", "")
  self.parryActive = false
  
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

function Parry:hiltBash()
	status.addEphemeralEffect("gic_hiltbash_cooldown")
	
	self.weapon:setStance(self.stances.windup)
	util.wait(self.stances.windup.duration)
	
	self.weapon:setStance(self.stances.fire)
	animator.setAnimationState("swoosh", "fire4")
	animator.playSound("hiltSmash")
	
	self.damageListener = damageListener("inflictedDamage", function(notifications)
      for _, notification in pairs(notifications) do
        if notification.healthLost > 0 and notification.damageSourceKind == self.damageConfig.damageSourceKind then
          animator.playSound("hiltSmashHit")
          return
        end
      end
    end)
	
	util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("swoosh")
		mcontroller.controlModifiers({movementSuppressed = true})
    
		self.weapon:setDamage(self.damageConfig, damageArea)
		self.damageListener:update()
	end)
	
	self.damageListener = nil
	
	altHoldTmp = false
	self.cooldownTimer = self.cooldownTime * 2.0
end

function Parry:interpStance(initStance,targetStance)
	local progress = 0
	util.wait(self.stances[initStance].duration, function()
		local from = self.stances[targetStance].weaponOffset or {0,0}
		local to = self.stances[initStance].weaponOffset or {0,0}
		self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances[initStance].weaponRotation, self.stances[targetStance].weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances[initStance].armRotation, self.stances[targetStance].armRotation))

		progress = math.min(1.0, progress + (self.dt / self.stances[initStance].duration))
		
		mcontroller.controlModifiers({runningSuppressed = true})
	end)
end

function Parry:chargeHiltBash()
	self.weapon:setStance(self.stances.idle)
	--util.wait(0.15, function()
		--mcontroller.controlModifiers({runningSuppressed = true})
	--end)
	--self:interpStance("idle","chargeWindup1")
	self.weapon:setStance(self.stances.chargeWindup1)
	util.wait(0.35, function()
		mcontroller.controlModifiers({runningSuppressed = true})
	end)
	self:interpStance("chargeWindup1","chargeWindup3")
	
	--self.weapon:setStance(self.stances.chargeWindup2)
	--util.wait(self.stances.chargeWindup2.duration)
	--util.wait(0.2, function()
		--mcontroller.controlModifiers({runningSuppressed = true})
	--end)
	--self:interpStance("chargeWindup2","chargeWindup3")
	
	animator.playSound("shing")
	if mcontroller.onGround() and not mcontroller.zeroG() then 
		mcontroller.setVelocity({mcontroller.facingDirection()*-15,0}) 
	end
	
	self.weapon:setStance(self.stances.chargeWindup3)
	status.addEphemeralEffect("gic_superarmor", self.stances.chargeWindup3.duration + self.stances.chargeFire.duration)
	util.wait(self.stances.chargeWindup3.duration, function()
		mcontroller.controlModifiers({movementSuppressed = true})
	end)
	
	if mcontroller.onGround() and not mcontroller.zeroG() then 
		mcontroller.setVelocity({mcontroller.facingDirection()*30,0}) 
	end
	self.weapon:setStance(self.stances.chargeFire)
	animator.setAnimationState("swoosh", "fire4")
	animator.playSound("hiltSmash")
	
	self.damageListener = damageListener("inflictedDamage", function(notifications)
      for _, notification in pairs(notifications) do
        if notification.healthLost > 0 and notification.damageSourceKind == self.damageConfig.damageSourceKind then
          animator.playSound("hiltSmashHit")
          return
        end
      end
    end)
	
	util.wait(self.stances.chargeFire.duration, function()
    local damageArea = partDamageArea("swoosh")
		mcontroller.controlModifiers({movementSuppressed = true})
    
		self.weapon:setDamage(self.damageConfig, damageArea)
		self.damageListener:update()
	end)
	
	self.damageListener = nil
	
	altHoldTmp = false
	self.chargeCooldownTimer = 1.0
end

function Parry:reset()
  animator.setAnimationState("parryShield", "inactive")
  status.clearPersistentEffects("broadswordParry")
  activeItem.setItemShieldPolys({})
end

function Parry:uninit()
  self:reset()
end
