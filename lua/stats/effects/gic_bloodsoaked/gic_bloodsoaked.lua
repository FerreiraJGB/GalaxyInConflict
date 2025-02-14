function init()
--  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
--  animator.setParticleEmitterActive("drips", true)
--  effect.setParentDirectives("fade=FF0400=0.1") --0.8
  
   self.statModifierGroup = effect.addStatModifierGroup({{stat = "gic_bloodsoaked", amount = 1}})
end

function update(dt)

end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
