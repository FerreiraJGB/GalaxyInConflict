function init()
end

function update(dt)
  status.setStatusProperty("gic_stopUnbrandedCycle", true)
  
  effect.expire()
end

function uninit()
end
