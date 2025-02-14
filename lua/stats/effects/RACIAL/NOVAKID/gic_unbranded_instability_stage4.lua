function init()

  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "maxHealth", amount = config.getParameter("healthAmount", 0)},
    {stat = "ews_misschance_mult", amount = -0.3},	
    {stat = "ews_inaccuracy_mult", amount = -0.3},
    {stat = "ews_meleeResistance", amount = -0.66},		
    {stat = "jumpModifier", amount = 0.4}
	})
 
end



function update(dt)

  mcontroller.controlModifiers({
      groundMovementModifier = 1.4,
      speedModifier = 1.4,
      airJumpModifier = 1.4
    })

end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup)
end
