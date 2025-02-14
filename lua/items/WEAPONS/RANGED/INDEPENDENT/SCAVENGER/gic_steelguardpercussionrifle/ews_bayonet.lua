require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

LanceAttack = WeaponAbility:new()

function LanceAttack:new(abilityConfig)
  local primary = config.getParameter("primaryAbility")
  return WeaponAbility.new(self, sb.jsonMerge(primary, abilityConfig))
end

function LanceAttack:init()
  self.cooldownTimer = 0
  self.weapon.onLeaveAbility = function()
    status.clearPersistentEffects("adrenaline")
  end
end

function LanceAttack:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if not self.weapon.currentAbility
     --and shiftHeld
     and self.fireMode == "alt" 
     and self.cooldownTimer == 0 then

    self:setState(self.fire)
  end
end

function LanceAttack:fire() 
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()
 -- animator.setLightActive(self.weapon.elementalType.."flash", true)
 -- animator.playSound(self.weapon.elementalType.."lancefire")
 -- animator.setAnimationState("lance", "fire")
  
  util.wait(self.stances.windup.duration)
  
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()
  animator.playSound("stab")
  animator.setAnimationState("swoosh", "fire")
  
  --status.setPersistentEffects("adrenaline", { "gic_adrenaline_surge" })
  
  
  util.wait(self.stances.fire.duration, function()
	self.weapon:updateAim()
    local damageArea = partDamageArea("middle")
    self.weapon:setDamage(self.damageConfigIntStab, damageArea)
  end)

  
  self.weapon:setStance(self.stances.hold)
  
  while self.fireMode == "alt" do
    local damageArea = partDamageArea("middle")
    self.weapon:setDamage(self.damageConfig, damageArea)
    coroutine.yield()
  end
  
  status.clearPersistentEffects("adrenaline")
  self.weapon:setStance(self.stances.idle)
  self.cooldownTimer = self.cooldownTime
end

function LanceAttack:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function LanceAttack:uninit()
  --status.clearPersistentEffects("adrenaline")
end
