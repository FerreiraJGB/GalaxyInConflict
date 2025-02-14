require "/scripts/vec2.lua"

function init()
  object.setInteractive(true)
end

function onInteraction()
  world.spawnVehicle("boat", vec2.add(object.position(),{-1.7,1.8}))
  object.smash(true)
end