require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Melee primary ability
MeleeCombo = WeaponAbility:new()

assassinateWindingStatus = true;
assassinateWindedStatus = true;

triggerWindup = true;
triggerUnwind = true;
triggerAssassination = false;


function MeleeCombo:init()
  self.comboStep = 1

  self.energyUsage = self.energyUsage or 0

  self:computeDamageAndCooldowns()

  self.weapon:setStance(self.stances.idle)

  self.edgeTriggerTimer = 0
  self.flashTimer = 0
  self.cooldownTimer = self.cooldowns[1]

  self.animKeyPrefix = self.animKeyPrefix or ""

  self.weapon.onLeaveAbility = function()
	assassinateWindedStatus = false
	-- sb.logInfo(sb.printJson(assassinateWindedStatus))
    self.weapon:setStance(self.stances.idle)
  end
  
  assassinateWindingStatus = false;
  assassinateWindedStatus = false;
  
  triggerWindup = false;
  triggerUnwind = false;
  
  --sb.logInfo(sb.printJson(assassinateWindedStatus))
end

-- Ticks on every update regardless if this is the active ability
function MeleeCombo:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
    if self.cooldownTimer == 0 then
      self:readyFlash()
    end
  end

  if self.flashTimer > 0 then
    self.flashTimer = math.max(0, self.flashTimer - self.dt)
    if self.flashTimer == 0 then
      animator.setGlobalTag("bladeDirectives", "")
    end
  end

  self.edgeTriggerTimer = math.max(0, self.edgeTriggerTimer - dt)
  if self.lastFireMode ~= (self.activatingFireMode or self.abilitySlot) and fireMode == (self.activatingFireMode or self.abilitySlot) then
    self.edgeTriggerTimer = self.edgeTriggerGrace
  end
  self.lastFireMode = fireMode

  if not self.weapon.currentAbility and self:shouldActivate() then
    self:setState(self.windup)
  end
  
  
  if triggerWindup then
	--sb.logInfo("windupTriggered")
	triggerWindup = false
	self:setState(self.assassinateWindup)
  elseif triggerUnwind then
	--sb.logInfo("winddownTriggered")
	triggerUnwind = false
	self:setState(self.assassinateUnwind)
  elseif triggerAssassination then
	--sb.logInfo("assassinationTriggered")
	triggerAssassination = false
	self:setState(self.assassinateAttack)
  end
end

-- State: windup
function MeleeCombo:windup()
  local stance = self.stances["windup"..self.comboStep]

  self.weapon:setStance(stance)

  self.edgeTriggerTimer = 0

  if stance.hold then
    while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
      coroutine.yield()
    end
  else
    util.wait(stance.duration)
  end

  if self.energyUsage then
    status.overConsumeResource("energy", self.energyUsage)
  end

  if self.stances["preslash"..self.comboStep] then
    self:setState(self.preslash)
  else
    self:setState(self.fire)
  end
end

-- State: wait
-- waiting for next combo input
function MeleeCombo:wait()
  local stance = self.stances["wait"..(self.comboStep - 1)]

  self.weapon:setStance(stance)

  util.wait(stance.duration, function()
    if self:shouldActivate() then
      self:setState(self.windup)
      return
    end
  end)

  self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep - 1] - stance.duration)
  self.comboStep = 1
end

-- State: preslash
-- brief frame in between windup and fire
function MeleeCombo:preslash()
  local stance = self.stances["preslash"..self.comboStep]

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  util.wait(stance.duration)

  self:setState(self.fire)
end

-- State: fire
function MeleeCombo:fire()
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

  if self.comboStep < self.comboSteps then
    self.comboStep = self.comboStep + 1
    self:setState(self.wait)
  else
    self.cooldownTimer = self.cooldowns[self.comboStep]
    self.comboStep = 1
  end
end

function MeleeCombo:shouldActivate()
  if self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
    if self.comboStep > 1 then
      return self.edgeTriggerTimer > 0
    else
      return self.fireMode == (self.activatingFireMode or self.abilitySlot)
    end
  end
end

function MeleeCombo:readyFlash()
  animator.setGlobalTag("bladeDirectives", self.flashDirectives)
  self.flashTimer = self.flashTime
end

