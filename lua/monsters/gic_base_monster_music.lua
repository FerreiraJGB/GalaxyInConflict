require "/monsters/gic_base_monster.lua"

-- Engine callback - called on initialization of entity
local oldInit = init
function init()
  self.musicEnabled = true
  self.nearbyPlayers = {}
  
  oldInit()
end

local oldUpdate = update
function update(dt)
  oldUpdate(dt)
  
  -- Main music scripts (finds nearby valid players, plays music to them if in range, stops music when players exit range)
  fillPlayerTable()
end


function fillPlayerTable()
	for playerId, _ in pairs(self.nearbyPlayers) do
		if not world.entityExists(playerId) then
			-- Player died or left the mission
			self.nearbyPlayers[playerId] = nil
		else
			local dist = world.magnitude(mcontroller.position(),world.entityPosition(playerId))
			-- Player is out of range
			if dist > config.getParameter("range",50) then
				self.nearbyPlayers[playerId] = nil
				world.sendEntityMessage(playerId, "playAltMusic", jarray(), config.getParameter("fadeOutTime",2.0))
			end
		end
	end

	local newPlayers = world.playerQuery(mcontroller.position(), config.getParameter("range",50), {})--broadcastAreaQuery({ includedTypes = {"player"} })
	for _, playerId in pairs(newPlayers) do
		if self.musicEnabled and not self.nearbyPlayers[playerId] then
			--sb.logInfo(playerId)
			--sb.logInfo(sb.printJson(config.getParameter("music")))
			
			initmusic(playerId)
			self.nearbyPlayers[playerId] = true
		end
	end
end

function initmusic(playerId)
	--sb.logInfo(sb.printJson(config.getParameter("music")))
	if self.musicEnabled then
		world.sendEntityMessage(playerId, "playAltMusic", config.getParameter("music"), config.getParameter("fadeInTime",2.0))
	else
		world.sendEntityMessage(playerId, "playAltMusic", jarray(), config.getParameter("fadeOutTime",2.0))
	end
end

function die()
  if not capturable.justCaptured then
    if self.deathBehavior then
      self.deathBehavior:run(script.updateDt())
    end
    capturable.die()
  end
  
  -- Stops all current instances of music playing started by this monster
  for playerId, _ in pairs(self.nearbyPlayers) do
	world.sendEntityMessage(playerId, "playAltMusic", jarray(), config.getParameter("fadeOutTime",2.0))
  end
  
  spawnDrops()
end

local oldUninit = uninit
function uninit()
  oldUninit()
end
