function init()
  script.setUpdateDelta(1)
end

function update(dt)
  if status.stat("gic_phead") == 1 and status.stat("gic_pchest") == 1 and status.stat("gic_plegs") == 1 then
    status.addEphemeralEffect("gic_powerarmor_powered", effect.duration(), entity.id())
  else
    status.removeEphemeralEffect("gic_powerarmor_powered")
  end
end

function uninit()
end
