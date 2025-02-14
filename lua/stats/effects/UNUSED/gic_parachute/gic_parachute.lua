function init()
  effect.setParentDirectives("fade=7733AA=0.25")

  animator.setParticleEmitterActive("gic_parachute", true)
end

function update(dt)
  
  mcontroller.controlModifiers({
    groundMovementModifier = 0.4,
    }),
  mcontroller.setYVelocity(-2)

 
 
  

end

function uninit()

if mcontroller.isColliding() or mcontroller.onGround()
then effect.expire("gic_parachute") 

end
