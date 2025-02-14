require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  -- if config.getParameter("key") == nil then
    -- activeItem.setInstanceValue("key", sb.makeUuid())
  -- end

  teleportUnviable, teleportViable, teleportCooldown = 1, 2, 3

  self.vehicleBoundingBox = config.getParameter("standBoundingBox")
  self.crouchBoundingBox = config.getParameter("crouchBoundingBox")

  self.teleportState = teleportCooldown

  self.respawnTimer = 0
  self.facingDirection = 0

  --updateIcon()
  animator.stopAllSounds("aimTeleport")
  animator.setAnimationState("mark", "inactive")
  activeItem.setScriptedAnimationParameter("teleportPreviewImage", config.getParameter("teleportPreviewImage"))
  activeItem.setScriptedAnimationParameter("teleportCrouchingPreviewImage", config.getParameter("teleportCrouchingPreviewImage"))
  activeItem.setScriptedAnimationParameter("teleportLimitOutlineImage", config.getParameter("teleportLimitOutlineImage"))
  activeItem.setScriptedAnimationParameter("teleportState", self.teleportState)
  
  self.primaryHeld = false;
  self.activateTeleport = false;
  
  self.aTarget = false; -- short for "assassination target". i'm fucking tired of typing "assassination" over and over again ok?
  
  --self.assassinsBlade = activeItem.callOtherHandScript("confirmAssassinsBlade") --THIS DOESN'T FUCKING WORK
  --sb.logInfo(sb.printJson(self.assassinsBlade))
  
  --if self.assassinsBlade then
	activeItem.callOtherHandScript("resetVars") --VAR'S DON'T PROPER RESET IN INIT OF SWORD FOR SOME REASON????
  --end
end

function activate(fireMode, shiftHeld)
    if fireMode == "primary" and not self.primaryHeld and not status.resourceLocked("energy") then
		self.activateTeleport = true;
		animator.playSound("aimTeleport")
    end
  --updateIcon()
end

function update(dt, fireMode)
   self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
   activeItem.setFacingDirection(self.facingDirection)
   
   activeItem.setArmAngle(self.aimAngle)
  
  
   if self.activateTeleport then
	findPossibleAssasinationTarget()
	if placementValid() and world.magnitude(mcontroller.position(), activeItem.ownerAimPosition()) <= 20 then
		self.teleportState = teleportViable
		
		--if self.assassinsBlade then
			--sb.logInfo(sb.printInfo(self.assassinsBlade))
			--findPossibleAssasinationTarget()
		--end
	else
		self.teleportState = teleportUnviable
		
		--if self.assassinsBlade then
			--if activeItem.callOtherHandScript("assassinateWinded") then
				--activeItem.callOtherHandScript("assassinateUnwind")
			--end
		--end
	end
   else
	self.teleportState = teleportCooldown
	animator.stopAllSounds("aimTeleport")
	
	if activeItem.callOtherHandScript("assassinateWinded") then
		activeItem.callOtherHandScript("assassinateUnwind")
	end
   end

   self.primaryHeld = fireMode == "primary";
   
   --physical mark imgs
   if self.activateTeleport then
	animator.setAnimationState("mark", "active")
   else
	animator.setAnimationState("mark", "inactive")
   end
   
   if fireMode == "none" and self.activateTeleport then
	teleport();
   end
   
  activeItem.setScriptedAnimationParameter("teleportState", self.teleportState)
  activeItem.setScriptedAnimationParameter("crouching", mcontroller.crouching())
end

function findPossibleAssasinationTarget()
	local pos = activeItem.ownerAimPosition()
	local trackingDistance = 2.5
	if self.aTarget then trackingDistance = trackingDistance * 3 end
	local queryParameters = {withoutEntityId = entity.id(), includedTypes = {"creature"}, order = "nearest"}
	local candidates = world.entityQuery(pos, trackingDistance, queryParameters)
	
	self.aTarget = false;
	if #candidates == 0 then 
		if activeItem.callOtherHandScript("assassinateWinded") then
			activeItem.callOtherHandScript("assassinateUnwind")
		end
		return 
	end
	
	for _, candidate in ipairs(candidates) do
    if world.entityCanDamage(entity.id(), candidate) then
      local canPos = world.entityPosition(candidate)
      if not world.lineTileCollision(pos, canPos) then
		--sb.logInfo(sb.printJson(not activeItem.callOtherHandScript("assassinateWinding") and not activeItem.callOtherHandScript("assassinateWinded")))
		
		self.aTarget = true;
		if not activeItem.callOtherHandScript("assassinateWinding") and not activeItem.callOtherHandScript("assassinateWinded") then
			activeItem.callOtherHandScript("assassinateWindup")
		end
        return
      end
    end
	end
	
	if activeItem.callOtherHandScript("assassinateWinded") then
		activeItem.callOtherHandScript("assassinateUnwind")
	end
end

function teleport()
  if self.teleportState == teleportViable and status.overConsumeResource("energy", 50) then
		animator.playSound("placeOk")
		
		world.spawnProjectile("gic_plasmaimpact_medium_teleport", mcontroller.position())
		mcontroller.setPosition(activeItem.ownerAimPosition())
		world.spawnProjectile("gic_plasmaimpact_medium_teleport", mcontroller.position())
		
		self.teleportState = teleportCooldown

		activeItem.setScriptedAnimationParameter("teleportState", self.teleportState)
		
		if self.aTarget and activeItem.callOtherHandScript("assassinateWinded") then
			--sb.logInfo(sb.printJson(self.aTarget))
			activeItem.callOtherHandScript("assassinateAttack")
		end
     else
        animator.playSound("placeBad")
   end
   
   animator.stopAllSounds("aimTeleport")
   self.activateTeleport = false;
end

-- function updateIcon()
  -- if config.getParameter("filled") then
    -- animator.setAnimationState("controller", "full")
    -- activeItem.setInventoryIcon(config.getParameter("filledInventoryIcon"))
  -- else
    -- animator.setAnimationState("controller", "empty")
    -- activeItem.setInventoryIcon(config.getParameter("emptyInventoryIcon"))
  -- end
-- end

function placementValid()
  local aimPosition = activeItem.ownerAimPosition()

  if world.lineTileCollision(mcontroller.position(), aimPosition) then
    return false
  end
  
  local boundingBox = self.vehicleBoundingBox
  if mcontroller.crouching() then
	boundingBox = self.crouchBoundingBox
  end

  --check LOS from top of player, top of bound box at cursor
  if world.lineTileCollision(vec2.add(mcontroller.position(),{0,boundingBox[4]}), vec2.add(aimPosition,{0,boundingBox[4]})) then
    return false
  end

  --check LOS from bottom of player, bottom of bound box at cursor
  -- if world.lineTileCollision(vec2.add(mcontroller.position(),{0,self.vehicleBoundingBox[2]}), vec2.add(aimPosition,{0,self.vehicleBoundingBox[2]})) then
    -- return false
  -- end

  local vehicleBounds = {
    boundingBox[1] + aimPosition[1],
    boundingBox[2] + aimPosition[2],
    boundingBox[3] + aimPosition[1],
    boundingBox[4] + aimPosition[2]
  }

  if world.rectTileCollision(vehicleBounds, {"Null", "Block", "Dynamic", "Slippery"}) then
    return false
  end

  return true
end
