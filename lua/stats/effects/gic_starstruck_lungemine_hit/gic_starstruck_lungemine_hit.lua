require "/scripts/status.lua"

function init()

  script.setUpdateDelta(5)

	
	
end

function update(dt)
  
  if effect.duration() <= dt then
  world.spawnProjectile(
      "gic_uxo_heavyartillery",
      mcontroller.position(),
      entity.id(),
      {0, 0},
      true,
      {}
    )
  end
  
end

function uninit()

end
