function init()

end

function update(dt)
  
  
  
end

function uninit()

	if effect.duration() and effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_delayedbooster_heal", 3)
	end

end
