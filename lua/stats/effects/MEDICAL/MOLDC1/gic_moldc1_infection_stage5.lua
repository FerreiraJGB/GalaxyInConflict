require "/scripts/status.lua"

function init()

  
  
  
  
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
  
  
  
  
  script.setUpdateDelta(5)

  self.healingRate = config.getParameter("healAmount", 30)-- / effect.duration()
  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.5}
	})
  
  if entity.entityType() == "monster" then effect.expire() end
  
  
  effect.setParentDirectives("fade=E19CF4=0.8")
  
  local enableParticles = config.getParameter("particles", true)
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", enableParticles)
  
  animator.playSound("loop", -1)
end

function update(dt)

  self.listener:update()  

  status.modifyResource("health", self.healingRate * dt)

  mcontroller.controlModifiers({
      groundMovementModifier = 0.5,
      speedModifier = 0.5,
      airJumpModifier = 0.5
    })
end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup)
end
