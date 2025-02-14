require "/monsters/gic_base_monster.lua"

--phases related variables
local phaseTriggers = {}
local phaseTriggerIds = {}
local healthThresholdTriggers = {}

local musicLoc = ""
local finalStandTriggered = false

-- Engine callback - called on initialization of entity
local oldInit = init
function init()
  self.musicEnabled = true
  self.nearbyPlayers = {}
  
  oldInit()
  
  --PHASE STUFF
  phaseTriggerIds = config.getParameter("phaseTriggerIds")
  healthThresholdTriggers = config.getParameter("healthThresholdTriggers")
  for i = 1, config.getParameter("phaseTriggerCount"), 1 do
	phaseTriggers[i] = false 
  end
  
  if not storage.playerTrackerAdaptive then 
	storage.playerTrackerAdaptive = {}
	storage.playerTrackCount = 0 
  end
  
  musicLoc = config.getParameter("music")
end

local oldUpdate = update
function update(dt)
  
  oldUpdate(dt)
  
  -- Main music scripts (finds nearby valid players, plays music to them if in range, stops music when players exit range)
  fillPlayerTable()
  
  --controls phases
  updatePhases()
  
  --switches music source to final stand music when threshhold met.
  finalStandMusic()
  
  --increases monster health if nearby players (one time buff per player)
  trackPlayersAdaptive()
end

function updatePhases()
	for i = 1, config.getParameter("phaseTriggerCount"), 1 do
		if status.resourcePercentage("health") <= healthThresholdTriggers[i] and phaseTriggers[i] == false then
			phaseTriggers[i] = true
			
			animator.setGlobalTag("phaseId", (i+1).."") -- for frame stuff for bosses.
			
			self.behavior = behavior.behavior(config.getParameter("behavior"), sb.jsonMerge(config.getParameter(phaseTriggerIds[i], {}), skillBehaviorConfig()), _ENV)
		
		--phase regression
		elseif (status.resourcePercentage("health") > healthThresholdTriggers[i] and phaseTriggers[i] == true) and config.getParameter("regressPhases") == true then
			
			phaseTriggers[i] = false
			local tempLowest = 1.0
			local lowestIndex = i
			for x = 1, config.getParameter("phaseTriggerCount"), 1 do --find the phase to regress to
				if (healthThresholdTriggers[x] and phaseTriggers[x] == true) and (healthThresholdTriggers[x] < tempLowest) then
					tempLowest = healthThresholdTriggers[x]
					lowestIndex = x
				end
			end
			
			if tempLowest == 1.0 then
				self.behavior = behavior.behavior(config.getParameter("behavior"), sb.jsonMerge(config.getParameter("behaviorConfig", {}), skillBehaviorConfig()), _ENV)
			else
				phaseTriggers[lowestIndex] = false
				self.behavior = behavior.behavior(config.getParameter("behavior"), sb.jsonMerge(config.getParameter(phaseTriggerIds[lowestIndex], {}), skillBehaviorConfig()), _ENV)
			end
		end
	end
end

function finalStandMusic()
	if status.resourcePercentage("health") <= config.getParameter("finalStandThreshold") and finalStandTriggered == false then
		finalStandTriggered = true
		musicLoc = config.getParameter("finalStandMusic")
		
		for playerId, _ in pairs(self.nearbyPlayers) do
			initmusic(playerId)
		end
	end
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
	--sb.logInfo(sb.printJson(musicLoc))
	if self.musicEnabled then
		world.sendEntityMessage(playerId, "playAltMusic", musicLoc, config.getParameter("fadeInTime",2.0))
	else
		world.sendEntityMessage(playerId, "playAltMusic", jarray(), config.getParameter("fadeOutTime",2.0))
	end
end


function trackPlayersAdaptive()
	-- local params = {
		-- withoutEntityId = entity.id(),
		-- includedTypes = {"creature"},
		-- order = "nearest"
	-- }
	
	local newPlayers = world.playerQuery(mcontroller.position(), config.getParameter("adaptiveTrackingRange",50), {})
	-- world.entityQuery(mcontroller.position(), config.getParameter("adaptiveTrackingRange",50), params)
	for _, playerId in pairs(newPlayers) do
		--local ident = playerId
		--if playerId <= 0 then ident = -playerId end
		
		--sb.logInfo(sb.printJson(storage.playerTrackerAdaptive[ident]))
		if not storage.playerTrackerAdaptive[world.entityName(playerId)] and world.entityCanDamage(entity.id(), playerId) then
			
			storage.playerTrackCount = storage.playerTrackCount + 1
			
			if storage.playerTrackCount > 1 then
				if #status.getPersistentEffects("healthbuff"..tostring(storage.playerTrackCount)) < 1 then
					local hpPercent = status.resourcePercentage("health")
					status.addPersistentEffects("healthbuff"..storage.playerTrackCount, {{stat = "maxHealth", amount = config.getParameter("adaptiveHealthBonus",50)}})
					status.setResourcePercentage("health", hpPercent)
					
					--sb.logInfo(sb.printJson(status.getPersistentEffects("healthbuff"..tostring(storage.playerTrackCount))))
					--sb.logInfo(sb.printJson(#status.getPersistentEffects("healthbuff"..tostring(storage.playerTrackCount))))
					--status.modifyResource("health", config.getParameter("adaptiveHealthBonus",50))
					--status.setStatusProperty(status.stat("maxHealth"), config.getParameter("adaptiveHealthBonus",50))
				end
			end
			storage.playerTrackerAdaptive[world.entityName(playerId)] = true
		end
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
  
  if config.getParameter("extraDropPools") then
	--sb.logInfo(sb.printJson(config.getParameter("extraDropPools")))
	local dropPool = config.getParameter("extraDropPools")[1]
	local a = storage.playerTrackCount - 1
	
	if a > 0 then
		repeat 
			world.spawnTreasure(mcontroller.position(), dropPool, 1)
			a = a - 1
		until a < 1
	end
  end
  
  spawnDrops()
end

local oldUninit = uninit
function uninit()
  oldUninit()
end