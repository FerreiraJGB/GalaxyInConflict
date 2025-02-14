require "/scripts/util.lua"

function init()
   script.setUpdateDelta(0)
   
   if not status.resourcePositive("health") then
		world.spawnProjectile("gic_null", mcontroller.position(), 0, {0, 0}, false, config.getParameter("projectileParameters")) --timeToLive = 0 })
	end
end

function uninit()

end
