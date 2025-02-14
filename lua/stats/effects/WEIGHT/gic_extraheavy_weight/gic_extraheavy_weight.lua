function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.99}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.01,
      speedModifier = 0.01,
      airJumpModifier = 0.01
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
