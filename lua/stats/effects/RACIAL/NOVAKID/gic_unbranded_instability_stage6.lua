function init()

  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "maxHealth", amount = config.getParameter("healthAmount", 0)},
    {stat = "ews_infammo", amount = 1.0},
	
    {stat = "ews_misschance_mult", amount = -0.5},	
    {stat = "ews_inaccuracy_mult", amount = -0.5},
    {stat = "ews_meleeResistance", amount = -1.5},		
    {stat = "jumpModifier", amount = 1.6}
	})
 
end



function update(dt)

  mcontroller.controlModifiers({
      groundMovementModifier = 2.6,
      speedModifier = 2.6,
      airJumpModifier = 2.6
    })
  
end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup)
end
