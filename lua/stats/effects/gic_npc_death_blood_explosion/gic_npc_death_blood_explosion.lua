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


end

function update(dt)
  self.listener:update()  
end

function uninit()

--sb.logInfo(sb.printJson(status.resource("health")))

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
