function init()
  animator.setParticleEmitterOffsetRegion("icetrail", mcontroller.boundBox())
  animator.setParticleEmitterActive("icetrail", true)
  effect.setParentDirectives("fade=00BBFF=0.05") --0.15

  script.setUpdateDelta(5)
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.25}
  })
  
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.75,
      speedModifier = 0.75,
      airJumpModifier = 0.75
    })
	
	
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = 20, --30
        damageSourceKind = "ice",
        sourceEntityId = entity.id()
      })
  end
	
end

function uninit()

  effect.removeStatModifierGroup(self.statModifierGroup)

end
