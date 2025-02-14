require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")

function init()
	message.setHandler("enterMissionArea", function(_, _, areaName)
			stageEnterArea(areaName)
		end)

	message.setHandler("gic_realisticfloranintroManagerId", function(_, _, id)
			self.managerId = id
			world.sendEntityMessage(self.managerId, "setSpecies", world.entitySpecies(entity.id()))
		end)

	message.setHandler("giveBeamaxe", function(...)
			setStage(4)
			quest.setIndicators({})
		end)

	quest.setIndicators({})
	quest.setParameter("weaponChest", {type = "item", item = "weaponchest"})
	quest.setParameter("beamaxe", {type = "item", item = "protectoratebeamaxe"})

	setPortraits()

	self.startingMusicTimer = config.getParameter("startingMusicTime")
	self.midpointMusicTimer = 0

	self.pesterTimer = 0

	setStage(1)

	status.setPersistentEffects("protectorateProtection", {
		{ stat = "breathProtection", amount = 1.0 },
		{ stat = "fallDamageMultiplier", effectiveMultiplier = 0.0}
	})
	world.sendEntityMessage(entity.id(), "playCinematic", config.getParameter("openingCinematic"))
end

function questStart()
	if player.essentialItem("beamaxe") then
		quest.complete()
		return
	end
	player.giveEssentialItem("inspectiontool", "inspectionmode")
	if player.introComplete() then
		for _, item in pairs(config.getParameter("skipIntroItems", {})) do
		player.giveItem(item)
		end
		player.giveEssentialItem("beamaxe", "beamaxe")
		quest.complete()
		return
	end
	world.sendEntityMessage(entity.id(), "playCinematic", config.getParameter("openingCinematic"))
	storage.starterChest = player.equippedItem("chest")
	storage.starterLegs = player.equippedItem("legs")
end

function questComplete()
	player.setIntroComplete(true)
	questutil.questCompleteActions()
end

function update(dt)
	if self.startingMusicTimer > 0 then
		self.startingMusicTimer = self.startingMusicTimer - dt
		if self.startingMusicTimer <= 0 then
			world.sendEntityMessage(entity.id(), "playAltMusic", config.getParameter("startingMusicTracks"))
		end
	end

	if self.midpointMusicTimer > 0 then
		self.midpointMusicTimer = self.midpointMusicTimer - dt
		if self.midpointMusicTimer <= 0 then
			world.sendEntityMessage(entity.id(), "playAltMusic", config.getParameter("midpointMusicTracks"))
		end
	end

	updateStage(dt)

	updatePester(dt)
end

function uninit()
	status.clearPersistentEffects("protectorateProtection")

	if quest.state() == "Active" then
		for _, item in pairs(config.getParameter("confiscateItems", {})) do
			player.consumeItem(item, true)
		end
		player.consumeItem(storage.starterChest)
		player.consumeItem(storage.starterLegs)

		player.removeEssentialItem("beamaxe")

		player.cleanupItems()
		player.giveItem(storage.starterChest)
		player.giveItem(storage.starterLegs)
	end
end


function setStage(newStage)
	if newStage ~= self.missionStage then
		if newStage == 1 then
			self.hasLounged = false
--			setPester("gic_realisticfloranintro_getuppester", 20)
			quest.setObjectiveList({{config.getParameter("descriptions.findbearing"), false}})
--splitter
		elseif newStage == 2 then
			setPester()
			quest.setObjectiveList({{config.getParameter("descriptions.eldermeeting"), false}})
--splitter
		elseif newStage == 3 then
    		quest.setIndicators({"beamaxe"})
		    world.sendEntityMessage(entity.id(), "playCinematic", config.getParameter("reinforcelegionCinematic"))
--splitter
		elseif newStage == 4 then
			player.giveEssentialItem("beamaxe", "beamaxe")
			world.sendEntityMessage(entity.id(), "playCinematic", "/cinematics/intro/gic_realisticfloran_intro_beamaxe/gic_realisticfloran_intro_beamaxe.cinematic")
			quest.setObjectiveList({{config.getParameter("descriptions.landingzonebattle"), false}})
--splitter
		elseif newStage == 7 then
    		quest.setIndicators({"weaponChest"})
--splitter
		elseif newStage == 10 then
		    world.sendEntityMessage(entity.id(), "playCinematic", config.getParameter("endpointCinematic"))
			self.missionCompleteTimer = 2.0
--splitter
		end
		self.missionStage = newStage
	end
end

function updateStage(dt)
	if self.missionStage == 1 then
		if self.hasLounged == false then
			local loungeables = world.loungeableQuery(entity.position(), 10, {order = "nearest"})
			if #loungeables > 0 then
				self.hasLounged = player.lounge(loungeables[1])
			end
		end

		if self.hasLounged and not player.isLounging() then
			setStage(2)
		end
	elseif player.hasItem("brokenprotectoratebroadsword") and self.missionStage < 8 then
		quest.setIndicators({})
		setStage(8)
	elseif self.missionStage == 10 then
		if self.missionCompleteTimer > 0 then
			 self.missionCompleteTimer = self.missionCompleteTimer - dt
			 if self.missionCompleteTimer <= 0 then
					 player.warp("ownship")
					 quest.complete()
			 end
		end
	end
end


function stageEnterArea(areaName)
--splitter - immediately transitions to this after waking
	if areaName == "eldermeeting" then
		setStage(2)
		player.radioMessage("gic_realisticfloranintro_eldermeeting")
--splitter
	elseif areaName == "pushup" then
		player.radioMessage("gic_realisticfloranintro_pushup")
		quest.setObjectiveList({{config.getParameter("descriptions.pushup"), false}})
--splitter
	elseif areaName == "devolvingsituation" then
		player.radioMessage("gic_realisticfloranintro_devolvingsituation")
--splitter Enter Bunker then told to find MM / Reinforce legion.
	elseif areaName == "findbeamaxe" then
		setStage(3)
--		player.radioMessage("gic_realisticfloranintro_findmattermanipulator")
		quest.setObjectiveList({{config.getParameter("descriptions.matterManipulator"), false}})
--splitter - Pick up MM
	elseif areaName == "beamaxe" then
		player.radioMessage("gic_realisticfloranintro_mattermanipulatortutorial")
--splitter
	elseif areaName == "Incoming" then
		player.radioMessage("gic_realisticfloranintro_incoming")
		quest.setObjectiveList({{config.getParameter("descriptions.escape"), false}})
		setStage(7)
--splitter
	elseif areaName == "checks" then
		player.radioMessage("gic_realisticfloranintro_checks")
--splitter
	elseif areaName == "ship" then
		setStage(10)
	end
end

function setPester(messageId, timeout)
	self.pesterMessage = messageId
	self.pesterTimer = timeout or 0
end

function updatePester(dt)
	if self.pesterTimer > 0 then
		self.pesterTimer = self.pesterTimer - dt
		if self.pesterTimer <= 0 then
			player.radioMessage(self.pesterMessage)
		end
	end
end
