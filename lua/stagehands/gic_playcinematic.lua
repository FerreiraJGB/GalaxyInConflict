require "/scripts/stagehandutil.lua"

function init()
  self.containsPlayers = {}
end

function update(dt)
  local newPlayers = broadcastAreaQuery({includedTypes = {"player"}})
  local oldPlayers = table.concat(self.containsPlayers, ",")
  for _, id in pairs(newPlayers) do
    if not string.find(oldPlayers, id) then
      world.sendEntityMessage(entity.id(), "playCinematic", config.getParameter("gic_playcinematic"))
    end
  end
  self.containsPlayers = newPlayers
end
