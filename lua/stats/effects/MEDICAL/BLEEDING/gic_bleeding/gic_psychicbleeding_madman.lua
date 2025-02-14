function init()
  script.setUpdateDelta(5)
  self.tickDamagePercentage = config.getParameter("tickDamagePercentage") or 0.025
  
  self.rampUpPerTick = config.getParameter("rampUpPerTick") or 0.005
  
  self.tickTime = 6.0
  self.tickTimer = self.tickTime
  
  self.statModifierGroup = effect.addStatModifierGroup({{stat = "gic_psychicbleeding_light", amount = 1}})
  
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
        damageSourceKind = "ews_psychic",
        sourceEntityId = entity.id()
      })
    self.tickDamagePercentage = self.tickDamagePercentage + self.rampUpPerTick
  end
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