function MeleeCombo:computeDamageAndCooldowns()
  local attackTimes = {}
  for i = 1, self.comboSteps do
    local attackTime = self.stances["windup"..i].duration + self.stances["fire"..i].duration
    if self.stances["preslash"..i] then
      attackTime = attackTime + self.stances["preslash"..i].duration
    end
    table.insert(attackTimes, attackTime)
  end

  self.cooldowns = {}
  local totalAttackTime = 0
  local totalDamageFactor = 0
  for i, attackTime in ipairs(attackTimes) do
    self.stepDamageConfig[i] = util.mergeTable(copy(self.damageConfig), self.stepDamageConfig[i])
    self.stepDamageConfig[i].timeoutGroup = "primary"..i

    local damageFactor = self.stepDamageConfig[i].baseDamageFactor
    self.stepDamageConfig[i].baseDamage = damageFactor * self.baseDps * self.fireTime

    totalAttackTime = totalAttackTime + attackTime
    totalDamageFactor = totalDamageFactor + damageFactor

    local targetTime = totalDamageFactor * self.fireTime
    local speedFactor = 1.0 * (self.comboSpeedFactor ^ i)
    table.insert(self.cooldowns, (targetTime - totalAttackTime) * speedFactor)
  end
end

function MeleeCombo:uninit()
  self.weapon:setDamage()
end

function assassinateWindup()
	--self.weapon:setState(self.assassinateWindup)
	triggerWindup = true
end
function MeleeCombo:assassinateWindup()
  self.weapon:setStance(self.stances.idle)
  self.weapon:updateAim()
  
  assassinateWindingStatus = true

  animator.setAnimationState("blade", "extend")
  local progress = 0
  util.wait(self.stances.assassinateWindup.duration, function()
    local from = self.stances.idle.weaponOffset or {0,0}
    local to = self.stances.assassinateWindup.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.idle.weaponRotation, self.stances.assassinateWindup.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.idle.armRotation, self.stances.assassinateWindup.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.assassinateWindup.duration))
  end)
  
  assassinateWindingStatus = false
  assassinateWindedStatus = true;
  
  --animator.setAnimationState("blade", "retract")
  --sb.logInfo("windupFinished")
  util.wait(99999, function()
	--animator.setAnimationState("blade", "active")
  end)
end

function assassinateUnwind()
	--self:setState(self.assassinateUnwind)
	triggerUnwind = true
end
function MeleeCombo:assassinateUnwind()
  self.weapon:setStance(self.stances.assassinateWindup)
  self.weapon:updateAim()
  
  assassinateWindingStatus = false
  assassinateWindedStatus = false;

  local progress = 0
  util.wait(self.stances.assassinateWindup.duration, function()
    local from = self.stances.assassinateWindup.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.assassinateWindup.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.assassinateWindup.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.assassinateWindup.duration))
  end)
  
  --self.assassinateWindingStatus = false
  --self.assassinateWindedStatus = false;
end

function assassinateAttack()
	--self:setState(self.assassinateUnwind)
	triggerAssassination = true
end
function MeleeCombo:assassinateAttack()
  self.weapon:setStance(self.stances.assassinateAttack)
  self.weapon:updateAim()
  
  assassinateWindingStatus = false
  assassinateWindedStatus = false;
  
  animator.setAnimationState("swoosh", "assassination")
  animator.playSound("assassination")
  util.wait(self.stances.assassinateAttack.duration, function()
    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.assassinateDamageConfig, damageArea)
  end)

  --animator.setAnimationState("blade", "retract")
  local progress = 0
  util.wait(self.stances.assassinateAttack.duration, function()
    local from = self.stances.assassinateAttack.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.assassinateAttack.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.assassinateAttack.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.assassinateAttack.duration))
  end)
  
  --self.assassinateWindingStatus = false
  --self.assassinateWindedStatus = false;
end

function assassinateWinding()
	--sb.logInfo("winding?" .. sb.printJson(assassinateWindingStatus))
	return assassinateWindingStatus;
end

function assassinateWinded()
	--sb.logInfo("winded?" .. sb.printJson(assassinateWindedStatus))
	return assassinateWindedStatus;
end

-- lets the Outsider's Mark know that there *is* an Assassin's Blade in the other hand, to avoid unecessary messages across the hands.
-- edit: WHY DOESN'T THIS WORK??? maybe because it's called in init?
-- fuck optimization, idgaf atm.
function confirmAssassinsBlade()
	--sb.logInfo("confirmedAssasinsBlade")
	return true
end

function resetVars()
	--sb.logInfo("varsReset")
	assassinateWindingStatus = false;
	assassinateWindedStatus = false;

	triggerWindup = false;
	triggerUnwind = false;
end