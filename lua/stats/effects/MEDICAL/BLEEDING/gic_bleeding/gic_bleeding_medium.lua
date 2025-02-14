function init()  
  script.setUpdateDelta(5)
  self.tickDamagePercentage = config.getParameter("initialTickDamagePercentage") or 0.025
  self.rampUpPerTick = config.getParameter("rampUpPerTick") or 0.005
  self.tickTime = 2.0
  self.tickTimer = self.tickTime
  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_bleeding_medium", amount = 1},
    {stat = "powerMultiplier", amount = -0.2},	
    {stat = "ews_misschance_mult", amount = 0.1},	
    {stat = "ews_inaccuracy_mult", amount = 0.1}
	})
  
  if entity.entityType() == "monster" then effect.expire() end
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
        damageSourceKind = "ews_bleed",
        sourceEntityId = entity.id()
      })
    
    self.tickDamagePercentage = self.tickDamagePercentage + self.rampUpPerTick
  end
end

function uninit()
	if effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_bruising_medium", 600)
	end
	
	effect.removeStatModifierGroup(self.statModifierGroup)
end
