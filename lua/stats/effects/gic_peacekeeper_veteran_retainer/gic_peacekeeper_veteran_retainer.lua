function init()
  self.statModifierGroup1 = effect.addStatModifierGroup({
    {stat = "ews_misschance_mult", amount = -0.15},
    {stat = "ews_inaccuracy_mult", amount = -0.15}
  })
  
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