function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
  animator.setParticleEmitterActive("healing", true)

  script.setUpdateDelta(5)

  self.healingRate = config.getParameter("healAmount", 30) / effect.duration()
  
  self.healthModifier = config.getParameter("healthModifier", 0)
  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 0.5},	
    {stat = "powerMultiplier", amount = 0.5},
    {stat = "gic_suppressedProtection", amount = 1.0},	


    {stat = "maxHealth", amount = config.getParameter("healthAmount", 0)},
    {stat = "maxHealth", baseMultiplier = config.getParameter("healthBaseMultiplier", 1.0)},
    {stat = "maxHealth", effectiveMultiplier = config.getParameter("healthEffectiveMultiplier", 1.0)}


  })
  
  
end

function update(dt)
  status.modifyResource("health", self.healingRate * dt)
  
  
  mcontroller.controlModifiers({
      groundMovementModifier = 1.5,
      speedModifier = 1.5,
      airJumpModifier = 1.5
    })
  
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
