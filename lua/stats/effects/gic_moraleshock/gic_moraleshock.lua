function init()
  local bounds = mcontroller.boundBox()
  self.statModifierGroup1 = effect.addStatModifierGroup({
    {stat = "ews_misschance_mult", amount = 0.5},
    {stat = "ews_inaccuracy_mult", amount = 0.5}
    })
	
  self.energyModifier = config.getParameter("energyModifier", 0)
  self.statModifierGroup2 = effect.addStatModifierGroup({{stat = "maxEnergy", effectiveMultiplier = self.energyModifier}})
	
end

function update(dt)

end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup1)
  effect.removeStatModifierGroup(self.statModifierGroup2)
end
