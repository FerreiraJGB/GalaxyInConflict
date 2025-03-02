require "/scripts/util.lua"

function init()
  animator.setParticleEmitterOffsetRegion("sparks", mcontroller.boundBox())
  animator.setParticleEmitterActive("sparks", true)
  effect.setParentDirectives("fade=7733AA=0.25")

  script.setUpdateDelta(5)

  self.damageClampRange = config.getParameter("damageClampRange")

  self.tickTime = config.getParameter("boltInterval", 1.0)
  self.tickTimer = self.tickTime
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  local boltPower = util.clamp(status.resourceMax("health") * config.getParameter("healthDamageFactor", 1.0), self.damageClampRange[1], self.damageClampRange[2])
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    local targetIds = world.entityQuery(mcontroller.position(), config.getParameter("jumpDistance", 8), {
      withoutEntityId = entity.id(),
      includedTypes = {"creature"}
    })

    shuffle(targetIds)

    for i,id in ipairs(targetIds) do
      local sourceEntityId = effect.sourceEntity() or entity.id()
      if world.entityCanDamage(sourceEntityId, id) and not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
        local sourceDamageTeam = world.entityDamageTeam(sourceEntityId)
        local directionTo = world.distance(world.entityPosition(id), mcontroller.position())
        world.spawnProjectile(
          "teslaboltsmall",
          mcontroller.position(),
          entity.id(),
          directionTo,
          false,
          {
            power = boltPower,
            damageTeam = sourceDamageTeam
          }
        )
        animator.playSound("bolt")
        return
      end
    end
  end
end

function init()
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
  mcontroller.setVelocity({0, 0})
end

function update(dt)
  mcontroller.controlModifiers({
      facingSuppressed = true,
      movementSuppressed = true
    })
end

function uninit()
  
end
