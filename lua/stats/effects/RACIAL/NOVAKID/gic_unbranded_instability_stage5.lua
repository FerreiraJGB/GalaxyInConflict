function init()

  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "maxHealth", amount = config.getParameter("healthAmount", 0)},	
    {stat = "ews_infammo", amount = 1.0},
	
    {stat = "ews_misschance_mult", amount = -0.4},	
    {stat = "ews_inaccuracy_mult", amount = -0.4},
    {stat = "ews_meleeResistance", amount = -1.0},			
    {stat = "jumpModifier", amount = 0.8}
	})

end



function update(dt)

  mcontroller.controlModifiers({
      groundMovementModifier = 1.8,
      speedModifier = 1.8,
      airJumpModifier = 1.8
    })
  
end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup)
end
