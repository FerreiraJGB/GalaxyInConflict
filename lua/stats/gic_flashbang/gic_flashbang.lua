function init()
  effect.setParentDirectives("fade=808080=0.4")
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
  
   self.statModifierGroup = effect.addStatModifierGroup({
	{stat = "gic_flashbanged", amount = 1},
	{stat = "ews_misschance_mult", amount = 0.75},
   	{stat = "ews_inaccuracy_mult", amount = 0.75},
	
	{stat = "gic_dodge_stat", amount = -1.00}
	
  })
  
  mcontroller.setVelocity({0, 0})
end

function update(dt)
  mcontroller.controlModifiers({
      facingSuppressed = true,
      movementSuppressed = true
    })
	
	if status.resource("health") == 0 then
		status.setResource("stunned", 0)
		effect.expire()
	end
end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
