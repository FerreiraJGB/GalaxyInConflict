function init()

  --Health Scale
  self.energyModifier = config.getParameter("energyModifier", 0)
  self.statModifierGroup1 = effect.addStatModifierGroup({{stat = "maxEnergy", effectiveMultiplier = self.energyModifier}})
  
  --Power
  self.powerModifier = config.getParameter("powerModifier", 0)
  self.statModifierGroup2 = effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.powerModifier}})
  
end

function update(dt)

end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup1)
	effect.removeStatModifierGroup(self.statModifierGroup2)
end
