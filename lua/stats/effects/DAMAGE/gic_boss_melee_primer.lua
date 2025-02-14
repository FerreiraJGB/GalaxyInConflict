function init()
  local duration = effect.duration()
  if status.stat("gic_boss_statidentifier") == 1 then
	status.addEphemeralEffect("gic_boss_melee_bleed",duration);
	effect.expire();
  end
end

--local duration = 5
function update()
	effect.expire();
end

function uninit()
end
