require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  animator.setParticleEmitterActive("sparks", true)
  effect.setParentDirectives("fade=E0FFFF=0.0")

  script.setUpdateDelta(5)

  self.triggerDamageThreshold = config.getParameter("triggerDamageThreshold")

  self.timeUntilActive = config.getParameter("activateDelay")
end

function update(dt)
  if self.timeUntilExpire then
    self.timeUntilExpire = self.timeUntilExpire - dt
    if self.timeUntilExpire <= 0 then
      effect.expire()
    end
  elseif self.timeUntilActive > 0 or not self.damageListener then
    self.timeUntilActive = self.timeUntilActive - dt
    if self.timeUntilActive <= 0 then
      self.damageListener = damageListener("damageTaken", function(notifications)
        local totalDamage = 0
        for _, notification in pairs(notifications) do
          if notification.hitType == "Hit" then
            totalDamage = totalDamage + notification.damageDealt
            if totalDamage >= self.triggerDamageThreshold then
              trigger()
              break
            end
          end
        end
      end)
    end
  else
    self.damageListener:update()
  end
end

function uninit()

end

function trigger()

	status.addEphemeralEffect("gic_electrofrost_damage",3); -- this function can config effect duration

  status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = config.getParameter("explosionDamageAmount"),
      damageSourceKind = "ice",
      sourceEntityId = entity.id()
    })
  world.spawnProjectile(
      "gic_soldierslayerloop_explosion_spawn",
      mcontroller.position(),
      entity.id(),
      {0, 0},
      true,
      {}
    )
  animator.burstParticleEmitter("sparks")
  animator.setParticleEmitterActive("sparks", false)
  animator.setLightActive("glow", false)
  self.timeUntilExpire = config.getParameter("deactivateDelay")
end
