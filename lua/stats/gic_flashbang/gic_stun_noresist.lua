require "/scripts/status.lua"

function init()
  effect.setParentDirectives("fade=808080=0.4")
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
  
   effect.addStatModifierGroup({
	{stat = "gic_stunned", amount = 1}
  })
  
  mcontroller.setVelocity({0, 0})
  
  self.listener = damageListener("damageTaken", function()
    animator.setAnimationState("shield", "hit")
  end)
  
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
	
  self.listener:update()
end

function uninit()

end
