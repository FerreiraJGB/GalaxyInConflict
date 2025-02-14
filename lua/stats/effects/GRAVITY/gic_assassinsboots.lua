function init()
  self.statModifierGroup = effect.addStatModifierGroup({
	{stat = "fallDamageMultiplier", amount = -0.9}
  })
end

function update(dt)

end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
