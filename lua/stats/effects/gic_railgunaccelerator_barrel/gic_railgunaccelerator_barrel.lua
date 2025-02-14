function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 0.25}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1.25,
      speedModifier = 1.25,
      airJumpModifier = 1.25
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
