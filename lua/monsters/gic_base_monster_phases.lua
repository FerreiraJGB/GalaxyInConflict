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
end

local oldUpdate = update
function update(dt)
  oldUpdate(dt)
  
  --if self.behaviorTick % 5 == 0 then
  --if status.resourcePercentage("health") <= config.getParameter("healthThresholdTrigger") and phase2trigger == false then
	--self.behavior = behavior.behavior(config.getParameter("behavior"), sb.jsonMerge(config.getParameter("behaviorConfigInjured", {}), skillBehaviorConfig()), _ENV)
	--phase2trigger = true
  --end
  
  --added code
  updatePhases()
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

local oldUninit = uninit
function uninit()
  oldUninit()
end