function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_armor_weight_medium_head", amount = 1.0},
    {stat = "jumpModifier", amount = 0.0},
    {stat = "gic_dodge_stat", amount = -0.05}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.90,
      speedModifier = 0.90,
      airJumpModifier = 1.0
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
