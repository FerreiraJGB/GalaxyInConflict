function init()
  script.setUpdateDelta(5)

  self.healingRate = 1.0 / config.getParameter("healTime", 60)
  
  self.healthModifier = config.getParameter("healthModifier", 0)
  self.statModifierGroup = effect.addStatModifierGroup({{stat = "maxHealth", effectiveMultiplier = self.healthModifier}})
  
end

function update(dt)
  
  status.modifyResourcePercentage("health", self.healingRate * dt)
  
end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup)

end
