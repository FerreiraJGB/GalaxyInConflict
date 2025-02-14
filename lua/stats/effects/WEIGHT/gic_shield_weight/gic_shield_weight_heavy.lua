function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 0.0}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.9,
      speedModifier = 0.9,
      airJumpModifier = 1.0
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
