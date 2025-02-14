function init()

  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "maxHealth", amount = config.getParameter("healthAmount", 0)},	
    {stat = "ews_misschance_mult", amount = -0.1},	
    {stat = "ews_inaccuracy_mult", amount = -0.1},
	
    {stat = "jumpModifier", amount = 0.1}
	})

end


local expireSfx = true


function update(dt)

  mcontroller.controlModifiers({
      groundMovementModifier = 1.1,
      speedModifier = 1.1,
      airJumpModifier = 1.1
    })
  
end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup)
end
