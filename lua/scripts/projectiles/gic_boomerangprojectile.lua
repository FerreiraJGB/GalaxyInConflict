require "/scripts/vec2.lua"

function init()
  self.returning = config.getParameter("returning", false)
  self.returnOnHit = config.getParameter("returnOnHit", false)
  self.controlForce = config.getParameter("controlForce")
  self.pickupDistance = config.getParameter("pickupDistance")
  self.maxDistance = config.getParameter("maxDistance")
  self.snapDistance = config.getParameter("snapDistance")
  self.timeToLive = config.getParameter("timeToLive")
  self.speed = config.getParameter("speed")
  self.recallSpeed = config.getParameter("recallSpeed")
  self.ignoreTerrain = config.getParameter("ignoreTerrain")
  self.ownerId = projectile.sourceEntity()
  self.minVelocity = config.getParameter("minVelocity", 0.2)

  if self.ignoreTerrain then mcontroller.applyParameters({collisionEnabled=false}) end

  message.setHandler("projectileIds", projectileIds)
  
  message.setHandler("forceReturn", forceReturn)
  message.setHandler("reelingBack", reelingBack)

  message.setHandler("setTargetPosition", function(_, _, targetPosition)
      self.targetPosition = targetPosition
    end)

  if boomerangExtra then
    boomerangExtra:init()
  end
end

function update(dt)
  if self.ownerId and world.entityExists(self.ownerId) then
    if boomerangExtra then
      boomerangExtra:update(dt)
    end

	local toTarget = world.distance(self.targetPosition or world.entityPosition(self.ownerId), mcontroller.position())
    if not self.returning then
      --mcontroller.approachVelocity({0, 0}, self.controlForce)
      if (not self.ignoreTerrain and mcontroller.isColliding()) or (vec2.mag(mcontroller.velocity()) < self.minVelocity) or (vec2.mag(toTarget) > self.maxDistance) then
        self.returning = true
      end
    else
      if vec2.mag(toTarget) < self.pickupDistance then
        projectile.die()
      elseif projectile.timeToLive() < self.timeToLive * 0.5 then
        mcontroller.applyParameters({collisionEnabled=false})
        mcontroller.approachVelocity(vec2.mul(vec2.norm(toTarget), self.recallSpeed), 500)
      elseif vec2.mag(toTarget) < self.snapDistance then
        mcontroller.approachVelocity(vec2.mul(vec2.norm(toTarget), self.recallSpeed), 500)
      else
        mcontroller.approachVelocity(vec2.mul(vec2.norm(toTarget), self.speed), self.controlForce)
      end
    end
  else
    projectile.die()
  end
end

function reelingBack()
  return self.returning
end

function forceReturn()
  self.returning = true
end

function hit(entityId)
  local params = {}
  params.actionOnReap = jarray()
  params.actionOnReap[1] = {action = "sound", options = jarray()}
  params.actionOnReap[1].options[1] = "/sfx/melee/gic_bloodborne_iron-stab-iron.wav"
  
  world.spawnProjectile("gic_null",mcontroller.position(),entity.id(),{0,0},false,params)
  if self.returnOnHit then self.returning = true end
end

function projectileIds()
  if boomerangExtra and boomerangExtra.projectileIds then
    return boomerangExtra:projectileIds()
  else
    return {entity.id()}
  end
end

function setTargetPosition(targetPosition)
  self.targetPosition = targetPosition
end
