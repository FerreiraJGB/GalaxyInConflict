function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 0.65}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.65,
      speedModifier = 0.65,
      airJumpModifier = 0.65
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
