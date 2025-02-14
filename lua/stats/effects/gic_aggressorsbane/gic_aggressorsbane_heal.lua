function init()
  script.setUpdateDelta(5)

  self.healingRate = 1.0 / config.getParameter("healTime", 60)
end

function update(dt)
  
  status.modifyResourcePercentage("health", self.healingRate * dt)
  
end

function uninit()

	if effect.duration() and effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_aggressorsbane_weakness", 5)
	end

	effect.removeStatModifierGroup(self.statModifierGroup)  
end
