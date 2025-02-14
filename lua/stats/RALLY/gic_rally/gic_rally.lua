function init()
  local bounds = mcontroller.boundBox()
  effect.addStatModifierGroup({
    {stat = "ews_meleeResistance", amount = 0.25},
    {stat = "ews_misschance_mult", amount = -0.25},
    {stat = "ews_inaccuracy_mult", amount = -0.25}
    })
	
  self.energyModifier = config.getParameter("energyModifier", 0)
  effect.addStatModifierGroup({{stat = "maxEnergy", effectiveMultiplier = self.energyModifier}})
	
end

function update(dt)

end

function uninit()
  
end
