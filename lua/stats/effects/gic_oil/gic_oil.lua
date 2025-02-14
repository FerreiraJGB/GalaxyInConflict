require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade=300030=0.1") --0.8
  
   self.statModifierGroup = effect.addStatModifierGroup({{stat = "gic_oil", amount = 1}})
   
   self.receivedDamage = 0
   self.damageTimer = 0
   
   self.damageThreshold = 70
   
   self.damageListener = damageListener("damageTaken", function(notifications)
		local totalDamage = 0
		for _, notification in pairs(notifications) do
			--sb.logInfo(notification.damageSourceKind)
			if notification.hitType == "Hit" then
				local damageKind = notification.damageSourceKind
				local elementKind = root.assetJson("/damage/"..damageKind..".damage")
				
				if elementKind and elementKind.elementalType == "fire" then
					totalDamage = totalDamage + notification.damageDealt
				end
			end
		end
		if totalDamage >= 0 then
			if self.damageTimer <= 0 then
				self.receivedDamage = 0 --reset damage
				self.damageTimer = 0.5 --0.5s to stack up damage
			end
			self.receivedDamage = self.receivedDamage + totalDamage
		end
	end)
end

function update(dt)
	self.damageListener:update()
	
	self.damageTimer = self.damageTimer - dt
	
	-- trigger status effect
	if self.receivedDamage >= self.damageThreshold then
		status.addEphemeralEffect("gic_oilburning",20)
		effect.expire()
	end
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
