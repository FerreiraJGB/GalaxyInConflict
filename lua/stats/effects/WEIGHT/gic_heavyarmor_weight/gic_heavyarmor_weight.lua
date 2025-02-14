function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.3}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.7,
      speedModifier = 0.7,
      airJumpModifier = 0.6
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
