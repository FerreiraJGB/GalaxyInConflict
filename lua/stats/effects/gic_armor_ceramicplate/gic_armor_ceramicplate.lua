function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.20}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.8,
      speedModifier = 0.80,
      airJumpModifier = 0.80
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
