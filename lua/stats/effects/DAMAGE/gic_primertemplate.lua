function init()
  local duration = effect.duration()
	
  --"stat" should be set to 1 in the triggering status effect
  if status.stat("stat") == 1 then
	status.addEphemeralEffect("statusEffect",duration)
  end

  effect.expire()
end

--local duration = 5
function update()
	effect.expire()
end

function uninit()
end
