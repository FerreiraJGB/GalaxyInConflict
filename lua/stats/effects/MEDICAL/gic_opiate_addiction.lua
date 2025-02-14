function init()
  --Health Scale
  -- optimize these stat modifier groups later, i'm lazy atm
  self.healthModifier = config.getParameter("healthModifier", 0)
  self.statModifierGroup1 = effect.addStatModifierGroup({{stat = "maxHealth", effectiveMultiplier = self.healthModifier}})
  
  self.statModifierGroup2 = effect.addStatModifierGroup({
    {stat = "gic_opiate_addictionAilment", amount = 1},
    {stat = "gic_opiate_withdrawalProtection", amount = 1}
	})
  
  if entity.entityType() == "monster" then effect.expire() end
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup1)
	effect.removeStatModifierGroup(self.statModifierGroup2)
	
	if effect.duration() and effect.duration() <= script.updateDt() then
--	if effect.duration() <= script.updateDt() then
	 --status.addEphemeralEffect("gic_opiate_withdrawal", 600)
	 status.addEphemeralEffect("gic_applyopiote_withdrawal",0.5)
	end
end
