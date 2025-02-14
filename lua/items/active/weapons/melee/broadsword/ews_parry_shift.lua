require "/scripts/util.lua"
require "/scripts/status.lua"
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
    and shiftHeld
    and self.cooldownTimer == 0 then
    --and status.overConsumeResource("energy", self.energyUsage) then

    self.weapon:setStance(self.stances.parry)
	self.weapon:updateAim()
	self:setState(self.parry)

 
  end
  if shiftHeld then
	self.fireModeTmp = 1
  else
	self.fireModeTmp = 0
  end
end

function Parry:parry()
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
end

function Parry:reset()
  animator.setAnimationState("parryShield", "inactive")
  status.clearPersistentEffects("broadswordParry")
  activeItem.setItemShieldPolys({})
end

function Parry:uninit()
  self:reset()
end
