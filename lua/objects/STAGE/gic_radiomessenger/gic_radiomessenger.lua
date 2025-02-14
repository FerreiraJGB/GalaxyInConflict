require "/scripts/util.lua"

function init()
  --self = config.getParameter("spawner")
  self.uses = 0

  --object.setInteractive(self.trigger == "interact")
  --self.position = object.toAbsolutePosition(self.position)
  --storage.cooldown = storage.cooldown or util.randomInRange(self.frequency or {0, 0})
  --storage.stock = storage.stock or self.stock
end

function update(dt)
	local uses = config.getParameter("uses") or 1
    if object.getInputNodeLevel(0) and not self.activated and self.uses < uses then
      radiomessage()
	end
	
	self.activated = object.getInputNodeLevel(0)
end

function radiomessage()
    local players = world.playerQuery(object.position(), config.getParameter("range") or 50, {})
	local radioMessage = config.getParameter("radioMessages")
	radioMessage = util.randomFromList(radioMessage)
	for i in ipairs(players) do
      world.sendEntityMessage(players[i], "queueRadioMessage", radioMessage)
    end
	
	self.uses = self.uses + 1
end
