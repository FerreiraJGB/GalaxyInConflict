function init()

  self.powerModifier = config.getParameter("powerModifier", 0)

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.40},
    {stat = "ews_npcfirerate", amount = 1.0},
    {stat = "gic_suppressed", amount = 1},
    {stat = "ews_misschance_mult", amount = 0.33},
    {stat = "ews_inaccuracy_mult", amount = 0.33},
	
	{stat = "powerMultiplier", effectiveMultiplier = self.powerModifier}
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.4,
      speedModifier = 0.40,
      airJumpModifier = 0.40
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
