function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 1.20}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1.20,
      speedModifier = 1.20,
      airJumpModifier = 1.20
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
