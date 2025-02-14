function init()
  --Health Scale
  self.healthModifier = config.getParameter("healthModifier", 0)
  self.statModifierGroup = effect.addStatModifierGroup({{stat = "maxHealth", effectiveMultiplier = self.healthModifier}})
  
  if entity.entityType() == "monster" then effect.expire() end
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
