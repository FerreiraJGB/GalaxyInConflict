require "/monsters/gic_base_monster.lua"

-- Engine callback - called on initialization of entity
local oldInit = init
function init()
  oldInit()
  
  self.oldVelocity = mcontroller.velocity()--world.entityVelocity(entity.id())
  if self.oldVelocity == nil then self.oldVelocity = {0,0} end
  --sb.logInfo(sb.printJson(status.resourceNames()))
  
  self.thrust = false
  status.setResource("gic_entityAngle",1.0)
end

local oldUpdate = update
function update(dt)
  oldUpdate(dt)
  
  --sb.logInfo(sb.printJson(storage))
  --status.setResource("gic_entityAngle",1.0)
  local angle = math.pi * 2 + status.resource("gic_entityAngle")
  --sb.logInfo(sb.printJson(angle -  math.pi * 2))
  
  --world.debugLine(mcontroller.position(), vec2.add(mcontroller.position(),{100*math.cos(angle),100*math.sin(angle)}), {255,0,0,255})
  
  local vel = mcontroller.velocity() --world.entityVelocity(entity.id())
  if vel == nil then vel = {0,0} end
  local accel = vec2.sub(vel,self.oldVelocity)
  --vel[1] = vel[1] * 2
  --vel[2] = vel[2] * 2
  
  accel[1] = accel[1] * 2
  accel[2] = accel[2] * 2
  
  world.debugLine(mcontroller.position(), vec2.add(mcontroller.position(),vel), {0,255,0,255})
  world.debugLine(mcontroller.position(), vec2.add(mcontroller.position(),accel), {0,0,255,255})
  
  -- new x = x*cos() + y*sin()
  -- new y = y*cos() - x*sin()
  -- source: https://doubleroot.in/lessons/coordinate-geometry-basics/rotation-of-axes/ because i'm too lazy to do some basic geometry
  
  local x = accel[1]/2
  local y = accel[2]/2
  
  local adjustedX = x * math.cos(angle) + y * math.sin(angle)
  local adjustedY = y * math.cos(angle) - x * math.sin(angle)
  
  local flippedx = false
  --if angle > math.pi/2 or angle < -math.pi/2 then adjustedY = -adjustedY; flippedx = true end
  
  --world.debugLine(mcontroller.position(), vec2.add(mcontroller.position(),{adjustedX*math.cos(angle+math.pi/2),adjustedX*math.sin(angle+math.pi/2)}), {255,0,255,255})
  world.debugLine(mcontroller.position(), vec2.add(mcontroller.position(),{adjustedY*math.cos(angle+math.pi/2),adjustedY*math.sin(angle+math.pi/2)}), {255,0,255,255})
  
  if adjustedX > 2 then
	self.thrust = true
	animator.setAnimationState("mainThrusters", "thrust")
  elseif self.thrust then
	animator.setAnimationState("mainThrusters", "on")
	self.thrust = false
  end
  
  if adjustedX < -0.5 then
	animator.setAnimationState("bottomrightThruster", "thrust")
	animator.setAnimationState("toprightThruster", "thrust")
  else
	animator.setAnimationState("bottomrightThruster", "off")
	animator.setAnimationState("toprightThruster", "off")
  end
  
  local vtb = 1 --vtb = "vertical trigger buffer"
  
  --if (not flippedx and adjustedY < -vtb) or (flippedx and adjustedY > vtb) then
  if adjustedY > vtb then
	--self.topThrust = true
	animator.setAnimationState("topleftThruster", "thrust")
	animator.setAnimationState("toprightThruster", "thrust")
  else--if self.topThrust then
	animator.setAnimationState("topleftThruster", "off")
	animator.setAnimationState("toprightThruster", "off")
	--self.topThrust = false
  end
  
  --if (not flippedx and adjustedY > vtb) or (flippedx and adjustedY < -vtb) then
  if adjustedY < -vtb then
	--self.bottomThrust = true
	animator.setAnimationState("bottomleftThruster", "thrust")
	animator.setAnimationState("bottomrightThruster", "thrust")
  else--if self.bottomThrust then
	animator.setAnimationState("bottomleftThruster", "off")
	animator.setAnimationState("bottomrightThruster", "off")
	--self.bottomThrust = false
  end
  
  --sb.logInfo(sb.printJson(status.resource("stunned")))
  --sb.logInfo(sb.printJson(animator.globalTag("entityRotation")))
  
  self.oldVelocity = vel
end

local oldUninit = uninit
function uninit()
  oldUninit()
end