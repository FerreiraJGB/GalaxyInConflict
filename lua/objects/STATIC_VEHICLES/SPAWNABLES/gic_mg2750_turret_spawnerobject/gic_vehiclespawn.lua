require "/scripts/vec2.lua"

function init()
  object.setInteractive(true)
end

function onInteraction()
  world.spawnVehicle("gic_mg2750_turret", vec2.add(object.position(),{5.0,3}))
  object.smash(true)
end