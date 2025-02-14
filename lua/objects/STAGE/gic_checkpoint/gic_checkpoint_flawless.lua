require "/scripts/rect.lua"
require "/scripts/util.lua"

function init()
  self.queryArea = config.getParameter("queryArea")
  self.queryArea = rect.translate(self.queryArea, entity.position())
  
  if not storage.playersTracker then
	storage.playersTracker = {}
  end

  self.spawnOffset = config.getParameter("spawnOffset", {0, 0})

  self.trackPlayers = util.interval(config.getParameter("queryInterval", 1.0), function()
    local players = world.entityQuery(rect.ll(self.queryArea), rect.ur(self.queryArea), { includedTypes = { "player" } })
	for key, value in pairs (players)
	do
		if not storage.playersTracker[value] then storage.playersTracker[value] = true end
	end
	self.checkDeaths()
  end)
  
  self.checkDeaths = (function()
	for key, value in pairs (storage.playersTracker)
	do
		if not world.entityExists(key) then --player died or left mission
			storage.flawlessFailed = true
			object.setOutputNodeLevel(0,true)
		end
	end
  end)
  
  
  self.query = util.interval(config.getParameter("queryInterval", 1.0), function()
    local players = world.entityQuery(rect.ll(self.queryArea), rect.ur(self.queryArea), { includedTypes = { "player" } })
    if #players > 0 then
      activate()
    end
  end)

  animator.setAnimationState("checkpoint", storage.activated and "active" or "inactive")
  if not storage.activated then
    if not (config.getParameter("alwaysLit")) then object.setLightColor({0, 0, 0, 0}) end
    object.setSoundEffectEnabled(false)
  end
  
  if not storage.flawlessFailed then
	storage.flawlessFailed = false
  else
	object.setOutputNodeLevel(0,true)
  end
end

function activate()
  animator.setAnimationState("checkpoint", "activate")
  if not (config.getParameter("alwaysLit")) then object.setLightColor(config.getParameter("lightColor", {0, 0, 0, 0})) end
  object.setSoundEffectEnabled(true)
  world.setPlayerStart(vec2.add(entity.position(), self.spawnOffset), true)
  storage.activated = true
end

function update(dt)
  if not storage.flawlessFailed == true then
	self.trackPlayers(dt)
	self.checkDeaths()
  end
  if not storage.activated then
    self.query(dt)
  end
end
