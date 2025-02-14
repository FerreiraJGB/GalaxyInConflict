require "/scripts/status.lua"

function init()

end

function update(dt)

end

function uninit()

--sb.logInfo(sb.printJson(status.resource("health")))

if status.resourcePositive("health") == false then

  world.spawnProjectile(
      "gic_ping_projectile_burdenofthedivine_reping",
      mcontroller.position(),
      entity.id(),
      {0, 0},
      true,
      {}
    )
	
	end

end
