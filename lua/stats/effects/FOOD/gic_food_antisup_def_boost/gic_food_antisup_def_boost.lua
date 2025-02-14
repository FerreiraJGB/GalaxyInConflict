function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_smallarmsResistance", amount = 0.3},
	{stat = "gic_suppressedProtection", amount = 1.0}
  })

  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
