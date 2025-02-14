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
    {stat = "jumpModifier", amount = 0.0}
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
      groundMovementModifier = 2.2,
      speedModifier = 2.2,
      airJumpModifier = 2.2
    })
end

function uninit()

if status.resourcePositive("health") == false then

  world.spawnProjectile(
      "gic_pericarpyx_infection_spawn_husk",
      mcontroller.position(),
      entity.id(),
      {0, 0},
      true,
      {}
    )
	
	end

	effect.removeStatModifierGroup(self.statModifierGroup)
end
