require "/items/active/weapons/melee/gic_meleecombo.lua"

-- Melee primary ability

SpearCombo = MeleeCombo:new()

function SpearCombo:init()
  MeleeCombo.init(self)
  
  self.holdDamageConfig = sb.jsonMerge(self.damageConfig, self.holdDamageConfig)
  self.holdDamageConfig.baseDamage = self.holdDamageMultiplier * self.baseDps / self.fireTime
end

function SpearCombo:update(dt, fireMode, shiftHeld)
  MeleeCombo.update(self,dt,fireMode,shiftHeld)
end

function SpearCombo:wait()
  MeleeCombo.wait(self)
end

-- State: fire
function SpearCombo:fire()
  local stance = self.stances["fire"..self.comboStep]

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  local animStateKey = self.animKeyPrefix .. (self.comboStep > 1 and "fire"..self.comboStep or "fire")
  animator.setAnimationState("swoosh", animStateKey)
  animator.playSound(animStateKey)

  local swooshKey = self.animKeyPrefix .. (self.elementalType or self.weapon.elementalType) .. "swoosh"
  animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep])
  animator.burstParticleEmitter(swooshKey)

  util.wait(stance.duration, function()
    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.stepDamageConfig[self.comboStep], damageArea)
  end)
  
  if self.lastFireMode == "primary" and self.comboStep == 1 then
	--sb.logInfo("triggerHold")
	self:setState(self.hold)
	
	self.triggerHold = true
  end

  if not self.triggerHold then
	if self.comboStep < self.comboSteps then
		self.comboStep = self.comboStep + 1
		self:setState(self.wait)
	else
		self.cooldownTimer = self.cooldowns[self.comboStep]
		self.comboStep = 1
	end
  end
end

function SpearCombo:hold()
  self.weapon:setStance(self.stances.hold)
  self.weapon:updateAim()
  
  while self.lastFireMode == "primary" do
    local damageArea = partDamageArea("blade")
    self.weapon:setDamage(self.holdDamageConfig, damageArea)
	--sb.logInfo("HELP")
	--sb.logInfo(sb.printJson(self.lastFireMode == "primary"))
    coroutine.yield()
  end

  self.triggerHold = false
  --self.cooldownTimer = self.fireTime * self.comboSpeedFactor
  --self.comboStep = 1
  
  if self.comboStep < self.comboSteps then
		self.comboStep = self.comboStep + 1
		self:setState(self.wait)
	else
		self.cooldownTimer = self.cooldowns[self.comboStep]
		self.comboStep = 1
	end
end

function SpearCombo:uninit()
  MeleeCombo.uninit(self)
end