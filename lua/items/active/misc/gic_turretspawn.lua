require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
end

function update(dt, fireMode, shiftHeld)
	if fireMode == "primary" then

        local vehicleParams = {
          ownerKey = config.getParameter("key"),
          startHealthFactor = config.getParameter("vehicleStartHealthFactor"),
        }

        world.spawnVehicle(config.getParameter("vehicleType"), vec2.add(mcontroller.position(),{mcontroller.facingDirection()*1,-1.0}), vehicleParams )
		animator.playSound("spawn")
		item.consume(1)
    end
end
