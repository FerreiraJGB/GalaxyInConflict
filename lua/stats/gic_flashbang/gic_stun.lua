require "/scripts/status.lua"

function init()
  effect.setParentDirectives("fade=808080=0.4")
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
  
  if status.stat("gic_stunProtection") == 1 then
	effect.expire()
  end
  
   self.statModifierGroup = effect.addStatModifierGroup({
	{stat = "gic_stunned", amount = 1},
	{stat = "gic_dodge_stat", amount = -1.00}
  })
  
  mcontroller.setVelocity({0, 0})
  
  self.listener = damageListener("damageTaken", function()
    animator.setAnimationState("shield", "hit")
  end)
  
end

function update(dt)
  if status.stat("gic_stunProtection") == 1 then
	effect.expire()
  end
  
  mcontroller.controlModifiers({
      facingSuppressed = true,
      movementSuppressed = true
    })
	
	if status.resource("health") == 0 then
		status.setResource("stunned", 0)
		effect.expire()
	end
	
  self.listener:update()
  
  if effect.duration() <= dt then
	status.addEphemeralEffect("gic_stunImmunity",6)
  end
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
