function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 0.1}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1.1,
      speedModifier = 1.1,
      airJumpModifier = 1.1
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
