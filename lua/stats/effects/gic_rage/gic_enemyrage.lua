function init()
  --Power
  self.powerModifier = config.getParameter("powerModifier", 0)
  self.statModifierGroup = effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.powerModifier}})

  --Colour
  effect.setParentDirectives("fade="..config.getParameter("color").."=0.1")
  script.setUpdateDelta(0)

  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
end


function update(dt)

end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
