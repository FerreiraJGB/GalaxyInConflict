function init()
  --Power
  self.powerModifier = config.getParameter("powerModifier", 0)
  self.statModifierGroup = effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.powerModifier}})

  local enableParticles = config.getParameter("particles", true)
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", enableParticles)
end


function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end