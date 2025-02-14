function init()
  
  
  if entity.entityType() == "monster" then effect.expire() end
  
  
end

function update(dt)
end

function uninit()

	if effect.duration() and effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_pericarpyx_infection_stage2", 60)
	end

end
