function init()
  self.statModifierGroup = effect.addStatModifierGroup({{stat = "maxEnergy", amount = config.getParameter("energyAmount", 0)}})

  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
