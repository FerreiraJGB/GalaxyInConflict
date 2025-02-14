function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  script.setUpdateDelta(5)

  self.tickTime = 1.0
  self.tickTimer = self.tickTime
end

function update(dt)
  

  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = 25,
        damageSourceKind = "ews_bleed",
        sourceEntityId = entity.id()
      })
  end
end

function uninit()

end
