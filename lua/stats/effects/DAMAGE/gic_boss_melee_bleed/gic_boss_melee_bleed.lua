require "/scripts/status.lua"

function init()
  
  script.setUpdateDelta(5)

--  self.tickDamagePercentage = 0.02
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
  
--   effect.addStatModifierGroup({
--	{stat = "gic_boss_melee_bleed", amount = 1}
--  })
  
  self.statModifierGroup = effect.addStatModifierGroup({{stat = "gic_boss_melee_bleed", amount = 1}})
  

  
  self.listener = damageListener("damageTaken", function(notifications)
    for _, notification in pairs(notifications) do
        if notification.healthLost > 0 then
		
		  world.spawnProjectile(
			"gic_blood_explosion_npc_hit",
			mcontroller.position(),
			entity.id(),
			{0, 0},
			true,
			{}
		  )
		
          return
        end
    end
  end)

  
  
end

function update(dt)

  self.listener:update()  

  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = 100,
        damageSourceKind = "ews_melee",
        sourceEntityId = entity.id()
      })
  end
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
	
	
if status.resourcePositive("health") == false then

  world.spawnProjectile(
      "gic_blood_explosion_npc",
      mcontroller.position(),
      entity.id(),
      {0, 0},
      true,
      {}
    )
	
	end
	
end
