function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_armor_weight_superheavy_head", amount = 1.0},
    {stat = "jumpModifier", amount = -0.3},
    {stat = "gic_dodge_stat", amount = -0.15}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.7,
      speedModifier = 0.7,
      airJumpModifier = 0.7
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
