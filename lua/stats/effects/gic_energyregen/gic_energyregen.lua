function init()
  animator.setParticleEmitterOffsetRegion("energy", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("energy", config.getParameter("emissionRate", 5))
  animator.setParticleEmitterActive("energy", true)

  self.statModifierGroup = effect.addStatModifierGroup({
      {stat = "energyRegenPercentageRate", amount = config.getParameter("regenBonusAmount", 10)},
      {stat = "energyRegenBlockTime", effectiveMultiplier = 0}
    })
end

function update(dt)

end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
