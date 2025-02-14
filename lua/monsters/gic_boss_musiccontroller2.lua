require "/scripts/util.lua"
require "/scripts/rect.lua"

function init()
  self.tookDamage = false
  self.dead = false

  --Movement
  self.spawnPosition = mcontroller.position()

  self.jumpTimer = 0
  self.isBlocked = false
  self.willFall = false

  self.queryTargetDistance = config.getParameter("queryTargetDistance", 60)
  self.trackTargetDistance = config.getParameter("trackTargetDistance")
  self.switchTargetDistance = config.getParameter("switchTargetDistance")
  self.keepTargetInSight = config.getParameter("keepTargetInSight", true)

  self.targets = {}

  self.skillParameters = {}
  

  monster.setUniqueId(config.getParameter("uniqueId"))

  monster.setDeathParticleBurst("deathPoof")

  monster.setDamageBar("None")

  self.musicEnabled = false
end

function update(dt)
  self.tookDamage = false

  if not status.resourcePositive("health") then
    local inState = self.state.stateDesc()
    if inState ~= "dieState" and not self.state.pickState({ die = true }) then
      self.state.endState()
      self.dead = true
    end

    self.state.update(dt)

    setBattleMusicEnabled(false)
  else
    trackTargets(self.keepTargetInSight, self.queryTargetDistance, self.trackTargetDistance, self.switchTargetDistance)


    if hasTarget() then
      script.setUpdateDelta(1)
      updatePhase(dt)

      monster.setDamageBar("Special")
      monster.setAggressive(true)
      setBattleMusicEnabled(true)
    else
      if self.hadTarget then
        if bossReset then bossReset() end
        monster.setDamageBar("None")
        monster.setAggressive(false)
      end

      script.setUpdateDelta(10)

      if not self.state.update(dt) then
        self.state.pickState()
      end

      setBattleMusicEnabled(false)
    end

    self.hadTarget = hasTarget()
  end
end

function damage(args)
  self.tookDamage = true

  if args.sourceId and args.sourceId ~= 0 and not inTargets(args.sourceId) then
    table.insert(self.targets, args.sourceId)
  end
end

function shouldDie()
  return self.dead
end

function hasTarget()
  if self.targetId and self.targetId ~= 0 then
    return self.targetId
  end
  return false
end

function trackTargets(keepInSight, queryRange, trackingRange)
  if keepInSight == nil then keepInSight = true end

  if #self.targets == 0 then
    local newTarget = util.closestValidTarget(queryRange)
    table.insert(self.targets, newTarget)
  end

  self.targets = util.filter(self.targets, function(targetId)
    if not world.entityExists(targetId) then return false end

    if keepInSight and not entity.entityInSight(targetId) then return false end

    if trackingRange and world.magnitude(mcontroller.position(), world.entityPosition(targetId)) > trackingRange then
      return false
    end

    return true
  end)

  --Set target to be top of the list
  self.targetId = self.targets[1]
  if self.targetId then
    self.targetPosition = world.entityPosition(self.targetId)
  end
end

function validTarget(targetId, keepInSight, trackingRange)
  local entityType = world.entityType(targetId)
  if entityType ~= "player" and entityType ~= "npc" then
    return false
  end

  if not world.entityExists(targetId) then return false end

  if keepInSight and not entity.entityInSight(targetId) then return false end

  if trackingRange then
    local distance = world.magnitude(mcontroller.position(), world.entityPosition(targetId))
    if distance > trackingRange then return false end
  end

  return true
end

function inTargets(entityId)
  for i,targetId in ipairs(self.targets) do
    if targetId == entityId then
      return i
    end
  end
  return false
end



function setBattleMusicEnabled(enabled)
  if self.musicEnabled ~= enabled then
    local musicStagehands = config.getParameter("musicStagehands", {})
    for _,stagehand in pairs(musicStagehands) do
      local entityId = world.loadUniqueEntity(stagehand)

      if entityId and world.entityExists(entityId) then
        world.callScriptedEntity(entityId, "setMusicEnabled", enabled)
        self.musicEnabled = enabled
      end
    end
  end
end
