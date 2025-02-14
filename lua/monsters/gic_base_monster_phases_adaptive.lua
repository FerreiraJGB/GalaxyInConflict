require "/monsters/gic_base_monster.lua"

--added code
local phaseTriggers = {}
local phaseTriggerIds = {}
local healthThresholdTriggers = {}

-- Engine callback - called on initialization of entity
local oldInit = init
function init()
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
end

local oldUpdate = update
function update(dt)
  oldUpdate(dt)
  
  --added code
  updatePhases()
  
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