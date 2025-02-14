function init()

  script.setUpdateDelta(5)

  self.healingRate = config.getParameter("healAmount", 30) / effect.duration()
  
end

function update(dt)
  status.modifyResource("health", self.healingRate * dt)
end

function uninit()
  
end
