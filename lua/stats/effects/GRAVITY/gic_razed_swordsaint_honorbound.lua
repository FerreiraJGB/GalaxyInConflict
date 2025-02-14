function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -1.0},
	{stat = "fallDamageMultiplier", amount = 10}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1,
      speedModifier = 1.0,
      airJumpModifier = 0.0
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
