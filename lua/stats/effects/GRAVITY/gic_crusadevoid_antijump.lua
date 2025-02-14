function init()
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.95},
	{stat = "fallDamageMultiplier", amount = 0}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1.5,
      speedModifier = 0.9,
      airJumpModifier = 0.3
    })
end

function uninit()

end
