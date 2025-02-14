function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 0.2}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1.2,
      speedModifier = 1.2,
      airJumpModifier = 1.2
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
