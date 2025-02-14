function init()
  animator.setParticleEmitterOffsetRegion("smokebomb", mcontroller.boundBox())
  animator.setParticleEmitterActive("smokebomb", true)
  
  animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
  animator.setParticleEmitterActive("smoke", true)
  
  --animator.setParticleEmitterOffsetRegion("shadow", mcontroller.boundBox())
  --animator.setParticleEmitterActive("shadow", true)
  
  
  effect.setParentDirectives("fade=000000=0.9")
  self.statModifierGroup = effect.addStatModifierGroup({{stat = "invulnerable", amount = 1},{stat = "powerMultiplier", effectiveMultiplier = 1.75}})
  --animator.playSound("burn", -1)
  
  --script.setUpdateDelta(5)

end

function update(dt)
	if effect.duration() < 2.9 then
		animator.setParticleEmitterActive("smokebomb", false)
	end
	
	--if effect.duration() < 2 then
		--animator.setParticleEmitterActive("shadow", true)
	--end
	
	mcontroller.controlModifiers({
      speedModifier = 1.50
    })
end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
