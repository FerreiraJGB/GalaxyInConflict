function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_medkit_recovery_use_penaltyProtection", amount = 1.0}
  })
end

function update(dt)

end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
