function init()
  effect.setParentDirectives("fade=808080=0.1")
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
  
  self.energyModifier = config.getParameter("energyModifier", 0)
  self.statModifierGroup1 = effect.addStatModifierGroup({{stat = "maxEnergy", effectiveMultiplier = self.energyModifier}})
  
  self.statModifierGroup2 =  effect.addStatModifierGroup({
	{stat = "gic_medkit_recovery_use_penalty", amount = 1},
	{stat = "ews_misschance_mult", amount = 0.75},
   	{stat = "ews_inaccuracy_mult", amount = 0.75}
  })
  
  
  self.powerModifier = config.getParameter("powerModifier", 0)
  self.statModifierGroup3 = effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.powerModifier}})
  
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
  
	effect.removeStatModifierGroup(self.statModifierGroup1)
	effect.removeStatModifierGroup(self.statModifierGroup2)
	effect.removeStatModifierGroup(self.statModifierGroup3)
  
end
