function init()
  animator.setParticleEmitterOffsetRegion("smokebomb", mcontroller.boundBox())
  animator.setParticleEmitterActive("smokebomb", true)
  
  animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
  animator.setParticleEmitterActive("smoke", true)
  
  
  effect.setParentDirectives("fade=000000=0.9")
  self.statModifierGroup = effect.addStatModifierGroup({{stat = "invulnerable", amount = 1}, {stat = "gic_secondChanceTriggered", amount = 1}})
  --animator.playSound("burn", -1)
  
  --script.setUpdateDelta(5)
  
  self.maxDuration = effect.duration()
  
local expireSfx = true

end

function update(dt)
	if effect.duration() < self.maxDuration - 0.1 then
		animator.setParticleEmitterActive("smokebomb", false)
	end

  if expireSfx and effect.duration() < 0.1 then
    expireSfx = false
    animator.playSound("expire")
  end

end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
