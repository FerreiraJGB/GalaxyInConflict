require "/scripts/rect.lua"

function init()
	self.containsPlayers = {}
	self.broadcastArea = rect.translate(config.getParameter("broadcastArea", {-8, -8, 8, 8}), entity.position())
	self.signalRegion = rect.translate(config.getParameter("signalRegion", {-8, -8, 8, 8}), entity.position())
	message.setHandler("setSpecies", function(_, _, species) self.species = species end)
	world.setSkyTime(config.getParameter("goodTime"))
	self.hasUpdatedShip = false
	-- sb.logInfo("Initializing floranintro manager with broadcastArea %s", self.broadcastArea)
end

function update(dt)
	world.loadRegion(self.signalRegion)
	queryPlayers()
	if self.species and not self.hasUpdatedShip then
		local shipSearchArea = rect.translate({0, -500, 900, 500}, entity.position())
		local ships = world.objectQuery(rect.ll(shipSearchArea), rect.ur(shipSearchArea), {callScript = "setSpecies", callScriptArgs = {self.species}})
		self.hasUpdatedShip = #ships > 0
	end
end

function queryPlayers()
	local newPlayerList = world.entityQuery(rect.ll(self.broadcastArea), rect.ur(self.broadcastArea), {includedTypes = {"player"}})
	local newPlayers = {}
	for _, id in pairs(newPlayerList) do
		if not self.containsPlayers[id] then
			world.sendEntityMessage(id, "gic_realisticfloranintromanagerId", entity.id())
		end
		newPlayers[id] = true
	end
	self.containsPlayers = newPlayers
end
