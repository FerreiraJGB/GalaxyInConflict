function init()
  --Health Scale
--  self.healthModifier = config.getParameter("healthModifier", 0)
--  self.statModifierGroup = effect.addStatModifierGroup({{status.resourceMax("food"), effectiveMultiplier = self.healthModifier}})
--   status.modifyResource("food", status.resource("food") * config.getParameter("healthModifier", 0) )



--   maxValue
   --modifyResource
   
   
   self.foodMultiplier = config.getParameter("foodMultiplier", 1)
   
self.statModifierGroup = status.resourceMax("food", effectiveMultiplier = self.foodMultiplier) --* dt   
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
