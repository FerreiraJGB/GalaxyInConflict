require "/scripts/status.lua"

function init()


end

function update(dt)
 
end

function uninit()

if status.resourcePositive("health") == false then

  world.spawnProjectile(
      "gic_konpaku_skeletonspawn_chance",
      mcontroller.position(),
      entity.id(),
      {0, 0},
      true,
      {}
    )
	
	end

end
