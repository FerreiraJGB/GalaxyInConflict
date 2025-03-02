require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

PowerPunch = WeaponAbility:new()

function PowerPunch:init()
  --self.freezeTimer = 0

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function PowerPunch:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  --self.freezeTimer = math.max(0, self.freezeTimer - self.dt)
  --if self.freezeTimer > 0 and not mcontroller.onGround() and math.abs(world.gravity(mcontroller.position())) > 0 then
   -- mcontroller.controlApproachVelocity({0, 0}, 1000)
  --end
end

-- used by fist weapon combo system
function PowerPunch:startAttack()

  if mcontroller.crouching() then
	self:setState(self.upwindup)
  else
	self:setState(self.windup)
  end

  --self.weapon.freezesLeft = 0
  --self.freezeTimer = self.freezeTime or 0
end

-- State: windup
function PowerPunch:windup()
  self.weapon:setStance(self.stances.windup)

  util.wait(self.stances.windup.duration)

  self:setState(self.windup2)
end

-- State: windup2
function PowerPunch:windup2()
  self.weapon:setStance(self.stances.windup2)

  util.wait(self.stances.windup2.duration)

  self:setState(self.fire)
end

-- State: special
function PowerPunch:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("attack", "special")
  animator.playSound("special")
  --animator.burstParticleEmitter("special")
  --world.spawnProjectile("mechexplosion",mcontroller.position(),activeItem.ownerEntityId(),{0, 0},false,{power=0})

  status.addEphemeralEffect("invulnerable", self.stances.fire.duration + 0.1)

  mcontroller.setVelocity({mcontroller.facingDirection()*40,5})
  util.wait(self.stances.fire.duration, function()
	animator.burstParticleEmitter("special")
    local damageArea = partDamageArea("specialswoosh")
    
    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)
  end)

  finishFistCombo()
  activeItem.callOtherHandScript("finishFistCombo")
end

function PowerPunch:upwindup()
  self.weapon:setStance(self.stances.upwindup)

  util.wait(self.stances.upwindup.duration)
  
  self.weapon:setStance(self.stances.upwindup2)

  util.wait(self.stances.upwindup2.duration)
  
  self:setState(self.upfire)

end

function PowerPunch:upfire()
  animator.burstParticleEmitter("special")
  self.weapon:setStance(self.stances.upfire)
  self.weapon:updateAim()

  animator.setAnimationState("attack", "uppercut")
  animator.playSound("special")
  --animator.burstParticleEmitter("special")
  --world.spawnProjectile("mechexplosion",mcontroller.position(),activeItem.ownerEntityId(),{0, 0},false,{power=0})

  status.addEphemeralEffect("invulnerable", self.stances.fire.duration + 0.1)

  --mcontroller.setVelocity({mcontroller.facingDirection()*40,5})
  util.wait(self.stances.fire.duration, function()
	animator.burstParticleEmitter("special")
    local damageArea = partDamageArea("specialswoosh")
    
    self.weapon:setDamage(self.uppercutdamageConfig, damageArea, self.fireTime)
	if self.stances.fire.velocity and math.abs(world.gravity(mcontroller.position())) > 0 then
      mcontroller.controlApproachVelocity({self.stances.fire.velocity[1] * self.weapon.aimDirection, self.stances.fire.velocity[2]}, 1000)
    end
  end)

  finishFistCombo()
  activeItem.callOtherHandScript("finishFistCombo")
end

function PowerPunch:uninit(unloaded)
  self.weapon:setDamage()
end
