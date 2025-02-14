function init()
  setDirection(storage.doorDirection or object.direction())

  self.sensorConfig = config.getParameter("sensorConfig")
  if self.sensorConfig then
    self.sensorConfig.detectEntityTypes = self.sensorConfig.detectEntityTypes or {"Player", "Npc"}
    self.sensorConfig.detectBoundMode = self.sensorConfig.detectBoundMode or "CollisionArea"
    self.sensorConfig.detectDuration = self.sensorConfig.detectDuration or 3
    self.sensorConfig.detectTimer = 0
    local detectArea = self.sensorConfig.detectArea
    local pos = object.position()
    if not detectArea or detectArea == "horizontal" then
      local bb = object.boundBox()
      self.sensorConfig.detectArea = {
        {bb[1] - 1, bb[2] + 0},
        {bb[3] + 1, bb[4] - 0}
      }
    elseif detectArea == "vertical" then
      local bb = object.boundBox()
      self.sensorConfig.detectArea = {
        {bb[1] + 1, bb[2] - 4},
        {bb[3] - 1, bb[4] + 4}
      }
    elseif type(detectArea[2]) == "number" then
      --center and radius
      self.sensorConfig.detectArea = {
        {pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
        detectArea[2]
      }
    elseif type(detectArea[2]) == "table" and #detectArea[2] == 2 then
      --rect corner1 and corner2
      self.sensorConfig.detectArea = {
        {pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
        {pos[1] + detectArea[2][1], pos[2] + detectArea[2][2]}
      }
    end
  end

  if storage.locked == nil then
    storage.locked = config.getParameter("locked", false)
  end

  if storage.state == nil then
    if config.getParameter("defaultState") == "open" then
      openDoor()
    else
      closeDoor()
    end
  else
    animator.setAnimationState("doorState", storage.state and "open" or "closed")
  end

  updateCollisionAndWires()
  updateInteractive()
  updateLight()

  message.setHandler("openDoor", function() openDoor() end)
  message.setHandler("closeDoor", function() closeDoor() end)
  message.setHandler("lockDoor", function() lockDoor() end)
  
  self.lockdown = false
  self.forcedLockdown = false
  
  self.unlockTimer = 2
  self.lockTimer = 2
end

function update(dt)
  if self.sensorConfig then
    self.sensorConfig.detectTimer = math.max(0, self.sensorConfig.detectTimer - dt)

    if not storage.locked and not object.isInputNodeConnected(0) then
      local entityIds = world.entityQuery(self.sensorConfig.detectArea[1], self.sensorConfig.detectArea[2], {
          withoutEntityId = entity.id(),
          includedTypes = self.sensorConfig.detectEntityTypes,
          boundMode = self.sensorConfig.detectBoundMode
        })

      if #entityIds > 0 then
        self.sensorConfig.detectTimer = self.sensorConfig.detectDuration
      end

      if self.sensorConfig.detectTimer > 0 then
        openDoor()
      else
        closeDoor()
      end
    end
  end
  
  
  if self.queUnlock == true then
	self.unlockTimer = self.unlockTimer - 0.05
	
	if self.unlockTimer <= 0 then
		self.queUnlock = false
		self.lockdown = false
		updateCollisionAndWires()
		
		if object.getInputNodeLevel(2) then
			openDoor(storage.doorDirection)
		end
	end
  end
  
  if self.queLock == true then
	self.lockTimer = self.lockTimer - 0.05
	
	if self.lockTimer <= 0 then
		self.queLock = false
		self.lockdown = true
		updateCollisionAndWires()
		
		if object.getInputNodeLevel(2) then
			closeDoor()
		end
	end
  end
end

function onNodeConnectionChange(args)
  updateInteractive()
  updateCollisionAndWires()
  if object.isInputNodeConnected(0) then
    onInputNodeChange({ level = object.getInputNodeLevel(0) })
  end
end

--input node 0 = button override input
--input node 1 = lockdown input
--input node 2 = normal proxy sensor input
--input node 3 = npc override sensor input

function onInputNodeChange(args)
  --sb.logInfo(sb.printJson(logInfo))
  local forceLockdown = (object.getInputNodeLevel(1))
  local npcOverride = object.getInputNodeLevel(3)
  local buttonToggle = object.getInputNodeLevel(0)
  --sb.logInfo(sb.printJson(lockdown).." lockdown")
  --sb.logInfo(sb.printJson(npcOverride).." npcOverride")
  --sb.logInfo(sb.printJson(buttonOverride).." buttonOverride")
  
  if forceLockdown and self.forcedLockdown == false and not npcOverride then
	self.forcedLockdown = true
	self.queUnlock = false
	--self.lockdown = true
	--closeDoor()
	self.queLock = true
	self.lockTimer = 2
	updateOutputs()
	return
  elseif not forceLockdown and self.forcedLockdown == true then
	self.forcedLockdown = false
	updateOutputs()
	--self.lockdown = false
	return
  end
  
  if args.level and npcOverride then
	if self.lockdown == true then
		--self.lockdown = false
		self.queUnlock = true
		self.queLock = false
		self.unlockTimer = 2
		updateOutputs()
	elseif self.queLock == true then
		self.queUnlock = true
		self.queLock = false
		self.unlockTimer = 2
		updateOutputs()
	elseif object.getInputNodeLevel(2) and self.lockdown == false then
		openDoor(storage.doorDirection)
	else
		closeDoor()
	end
  elseif args.level and buttonToggle and not npcOverride then 
	if self.lockdown == true then
		--self.lockdown = false
		self.queUnlock = true
		self.queLock = false
		self.unlockTimer = 2
		updateOutputs()
	else
		--self.lockdown = true
		self.queUnlock = false
		self.queLock = true
		self.lockTimer = 2
		updateOutputs()
	end
  elseif object.getInputNodeLevel(2) and self.lockdown == false then
	openDoor(storage.doorDirection)
  else
	closeDoor()
  end
end

function onInteraction(args)
  if storage.locked then
    animator.playSound("locked")
  else
    if not storage.state then
      openDoor(args.source[1])
    else
      closeDoor()
    end
  end
end

function updateLight()
  if not storage.state then
    object.setLightColor(config.getParameter("closedLight", {0,0,0,0}))
  else
    object.setLightColor(config.getParameter("openLight", {0,0,0,0}))
  end
end

function updateInteractive()
  object.setInteractive(false)
  --object.setInteractive(config.getParameter("interactive", true) and not self.sensorConfig and not object.isInputNodeConnected(0) and not storage.locked)
end

function updateCollisionAndWires()
  setupMaterialSpaces()
  object.setMaterialSpaces(storage.state and self.openMaterialSpaces or self.closedMaterialSpaces)
  
  updateOutputs()
end

function updateOutputs()
  --object.setOutputNodeLevel(0,storage.state)
  --object.setAllOutputNodes(storage.state)
  
  local outputState = (not self.lockdown)
  if self.queUnlock == true then 
	outputState = true 
  elseif self.queLock == true then 
	outputState = false 
  end
  
  object.setOutputNodeLevel(1,outputState)
  object.setOutputNodeLevel(0,storage.state)
end

function setupMaterialSpaces()
  self.closedMaterialSpaces = config.getParameter("closedMaterialSpaces")
  if not self.closedMaterialSpaces then
    self.closedMaterialSpaces = {}
    local metamaterial = "metamaterial:door"
    if object.isInputNodeConnected(0) then
      metamaterial = "metamaterial:lockedDoor"
    end
    for i, space in ipairs(object.spaces()) do
      table.insert(self.closedMaterialSpaces, {space, metamaterial})
    end
  end
  self.openMaterialSpaces = config.getParameter("openMaterialSpaces", {})
end

function setDirection(direction)
  storage.doorDirection = direction
  animator.setGlobalTag("doorDirection", direction < 0 and "Left" or "Right")
end

function hasCapability(capability)
  if capability == 'lockedDoor' then
    return storage.locked
  elseif object.isInputNodeConnected(0) or storage.locked or self.sensorConfig then
    return false
  elseif capability == 'door' then
    return true
  elseif capability == 'closedDoor' then
    return not storage.state
  elseif capability == 'openDoor' then
    return storage.state
  else
    return false
  end
end

function doorOccupiesSpace(position)
  local relative = {position[1] - object.position()[1], position[2] - object.position()[2]}
  for _, space in ipairs(object.spaces()) do
    if math.floor(relative[1]) == space[1] and math.floor(relative[2]) == space[2] then
      return true
    end
  end
  return false
end

function lockDoor()
  if not storage.locked then
    storage.locked = true
    updateInteractive()
    if storage.state then
      -- close door before locking
      storage.state = false
      animator.playSound("close")
      animator.setAnimationState("doorState", "locking")
      updateCollisionAndWires()
    else
      animator.setAnimationState("doorState", "locked")
    end
    return true
  end
end

function unlockDoor()
  if storage.locked then
    storage.locked = false
    updateInteractive()
    animator.setAnimationState("doorState", "closed")
    return true
  end
end

function closeDoor()
  if storage.state ~= false then
    storage.state = false
    updateInteractive()
    animator.playSound("close")
    animator.setAnimationState("doorState", "closing")
    updateCollisionAndWires()
    updateLight()
  end
end

function openDoor(direction)
  if not storage.state then
    storage.state = true
    storage.locked = false -- make sure we don't get out of sync when wired
    updateInteractive()
    setDirection((direction == nil or direction * object.direction() < 0) and -1 or 1)
    animator.playSound("open")
    animator.setAnimationState("doorState", "open")
    updateCollisionAndWires()
    updateLight()
  end
end
