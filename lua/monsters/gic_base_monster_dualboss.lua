require "/monsters/gic_base_monster.lua"

--added code
local targetEntity
local targetEntityId = false
local queryParameters = {}
local trackingDistance
local targetPhase

-- Engine callback - called on initialization of entity
local oldInit = init
function init()  
  oldInit()
  
  --PHASE STUFF
 targetEntity = config.getParameter("targetEntity")
 trackingDistance = config.getParameter("trackingDistance",100)
 targetPhase = config.getParameter("targetPhase")
 targetEntityId = findTargets()
 --sb.logInfo(sb.printJson(targetEntityId))
 
 queryParameters = {
    withoutEntityId = entity.id(),
    includedTypes = {"creature"},
    order = "nearest"
  }
 
 self.repeatTries = 5
end

local oldUpdate = update
function update(dt)
  oldUpdate(dt)
  
  --added code
  updatePhase()
end

function updatePhase()
	if not storage.switchedPhase then
		if not targetEntityId and self.repeatTries > 0 then
			--sb.logInfo("looking for friendly")
			targetEntityId = findTargets() --buffer in case both entities don't exist exactly simultaneously
			self.repeatTries = self.repeatTries - 1
		elseif not targetEntityId or not world.entityExists(targetEntityId) then
			--switch behavior if not valid target
			storage.switchedPhase = true
			self.behavior = behavior.behavior(config.getParameter("behavior"), sb.jsonMerge(config.getParameter(targetPhase, {}), skillBehaviorConfig()), _ENV)
		end
	end
end

function findTargets()
  local pos = mcontroller.position()
  local candidates = world.entityQuery(pos, trackingDistance, queryParameters)

  if #candidates == 0 then return false end

  for _, candidate in ipairs(candidates) do
    if world.entityTypeName(candidate) == targetEntity then
		return candidate
    end
  end
  
  return false
end

local oldUninit = uninit
function uninit()
  oldUninit()
end