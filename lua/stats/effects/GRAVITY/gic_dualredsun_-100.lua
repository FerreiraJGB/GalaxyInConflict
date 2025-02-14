function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -1.0},
	{stat = "fallDamageMultiplier", amount = 20}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1,
      speedModifier = 0.8,
      airJumpModifier = 0.15
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
