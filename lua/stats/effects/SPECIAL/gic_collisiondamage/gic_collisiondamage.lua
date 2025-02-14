require("/scripts/vec2.lua")

function init()
  self.collisionDamageTrackingVelocities = {}
  self.collisionNotificationTrackingVelocities = {}
  self.terrainCollisionDamage = config.getParameter("terrainCollisionDamage")
  self.minDamageCollisionAccel = config.getParameter("minDamageCollisionAccel")
  self.accelerationTrackingCount = 2
  self.lastPosition = mcontroller.position()
  self.expireEffect = false
end

function update(dt)
  if self.expireEffect == false then
	updateTracking(dt)
  end
end

function updateTracking(dt)
  local newPosition = mcontroller.position()
  local newVelocity = (newPosition[1] - self.lastPosition[1])/dt--vec2.div(vec2.sub(newPosition, self.lastPosition), dt)
  self.lastPosition = newPosition

  if mcontroller.isColliding() and not mcontroller.onGround() then
    function findMaxAccel(trackedVelocities)
      local maxAccel = 0
      for _, v in ipairs(trackedVelocities) do
        local accel = math.abs(newVelocity - v)--vec2.mag(vec2.sub(newVelocity, v))
        if accel > maxAccel then
          maxAccel = accel
        end
      end
      return maxAccel
    end

    if findMaxAccel(self.collisionDamageTrackingVelocities) >= self.minDamageCollisionAccel then

	  --animator.playSound("collide")
	  local diff = (findMaxAccel(self.collisionDamageTrackingVelocities) - self.minDamageCollisionAccel)/(self.minDamageCollisionAccel)
	  local damageDealt = self.terrainCollisionDamage * diff
	  
      self.collisionDamageTrackingVelocities = {}
      self.collisionNotificationTrackingVelocities = {}
	  
	  status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = damageDealt,
        damageSourceKind = "default",
        sourceEntityId = entity.id()
      })
	  animator.playSound("collide")
	  --effect.expire()
	  
	  if self.expireEffect == false then
		self.expireEffect = true
		effect.modifyDuration(0.25 - effect.duration())
	  end
    end
  end

  function appendTrackingVelocity(trackedVelocities, newVelocity)
    table.insert(trackedVelocities, newVelocity)
    while #trackedVelocities > self.accelerationTrackingCount do
      table.remove(trackedVelocities, 1)
    end
  end

  appendTrackingVelocity(self.collisionDamageTrackingVelocities, newVelocity)
end

function uninit()
end
