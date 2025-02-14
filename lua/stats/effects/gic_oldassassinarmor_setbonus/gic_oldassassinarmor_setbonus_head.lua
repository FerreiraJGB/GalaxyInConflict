function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 1.3}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1.3,
      speedModifier = 1.3,
      airJumpModifier = 1.3
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
