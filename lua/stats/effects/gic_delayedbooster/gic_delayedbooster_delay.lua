function init()
  self.statModifierGroup = effect.addStatModifierGroup({

    {stat = "gic_delayedbooster_healStatusImmunity", amount = 1.0}

  })
end

function update(dt)
  
  
  
end

function uninit()

	if effect.duration() and effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_delayedbooster_delay2", 0.01)
	end

	
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
