function init()
  local duration = effect.duration()
  if status.stat("gic_stunned") == 1 then
	
	if status.stat("gic_boss_statidentifier") == 1 then
		status.addEphemeralEffect("gic_boss_melee_bleed",duration)
	else
		status.addEphemeralEffect("gic_bleeding_heavy",duration * 2) -- inflicts heavy bleed (to fight normal entities) if not boss
	end
	
	effect.expire()
  end
end

--local duration = 5
function update()
	effect.expire()
end

function uninit()
end
