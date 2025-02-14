require "/scripts/util.lua"

function init()
  self.players = {}
  script.setUpdateDelta(5)
  
  
  self.stopMusicType = jarray()
  self.isTerrestial = world.terrestrial()
  
  if self.isTerrestial then -- NOTE -- FOR THIS MUSIC PLAYER CODE, I CAN'T MAKE AN END-ALL-BE-ALL CODE TO CATCH ALL BIOMES BECAUSE OF DIFFERING FILE STRUCTURES AND THE LIKE. AS A RESULT, THE BEST OPTION IS TO JUST MAKE A SPECIFIC LIST FOR THIS KIND OF STUFF OF WHERE THIS OBJECT MAY BE PLACED ON A TERRESTIAL WORLD.
	self.worldType = world.type()
	local rootData = {}
	rootData["gic_abandoned_wartorn"] = "/biomes/surface/planets/gic_abandoned_wartorn.biome"
	rootData["gic_atmospheric_wartorn"] = "/biomes/surface/planets/gic_atmospheric_wartorn.biome"
	rootData["gic_forest_wartorn"] = "/biomes/surface/planets/gic_forest_wartorn.biome"
	rootData["gic_jungle_wartorn"] = "/biomes/surface/planets/gic_jungle_wartorn.biome"
	rootData["gic_wartorn_interstate"] = "/biomes/surface/planets/gic_wartorn_interstate.biome"
	-- only wartorn planets for now; minor issue here is that i can only pull the planet's primary biome soundtrack, cannot pull the soundtrack for a biome at the objects position.
	
	if rootData[self.worldType] then
		local worldData = root.assetJson(rootData[self.worldType])
		local dayTime = (world.timeOfDay() < 0.5) --if timeOfDay < 0.5, then day. else, is nightime (half of day should be daytime, other half should be nighttime.)
		
		if dayTime then self.stopMusicType = worldData.musicTrack.day.tracks else self.stopMusicType = worldData.musicTrack.night.tracks end
	end
  end
end

function update(dt)
	for playerId, _ in pairs(self.players) do
		if not world.entityExists(playerId) then
			-- Player died or left the mission
			self.players[playerId] = nil
		else
			local dist = world.magnitude(object.position(),world.entityPosition(playerId))
			-- Player is out of range
			if dist > config.getParameter("range") then
				self.players[playerId] = nil
				world.sendEntityMessage(playerId, "playAltMusic", jarray(), config.getParameter("fadeOutTime"))
			end
		end
	end

	local newPlayers = world.playerQuery(object.position(), config.getParameter("range") or 50, {})--broadcastAreaQuery({ includedTypes = {"player"} })
	for _, playerId in pairs(newPlayers) do
		if object.getInputNodeLevel(0) and not self.players[playerId] then
			initmusic(playerId)
			self.players[playerId] = true
		end
	end
	
	
	if object.getInputNodeLevel(0) and not self.activated then
		startmusic()
	elseif not object.getInputNodeLevel(0) and self.activated then
		stopmusic()
	end
	
	self.activated = object.getInputNodeLevel(0)
end

function initmusic(playerId)
	if object.getInputNodeLevel(0) then
		world.sendEntityMessage(playerId, "playAltMusic", config.getParameter("music"), config.getParameter("fadeInTime"))
	else
		world.sendEntityMessage(playerId, "playAltMusic", jarray(), config.getParameter("fadeOutTime"))
	end
end

function startmusic()
	for playerId, _ in pairs(self.players) do
		world.sendEntityMessage(playerId, "playAltMusic", config.getParameter("music"), config.getParameter("fadeInTime"))
	end
end

function stopmusic()
	for playerId, _ in pairs(self.players) do
		world.sendEntityMessage(playerId, "playAltMusic", self.stopMusicType, config.getParameter("fadeOutTime"))
	end
end
