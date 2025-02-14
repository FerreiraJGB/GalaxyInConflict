function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_bleedResistance", amount = config.getParameter("ews_bleedResistance", 1.0)}
  })
  
  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
