function init()
  self.statModifierGroup = effect.addStatModifierGroup({

    {stat = "ews_psychicResistance", amount = config.getParameter("ews_psychicResistance", 100)}
	
	
  })

  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
