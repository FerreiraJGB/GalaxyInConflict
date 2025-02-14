--Yo if anyone is reading this all of this belongs to the Elithian Races mod. Pls no destroy me.
-- and then this got modified by Echo/SirBucketKicker

function init()
	self.targetID = 0

	message.setHandler("gic_confirmStat",
      function(_, _, result)
		-- sb.logInfo("pass switch confirm received from player")
		-- sb.logInfo("pass switch result: " .. sb.printJson(result))
		if (result >= 1) then
			-- sb.logInfo("pass switch confirmed received stat status result, result valid")
			
			-- consume key item if desired
			if config.getParameter("consumeItem", false) then
				-- forceful conversion to int using math.floor() ??
				world.sendEntityMessage(math.floor(self.targetID), "gic_consumeItem", self.requiredItem)
			end
			
			output(true)
			animator.playSound("on")
			storage.timer = self.activeTime
			object.setInteractive(config.getParameter("interactive", false))
		end
	  end)

  --Set the item required for succesful interaction
  self.requiredItem = config.getParameter("requiredItem")
  
  --Ensure that the object can be interacted with
  object.setInteractive(config.getParameter("interactive", true))
  
  --Set the initial state
  if storage.state == nil then
    output(config.getParameter("defaultSwitchState", false))
  else
    output(storage.state)
  end
  
  --Set up the timer function
  if storage.timer == nil then
    storage.timer = 0
  end
  
  --Set the time to remain active after being activated
  self.activeTime = config.getParameter("activeTime")
end

function state()
  return storage.state
end

function onInteraction(args)
  local playerId = args.sourceId
  if storage.state == false and world.entityHasCountOfItem(playerId, self.requiredItem) > 0 then
	
	-- set up object to await a call from player, confirming whether stat is valid or not
	if config.getParameter("confirmStat") then
		-- sb.logInfo("checking if stat " .. sb.printJson(config.getParameter("checkStat")) .. " exists")
		world.sendEntityMessage(math.floor(args.sourceId), "gic_checkStat", entity.id(), config.getParameter("checkStat"))
		self.targetID = args.sourceId
		return
	end
	
	-- consume key item if desired
    if config.getParameter("consumeItem", false) then
	    -- forceful conversion to int using math.floor() ??
		world.sendEntityMessage(math.floor(args.sourceId), "gic_consumeItem", self.requiredItem)
	end
	
	output(true)

	animator.playSound("on")
	storage.timer = self.activeTime
	object.setInteractive(config.getParameter("interactive", false))
  else
	animator.playSound("off")
  end
end

function output(state)
  if storage.state ~= state then
    storage.state = state
    object.setAllOutputNodes(state)
    if state then
      animator.setAnimationState("switchState", "on")
      --animator.playSound("on")
    else
      animator.setAnimationState("switchState", "off")
      --animator.playSound("off")
    end
  else
  end
end

function update(dt)
  if storage.timer > 0 then
    -- storage.timer = math.max(0, storage.timer - dt)
	-- don't tick timer at all

	-- toggle on
	animator.setAnimationState("switchState", "on")
	object.setInteractive(config.getParameter("interactive", false))

    if storage.timer == 0 then
      output(false)
    end
  end
end
