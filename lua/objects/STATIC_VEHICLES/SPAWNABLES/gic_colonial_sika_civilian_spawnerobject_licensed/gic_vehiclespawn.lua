require "/scripts/vec2.lua"

function init()
  object.setInteractive(true)
end

function onInteraction()
  world.spawnVehicle("gic_sika_helicopter_civilian", vec2.add(object.position(),{1.9,7}))
  world.spawnItem({item = "gic_sika_license"}, object.position())
  object.smash(true)
end