function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = config.getParameter("jumpModif", -1.0)}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = config.getParameter("speedModif", 1),
      speedModifier = config.getParameter("speedModif", 1),
      airJumpModifier = config.getParameter("speedModif", 1)
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
