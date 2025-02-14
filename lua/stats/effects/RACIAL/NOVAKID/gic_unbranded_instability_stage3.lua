function init()

  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "maxHealth", amount = config.getParameter("healthAmount", 0)},	
    {stat = "ews_misschance_mult", amount = -0.2},	
    {stat = "ews_inaccuracy_mult", amount = -0.2},
    {stat = "ews_meleeResistance", amount = -0.33},		
    {stat = "jumpModifier", amount = 0.2}
	})
 
end


local expireSfx = true


function update(dt)

  mcontroller.controlModifiers({
      groundMovementModifier = 1.2,
      speedModifier = 1.2,
      airJumpModifier = 1.2
    })

  
end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup)
end
