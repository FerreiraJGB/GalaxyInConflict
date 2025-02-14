function init()
  
  
  if entity.entityType() == "monster" then effect.expire() end
  
  
end

function update(dt)
end

function uninit()

	if effect.duration() and effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_apply_moldc1", 1)
	end

end
