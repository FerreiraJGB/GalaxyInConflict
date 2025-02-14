function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_armor_weight_heavy_chest", amount = 1.0},
    {stat = "jumpModifier", amount = 0.0},
    {stat = "gic_dodge_stat", amount = -0.1}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.8,
      speedModifier = 0.8,
      airJumpModifier = 1.0
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
