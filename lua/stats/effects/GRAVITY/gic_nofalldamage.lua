function init()
  self.statModifierGroup = effect.addStatModifierGroup({
{stat = "fallDamageMultiplier", effectiveMultiplier = 0}
  })
end

function update(dt)

end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
