function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_light_weight", amount = 1.0},
    {stat = "jumpModifier", amount = 0.1},
    {stat = "gic_dodge_stat", amount = 0.10}
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
