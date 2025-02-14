require "/scripts/util.lua"
require "/scripts/rect.lua"


function init()

  monster.setUniqueId(config.getParameter("uniqueId"))

  monster.setDamageBar("None")

  self.musicEnabled = true

end

function update(dt)
	if hasTarget() then
      script.setUpdateDelta(1)
      updatePhase(dt)
      setBattleMusicEnabled(true)
    else
      script.setUpdateDelta(10)
      setBattleMusicEnabled(false)
    end

    self.hadTarget = hasTarget()

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