function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.35}, --0.5
	{stat = "fallDamageMultiplier", amount = 10}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1,
      speedModifier = 1.0, --0.9
      airJumpModifier = 0.6 --0.3
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
