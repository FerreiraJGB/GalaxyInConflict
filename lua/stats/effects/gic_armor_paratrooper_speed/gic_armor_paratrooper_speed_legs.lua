function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 0.10},
    {stat = "gic_dodge_stat", amount = 0.05}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1.10,
      speedModifier = 1.10,
      airJumpModifier = 1.10
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
