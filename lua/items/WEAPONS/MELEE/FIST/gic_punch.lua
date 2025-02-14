require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

-- fist weapon primary attack
Punch = WeaponAbility:new()

function Punch:init()
  self.damageConfig.baseDamage = self.baseDps * self.fireTime

  self.weapon:setStance(self.stances.idle)
  
  self.parrying = false
  self.triggerAlt = false
  self.triggerAltTimer = 1.0

  self.cooldownTimer = self:cooldownTime()

  --self.freezesLeft = self.freezeLimit
  --self.freezeTimer = 0

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function Punch:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.triggerAltTimer = math.max(0, self.triggerAltTimer - self.dt)
  self.fireMode = fireMode

  --self.freezeTimer = math.max(0, self.freezeTimer - dt)
  --if self.freezeTimer > 0 and not mcontroller.onGround() and math.abs(world.gravity(mcontroller.position())) > 0 then
   -- mcontroller.controlApproachVelocity({0, 0}, 1000)
  --end
  
  if self.weapon.currentAbility == nil
    and shiftHeld
    and self.cooldownTimer == 0 
	and status.resourcePositive("shieldStamina") then
    --and status.overConsumeResource("energy", self.energyUsage) then

    --self.weapon:setStance(self.stances.parry)
	self.weapon:updateAim()
	self:setState(self.parry)
  end
  
  if shiftHeld then
	self.fireModeTmp = 1
  else
	self.fireModeTmp = 0
  end
  
  --if mcontroller.crouching() then
	--status.setPersistentEffects("ducknweave", {"gic_superarmor"})
  --else
	--status.clearPersistentEffects("ducknweave")
  --end
end

function Punch:parry()
  self.weapon:setStance(self.stances.parry)
  self.weapon:updateAim()
  self.parryTime = 999999
  self.perfectBlockTime = 0.4
  self.shieldHealth = 150
  --self.cooldownTime = 0.5
  status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = 9999}})
  
  local blockPoly = animator.partPoly("counterShield", "shieldPoly")
  activeItem.setItemShieldPolys({blockPoly})

  --animator.setAnimationState("parryShield", "active")
  
  animator.playSound("guard")
  
  local shieldHp = status.resource("shieldStamina")
  local damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 then
		if self.shieldTime <= self.perfectBlockTime and status.resource("shieldStamina") < shieldHp then
			animator.playSound("perfectBlock")
			
			self.shieldTime = 0
			status.setResource("shieldStamina", 1)
			status.addEphemeralEffect("regenerationfast",1)
		else
			animator.playSound("parry")
		end
        --animator.playSound("parry")
        --animator.setAnimationState("parryShield", "block")
        return
      end
    end
	
	shieldHp = status.resource("shieldStamina")
  end)
  
  
  
  local perfectParryGone = false
  self.shieldTime = 0
  self.fireModeTmp = 1
  self.parrying = true
  util.wait(self.parryTime, function(dt)
  
	--Interrupt when running out of shield stamina
	if not status.resourcePositive("shieldStamina") then 
		self.cooldownTimer = 1.0
		animator.playSound("break") 
		return true 
	end
	if self.fireModeTmp == 0 then 
		self.cooldownTimer = 0.25
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
	
	if self.fireMode == "primary" and self.triggerAltTimer == 0 and status.stat("gic_hiltbash_cooldown") == 0 then
		self.triggerAlt = true
		activeItem.callOtherHandScript("altAbilityBuffer")
		return true
	end
	
	if self.triggerAlt == true and self.triggerAltTimer == 0 then
		return true
	end
	
	damageListener:update()
  end)
  self.parrying = false
  animator.setGlobalTag("directives", "")
  self:reset()
  activeItem.setItemShieldPolys({})
  
  if self.triggerAlt then
	self.triggerAlt = false
	self:setState(self.triggerAltAbility)
  end
end

function Punch:altAbilityBuffer()
	self.triggerAlt = true
end

function Punch:altAbilityReady()
	return (self.parrying and self.triggerAltTimer == 0)
end

function Punch:triggerAltAbility()
  status.addEphemeralEffect("gic_hiltbash_cooldown")
  
  animator.playSound("hiltSmash")
  self.weapon:setStance(self.stances.stunWindup)

  util.wait(self.stances.stunWindup.duration)
  
  self.weapon:setStance(self.stances.stun)
  mcontroller.setVelocity({mcontroller.facingDirection()*30,2})
  self.weapon:updateAim()

  animator.setAnimationState("attack", "slash")
  animator.playSound("fire")

  --status.addEphemeralEffect("invulnerable", self.stances.fire.duration + 0.05)

  self.damageListener = damageListener("inflictedDamage", function(notifications)
      for _, notification in pairs(notifications) do
        if notification.healthLost > 0 and notification.damageSourceKind == self.stunDamageConfig.damageSourceKind then
          animator.playSound("hiltSmashHit")
          return
        end
      end
    end)
  
  util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("slash")
	mcontroller.controlModifiers({movementSuppressed = true})
    
    self.weapon:setDamage(self.stunDamageConfig, damageArea, self.fireTime)
	self.damageListener:update()
  end)
  
  self.damageListener = nil

  self.cooldownTimer = self.fireTime/2--self:cooldownTime()
  self.triggerAltTimer = 1.0
end

function Punch:canStartAttack()
  return not self.weapon.currentAbility and self.cooldownTimer == 0
end

-- used by fist weapon combo system
function Punch:startAttack()
  self:setState(self.windup)

  --if self.weapon.freezesLeft > 0 then
    --self.weapon.freezesLeft = self.weapon.freezesLeft - 1
    --self.freezeTimer = self.freezeTime or 0
  --end
end

function Punch:initiateAttack()
  self.weapon:setStance(self.stances.windup)

  util.wait(self.stances.windup.duration)
  
  self.weapon:setStance(self.stances.windup2)

  util.wait(self.stances.windup2.duration)
  
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("attack", "fire")
  animator.playSound("fire")

  --status.addEphemeralEffect("invulnerable", self.stances.fire.duration + 0.05)

  util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("swoosh")
    
    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)
  end)

  self.cooldownTimer = self.fireTime--self:cooldownTime()
end

-- State: windup
function Punch:windup()
  self.weapon:setStance(self.stances.windup)

  util.wait(self.stances.windup.duration)

  self:setState(self.windup2)
end

-- State: windup2
function Punch:windup2()
  self.weapon:setStance(self.stances.windup2)

  util.wait(self.stances.windup2.duration)

  self:setState(self.fire)
end

-- State: fire
function Punch:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("attack", "fire")
  animator.playSound("fire")

  --status.addEphemeralEffect("invulnerable", self.stances.fire.duration + 0.05)

  util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("swoosh")
    
    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)
  end)

  self.cooldownTimer = self:cooldownTime()
end

function Punch:cooldownTime()
  return self.fireTime - self.stances.windup.duration - self.stances.fire.duration
end

function Punch:uninit(unloaded)
  self.weapon:setDamage()
  self:reset()
end

function Punch:reset()
	status.clearPersistentEffects("broadswordParry")
	--status.clearPersistentEffects("ducknweave")
	--status.clearPersistentEffects("stopMovement")
	activeItem.setItemShieldPolys({})
end
