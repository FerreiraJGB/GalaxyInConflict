require "/items/active/weapons/melee/gic_meleecombo.lua"


-- Melee primary ability
RangedCombo = MeleeCombo:new()

function RangedCombo:init()
  MeleeCombo.init(self)
end

function RangedCombo:update(dt, fireMode, shiftHeld)
  MeleeCombo.update(self,dt,fireMode,shiftHeld)
end

-- State: fire
function RangedCombo:fire()
  local stance = self.stances["fire"..self.comboStep]

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  local animStateKey = self.animKeyPrefix .. (self.comboStep > 1 and "fire"..self.comboStep or "fire")
  animator.setAnimationState("swoosh", animStateKey)
  animator.playSound(animStateKey)

  local swooshKey = self.animKeyPrefix .. (self.elementalType or self.weapon.elementalType) .. "swoosh"
  animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep])
  animator.burstParticleEmitter(swooshKey)
  
  --spawn projectile code
  if stance.fireProjectile then
	local params = stance.projectileParameters
	if stance.powerMultiplier then
		params.powerMultiplier = activeItem.ownerPowerMultiplier()
	end
	
	world.spawnProjectile(
		stance.projectileType,
        mcontroller.position(),
        activeItem.ownerEntityId(),
        self:aimVector(stance.inaccuracy or 0),
        false,
        params
    )
  end

  util.wait(stance.duration, function()
    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.stepDamageConfig[self.comboStep], damageArea)
  end)

  if self.comboStep < self.comboSteps then
    self.comboStep = self.comboStep + 1
    self:setState(self.wait)
  else
    self.cooldownTimer = self.cooldowns[self.comboStep]
    self.comboStep = 1
  end
end

function RangedCombo:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function RangedCombo:uninit()
  MeleeCombo.uninit(self)
end
