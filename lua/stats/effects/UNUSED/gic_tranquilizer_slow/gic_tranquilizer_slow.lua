function init()
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.60}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.2,
      speedModifier = 0.20,
      airJumpModifier = 0.20
    })
end

function uninit()

end
