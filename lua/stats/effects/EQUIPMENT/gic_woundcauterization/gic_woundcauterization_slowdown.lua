function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.40}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.4,
      speedModifier = 0.40,
      airJumpModifier = 0.40
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
