function init()
	self.duration = effect.duration()
end

function update(dt)

  local species = world.entitySpecies(entity.id())
  if (species == "gic_realistichuman") then
	status.addEphemeralEffect("gic_bandaged_100",self.duration)
	status.addEphemeralEffect("gic_bleeding_mediumStatusImmunity",1)
  else
	status.addEphemeralEffect("gic_bandaged",self.duration)
  end
  
  effect.expire()
end

function uninit()

end
