function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)

  script.setUpdateDelta(5)

  self.tickDamagePercentage = 0.15 --default "weakpoison" statuseffect had this value at 0.025 | Original value had  this at 0.075
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
  
  --reduction in resistances and vanilla protection value
  self.statModifierGroup = effect.addStatModifierGroup({
		{stat = "ews_meleeResistance", amount = -0.5},
		{stat = "ews_smallarmsResistance", amount = -0.25},
		{stat = "ews_heavyarmsResistance", amount = -0.1},
		{stat = "ews_explosiveResistance", amount = -0.25},
		{stat = "protection", amount = -50}
	})
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.min(math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1, 50), -- max damage per tick == 50, to prevent over-scaling
        damageSourceKind = "ews_smallarmsthermal",
        sourceEntityId = entity.id()
      })
  end

  effect.setParentDirectives(string.format("fade=00AA00=%.1f", self.tickTimer * 0.4))
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
