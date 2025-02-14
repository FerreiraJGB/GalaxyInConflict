function init()

  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
  animator.setParticleEmitterActive("healing", true)

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_meleeResistance", amount = -5.0},
    {stat = "maxHealth", amount = config.getParameter("healthAmount", 0)},
    {stat = "maxHealth", baseMultiplier = config.getParameter("healthBaseMultiplier", 1.0)},
    {stat = "maxHealth", effectiveMultiplier = config.getParameter("healthEffectiveMultiplier", 1.0)},
  })

  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
