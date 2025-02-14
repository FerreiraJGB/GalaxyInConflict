function init()

  self.healthModifier = config.getParameter("healthModifier", 0)

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_shieldDefenseMult", amount = 0.5},
    {stat = "maxHealth", effectiveMultiplier = self.healthModifier}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
