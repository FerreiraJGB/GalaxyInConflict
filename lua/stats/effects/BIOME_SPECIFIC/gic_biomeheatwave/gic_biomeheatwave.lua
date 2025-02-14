function init()
  animator.setParticleEmitterBurstCount("flames", 6)
  animator.setParticleEmitterOffsetRegion("flames", {bounds[1], bounds[2] - 0.25, bounds[3], bounds[2] + 0.25})
  animator.setParticleEmitterOffsetRegion("drips", bounds)
  animator.setParticleEmitterActive("drips", true)

  effect.setParentDirectives(config.getParameter("directives", ""))

  self.movementModifiers = config.getParameter("movementModifiers", {})

  self.energyCost = config.getParameter("energyCost", 1)
  self.healthDamage = config.getParameter("healthDamage", 1)
  
  script.setUpdateDelta(config.getParameter("tickRate", 1))

  self.statModifierGroup = effect.addStatModifierGroup({{stat = "energyRegenPercentageRate", effectiveMultiplier = 0}})

  world.sendEntityMessage(entity.id(), "queueRadioMessage", "gic_biomeheatwave", 5.0)
end

function update(dt)
  mcontroller.controlModifiers(self.movementModifiers)
  if not status.overConsumeResource("energy", self.energyCost) then
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = self.healthDamage,
        damageSourceKind = "fire",
        sourceEntityId = entity.id()
      })
  end
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
