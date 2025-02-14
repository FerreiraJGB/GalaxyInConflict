require("/scripts/vec2.lua")
require("/vehicles/gic_sika_helicopter/gic_sika_helicopter.lua")

local oldInit = init
local oldUpdate = update
--local oldUnInit = uninit

local aimAngle2 = 0

function init()
  oldInit()
end

function update()
  oldUpdate()
end

-- override old AI targeting
function aiTargeting()
end

function controls()
  -- do literally nothing
end

--local oldAnimate = animate
function animate()
  --oldAnimate()
  
  animator.resetTransformationGroup("flip")
  if self.facingDirection < 0 then
    animator.scaleTransformationGroup("flip", {-1, 1})
  end

  animator.resetTransformationGroup("rotation")
  animator.rotateTransformationGroup("rotation", self.angle)

  -- GUN ANIMATION STUFF
  
  -- local aimLimit2 = math.pi/180 * 60
  -- local diff = world.distance(vehicle.aimPosition("passengerSeat2"), vec2.add(mcontroller.position(),{(-4.75+6.35)*self.facingDirection , -3.0}))
  -- --diff[2] = diff[2] - 0.000366211 + 2.33
  -- --diff[1] = diff[1] - 4.875
  -- aimAngle2 = math.atan(diff[2], diff[1])
  -- if self.facingDirection < 0 then

   -- if aimAngle2 > 0 then
     -- aimAngle2 = math.max(aimAngle2, math.pi - aimLimit2 + self.angle)
   -- else
     -- aimAngle2 = math.min(aimAngle2, -math.pi + aimLimit2 + self.angle)
   -- end
   
   -- if vehicle.entityLoungingIn("passengerSeat2") then
	-- animator.rotateGroup("sidegun", math.pi - aimAngle2 + self.angle)
   -- end
  -- else
   -- if aimAngle2 - self.angle > 0 then
     -- aimAngle2 = math.min(aimAngle2, aimLimit2 + self.angle)
   -- else
     -- aimAngle2 = math.max(aimAngle2, -aimLimit2 + self.angle)
   -- end
   -- if vehicle.entityLoungingIn("passengerSeat2") then
	-- animator.rotateGroup("sidegun", aimAngle2 - self.angle)
   -- end
  -- end
  
  if vehicle.controlHeld("copilotSeat", "up") then
      if self.headlightCanToggle then
	  
		self.headlightState = animator.animationState("headlights")
		if self.headlightState == "on" then
			animator.playSound("headlightSwitchOn")
			--animator.setLightActive("headlightBeam", false)
			animator.setAnimationState("headlights", "off")
		else
			animator.playSound("headlightSwitchOff")
			--animator.setLightActive("headlightBeam", true)
			animator.setAnimationState("headlights", "on")
			
		end
		self.headlightState = animator.animationState("headlights")
		
        self.headlightCanToggle = false
        end
      else
      self.headlightCanToggle = true
   end
end

local oldMove = move
function move()
	oldMove()
end

local oldUninit = uninit
function uninit()
	if oldUninit ~= nil then
		oldUninit()
	end
end
