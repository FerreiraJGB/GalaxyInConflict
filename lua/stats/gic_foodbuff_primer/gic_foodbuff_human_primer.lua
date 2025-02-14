function init()
	self.duration = effect.duration()
end

function update()
   if world.entitySpecies(effect.sourceEntity()) == "gic_realistichuman" then
      status.modifyResource("health", self.duration)
   end
   effect.expire()
end

function uninit()
end
