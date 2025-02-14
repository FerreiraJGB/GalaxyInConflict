function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_suppressedProtection", amount = 1.0}
  })
end

function update(dt)
  
end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup)  
	
	if effect.duration() and effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_suppressed", 2)
	end
	
end
