function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
  animator.setParticleEmitterActive("healing", true)


  script.setUpdateDelta(5)
  

  self.healingRate = config.getParameter("healAmount", 30) / effect.duration()
  
  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "powerMultiplier", amount = -0.5},
    {stat = "ews_misschance_mult", amount = 0.5},	
    {stat = "ews_inaccuracy_mult", amount = 0.5}
  })
  
  
end

function update(dt)
  status.modifyResource("health", self.healingRate * dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
