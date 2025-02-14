function init()
  script.setUpdateDelta(5)
--  self.tickDamagePercentage = config.getParameter("tickDamagePercentage") or 0.025
--  self.tickTime = 3.0
--  self.tickTimer = self.tickTime
  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_bleeding_light", amount = 1},
    {stat = "powerMultiplier", amount = -0.2},	
    {stat = "ews_misschance_mult", amount = 0.1},	
    {stat = "ews_inaccuracy_mult", amount = 0.1}
	})
  
  if entity.entityType() == "monster" then effect.expire() end
end

function update(dt)
--  self.tickTimer = self.tickTimer - dt
--  if self.tickTimer <= 0 then
--    self.tickTimer = self.tickTime
--    status.applySelfDamageRequest({
--        damageType = "IgnoresDef",
--        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
--        damageSourceKind = "ews_bleed",
--        sourceEntityId = entity.id()
--      })
--  end
end

function uninit()
	if effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_bruising_light", 300)
	end
	
	effect.removeStatModifierGroup(self.statModifierGroup)
end
