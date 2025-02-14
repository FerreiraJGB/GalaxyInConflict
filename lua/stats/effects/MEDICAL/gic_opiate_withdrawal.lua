function init()
  --Health Scale
  -- optimize these stat modifier groups later, i'm lazy atm
  
  self.energyModifier = config.getParameter("energyModifier", 0)
  
  self.healthModifier = config.getParameter("healthModifier", 0)
  
  self.statModifierGroup1 = effect.addStatModifierGroup({{stat = "maxHealth", effectiveMultiplier = self.healthModifier}})
  
  self.statModifierGroup2 = effect.addStatModifierGroup({{stat = "maxEnergy", effectiveMultiplier = self.energyModifier}})
  
  self.statModifierGroup3 = effect.addStatModifierGroup({
    {stat = "gic_opiate_withdrawalAilment", amount = 1},
    {stat = "powerMultiplier", amount = -0.5},
    {stat = "ews_misschance_mult", amount = 0.1},	
    {stat = "ews_inaccuracy_mult", amount = 0.1}  
  })
  
  if entity.entityType() == "monster" then effect.expire() end
end

function update(dt)
end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup1)
	effect.removeStatModifierGroup(self.statModifierGroup2)
	effect.removeStatModifierGroup(self.statModifierGroup3)
	
end
