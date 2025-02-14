require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  --animator.setParticleEmitterActive("sparks", true)
  effect.setParentDirectives("fade=FDD700=0.0")

  script.setUpdateDelta(5)

  self.triggerDamageThreshold = config.getParameter("triggerDamageThreshold")

  self.timeUntilActive = config.getParameter("activateDelay")
  
  self.triggered = false
end

function update(dt)
  if self.triggered then
    self.timeUntilExpire = self.timeUntilExpire - dt
    if self.timeUntilExpire <= 0 then
      self.triggered = false
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

  status.addEphemeralEffect("gic_bulletshot_triagefairy_bonusheal",5); -- this function can config effect duration

  --animator.burstParticleEmitter("sparks")
  --animator.setParticleEmitterActive("sparks", false)
  --animator.setLightActive("glow", false)
  self.timeUntilExpire = config.getParameter("deactivateDelay")
  
  self.triggered = true
end
