function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "grit", amount = 1.0}
  })
  
  effect.setParentDirectives("fade="..config.getParameter("color").."=0.15")
  script.setUpdateDelta(0)
  
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
  
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
