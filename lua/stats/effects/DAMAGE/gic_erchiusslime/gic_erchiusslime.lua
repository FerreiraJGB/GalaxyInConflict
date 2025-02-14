function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade=300030=0.8")
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.2}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.6,
      speedModifier = 0.6,
      airJumpModifier = 0.60
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
