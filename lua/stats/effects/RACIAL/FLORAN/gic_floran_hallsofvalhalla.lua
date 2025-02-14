function init()


  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "maxHealth", amount = config.getParameter("healthAmount", 0)}
  })

  animator.setParticleEmitterActive("sparks", true)
  effect.setParentDirectives("fade=E0FFFF=0.0")

  script.setUpdateDelta(5)
  
  
  self.healingRate = 1.0 / config.getParameter("healTime", 60)
  
  
end

function update(dt)
  status.modifyResourcePercentage("health", self.healingRate * dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
