function init()


  --Power
  self.powerModifier = config.getParameter("powerModifier", 0)
  self.statModifierGroup2 = effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.powerModifier}})  

  self.statModifierGroup1 = effect.addStatModifierGroup({
  
  
     {stat = "ews_npcfirerate", amount = 0.5}
	
	
  })
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup1)
	effect.removeStatModifierGroup(self.statModifierGroup2)
end
