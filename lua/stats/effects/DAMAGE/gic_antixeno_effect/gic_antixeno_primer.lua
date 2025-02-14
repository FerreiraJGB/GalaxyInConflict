function procEffect()
	status.addEphemeralEffect("gic_antixeno_effect",duration);
	effect.expire();
end

function init()
  local duration = effect.duration()
  
  local species = world.entitySpecies(entity.id())
  if species == nil then --if monster, then
	--procEffect();
  else
	if not (species == "human" or species == "gic_realistichuman") then
		procEffect();
	end
  end
end

--local duration = 5
function update()
	effect.expire();
end

function uninit()
end
