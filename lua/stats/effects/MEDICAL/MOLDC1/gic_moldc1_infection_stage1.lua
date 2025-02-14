function init()
  
  
  if entity.entityType() == "monster" then effect.expire() end
  
  
end

function update(dt)
end

function uninit()

	if effect.duration() and effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_moldc1_infection_stage2", 90)
	end

end
