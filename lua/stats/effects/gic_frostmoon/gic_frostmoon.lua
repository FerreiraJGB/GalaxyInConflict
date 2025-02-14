require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  -- note to med: you can copy this whole .lua file and just edit these four values freely to achieve whatever you need to do.
  self.statName = "gic_frostmoon" -- name of the stat that gets set to value 1; system only works if this stat value is set to 1, otherwise this effect will be ignored.
  self.nameIdentifier = "frostmoon" -- this can be anything, only purpose is to internally store data in format {stat, activated?}
  self.cooldownEffect = "gic_frostmoon_weakness" -- status effect to be triggered after damage is negated/reduced
  self.cooldownEffectDuration = 7 -- duration of cooldown status effect
  self.shouldEntirelyNullifyDamage = true -- if true, then damage is *entirely* nullified when system triggers.



  self.statModifierGroup = effect.addStatModifierGroup({
	{stat = self.statName, amount = 1.0}
  })

  animator.setParticleEmitterActive("sparks", true)
  effect.setParentDirectives("fade=FDD700=0.0")

  script.setUpdateDelta(1)

  self.triggerDamageThreshold = config.getParameter("triggerDamageThreshold")

  self.timeUntilActive = config.getParameter("activateDelay")
  
  self.triggered = false
  
  
  local damageNullifiers = status.statusProperty("gic_damageNullifiers",{})
  if not damageNullifiers[self.nameIdentifier] then
	-- {stat, activated, nullify damage entirely}
	damageNullifiers[self.nameIdentifier] = {self.statName, false, self.shouldEntirelyNullifyDamage}
  end
  status.setStatusProperty("gic_damageNullifiers",damageNullifiers)
end

function update(dt)
  if self.triggered then
    self.timeUntilExpire = self.timeUntilExpire - dt
    if self.timeUntilExpire <= 0 then
		-- nothing lmao
    end
  elseif self.timeUntilActive > 0 then --or not self.damageListener then
    self.timeUntilActive = self.timeUntilActive - dt
    if self.timeUntilActive <= 0 then
		-- nothing here either lol
    end
  else
	local damageNullifiers = status.statusProperty("gic_damageNullifiers",{})
	if damageNullifiers[self.nameIdentifier][2] == false then
		trigger()
	end
  end
end

function uninit()
	if not self.triggered then
		effect.removeStatModifierGroup(self.statModifierGroup)
	end
end

function trigger()
	-- update damageNullifiers table
	local damageNullifiers = status.statusProperty("gic_damageNullifiers")
	damageNullifiers[self.nameIdentifier][2] = true
	status.setStatusProperty("gic_damageNullifiers",damageNullifiers)
	
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = config.getParameter("explosionDamageAmount"),
      damageSourceKind = "default",
      sourceEntityId = entity.id()
    })
	
	animator.burstParticleEmitter("sparks")
	animator.setParticleEmitterActive("sparks", false)
	animator.setLightActive("glow", false)
	
	
	effect.removeStatModifierGroup(self.statModifierGroup)
	self.timeUntilExpire = config.getParameter("deactivateDelay")
	self.triggered = true
	
	status.addEphemeralEffect(self.cooldownEffect, self.cooldownEffectDuration)
end