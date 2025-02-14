require "/scripts/util.lua"
require "/scripts/status.lua"

function init()

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

	 status.addEphemeralEffect("gic_voidring_resist", 5)

  status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = config.getParameter("explosionDamageAmount"),
      damageSourceKind = "default",
      sourceEntityId = entity.id()
    })
	
--  world.spawnProjectile(
--      "gic_u500_explosion",
--      mcontroller.position(),
--      entity.id(),
--      {0, 0},
--      true,
--      {}
--    )

  self.timeUntilExpire = config.getParameter("deactivateDelay")
  
  self.triggered = true
end
