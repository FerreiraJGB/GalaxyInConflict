require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()

   world.spawnNpc(mcontroller.position(), "gic_realistichuman", "gic_protectorate_wolf", 1)
   world.spawnNpc(mcontroller.position(), "gic_realistichuman", "gic_federal_paratrooper", 1)
   
end
