function init()

  animator.setParticleEmitterActive("sparks", true)
  effect.setParentDirectives("fade=E0FFFF=0.0")

  script.setUpdateDelta(5)

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_misschance_mult", amount = -0.33},	
    {stat = "ews_inaccuracy_mult", amount = -0.33}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
