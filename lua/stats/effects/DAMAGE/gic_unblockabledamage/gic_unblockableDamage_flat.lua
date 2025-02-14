function init()
	self.damage = effect.duration()
end

function update(dt)
	status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = self.damage,
      damageSourceKind = "ews_melee",
      sourceEntityId = entity.id()
    })
	
	effect.expire()
end

function uninit()
  
end
