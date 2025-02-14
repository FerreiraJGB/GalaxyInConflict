require "/scripts/vec2.lua"

function init()
  object.setInteractive(true)
end

function onInteraction()
  world.spawnVehicle("gic_unitan_partisan_mbt", vec2.add(object.position(),{3,4}))
  world.spawnItem({item = "gic_partisan_license"}, object.position())
  object.smash(true)
end