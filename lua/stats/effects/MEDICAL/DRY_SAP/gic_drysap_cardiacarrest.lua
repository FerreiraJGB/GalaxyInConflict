function init()
  script.setUpdateDelta(5)
  self.tickDamagePercentage = 80.0
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
end

function update(dt)

  self.tickTimer = self.tickTimer - dt
  
  local species = world.entitySpecies(entity.id())
  if (species == "floran" or species == "gic_realisticfloran") then
	status.addEphemeralEffect("gic_floranhuntersense",duration)
	status.addEphemeralEffect("gic_suppressedStatusImmunity",duration)
	effect.expire()
  else
	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
		status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
			damageSourceKind = "ews_antitank",
			sourceEntityId = entity.id()
		})
	end
  end
end

function uninit()

end
