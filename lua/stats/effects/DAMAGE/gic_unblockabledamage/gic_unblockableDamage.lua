function init()
	self.damagePercent = effect.duration()/100
end

function update(dt)
	status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = math.floor(status.resourceMax("health") * self.damagePercent) + 1,
      damageSourceKind = "ews_melee",
      sourceEntityId = entity.id()
    })
	
	effect.expire()
end

function uninit()
  
end
