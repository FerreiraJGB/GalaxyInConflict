function init()

  self.powerModifier = config.getParameter("powerModifier", 0)

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 0.25},
    {stat = "ews_npcfirerate", amount = 30.0},
	
	{stat = "powerMultiplier", effectiveMultiplier = self.powerModifier}
  })
  
  if entity.entityType() == "player" then effect.expire() end
  
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1.25,
      speedModifier = 1.25,
      airJumpModifier = 1.25
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
