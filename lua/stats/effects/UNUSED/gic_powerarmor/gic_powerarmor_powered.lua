function init()
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.2},
	{stat = "gic_powerarmor_full", amount = 1},
	{stat = "gic_antiheavyweight", amount = 1},
	{stat = "gic_antimediumweight", amount = 1},
	{stat = "gic_antilightweight", amount = 1}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.8,
      speedModifier = 0.8,
      airJumpModifier = 0.8
    })
end

function uninit()

end
