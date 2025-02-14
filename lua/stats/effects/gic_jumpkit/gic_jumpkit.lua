function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 1.0},
	{stat = "fallDamageMultiplier", amount = -0.5}
  })
  
  self.gravityModifier = config.getParameter("gravityModifier")
  self.movementParams = mcontroller.baseParameters()

  setGravityMultiplier()
end

function setGravityMultiplier()
  local oldGravityMultiplier = self.movementParams.gravityMultiplier or 1

  self.newGravityMultiplier = self.gravityModifier * oldGravityMultiplier
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1,
      speedModifier = 1.0,
      airJumpModifier = 2.0
    })
  mcontroller.controlParameters({
     gravityMultiplier = self.newGravityMultiplier
  })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
