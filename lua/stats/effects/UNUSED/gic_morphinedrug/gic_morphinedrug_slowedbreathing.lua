function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.40}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.6,
      speedModifier = 0.60,
      airJumpModifier = 0.60
    })
end

function uninit()

end
