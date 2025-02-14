function init()
	effect.setParentDirectives("fade=ff0000=0.5?border=2;99000099;00000000")
	self.statModifierGroup1 = effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = 3.0}})
	
	animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
	animator.setParticleEmitterActive("embers", true)
	
	self.statModifierGroup2 = effect.addStatModifierGroup({
    {stat = "protection", amount = 10.0},
    {stat = "ews_meleeResistance", amount = 3.95},
    {stat = "ews_smallarmsResistance", amount = 0.95},
    {stat = "ews_heavyarmsResistance", amount = 0.95}
  })
end


function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup1)
	effect.removeStatModifierGroup(self.statModifierGroup2)
end