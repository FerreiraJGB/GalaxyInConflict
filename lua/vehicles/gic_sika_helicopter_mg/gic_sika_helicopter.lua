require("/scripts/vec2.lua")
require("/vehicles/gic_sika_helicopter/gic_sika_helicopter.lua")

local oldInit = init
local oldUpdate = update
--local oldUnInit = uninit

local aimAngle2 = 0

function init()
  oldInit()
  self.fireTimer2 = 0
  self.unhookBuffer = 0
  self.id = entity.id()
  self.hookedEntity = nil
  
  -- override old function
  message.setHandler("gic_boardFollower",
      function(_, _, uuid, npcId)
  			if vehicle.entityLoungingIn("drivingSeat") ~= nil then 
				if world.entityUniqueId(vehicle.entityLoungingIn("drivingSeat")) == uuid then
					self.boardFollower = npcId
				end
			end
	  end)
  -- setup boarding follower functionality (largely ripped from the shuttlecraft mod)
  message.setHandler("gic_boardGunnerFollower",
      function(_, _, uuid, npcId)
  			if vehicle.entityLoungingIn("drivingSeat") ~= nil then 
				if world.entityUniqueId(vehicle.entityLoungingIn("drivingSeat")) == uuid then
					self.boardGunnerFollower = npcId
				end
			end
	  end)
  self.gunnerAimPos = vehicle.aimPosition("passengerSeat2");
  
  message.setHandler("confirmHooked",
      function(_, _, id)
		self.hookedEntity = id
      end)
	  
  message.setHandler("unhook",
      function(_, _)
		self.hookedEntity = nil
      end)
end

-- basically ripped from the shuttlecraft mod, edited and such for this vehicle's purposes though.
function gunnerFollowerEmbark(npcId)
			local driverSeat = "drivingSeat"
			local boardSeat = nil

			if world.entityType(npcId) == "npc" then
				if vehicle.entityLoungingIn(driverSeat) ~= nil then 
					if vehicle.entityLoungingIn("passengerSeat2") == nil and boardSeat == nil then 
						boardSeat = 3
					end 
				end 
				if boardSeat ~= nil then 
						local beamin = false 
						if world.magnitude(world.entityPosition(npcId), mcontroller.position()) >= 20 then beamin = true end
						world.callScriptedEntity(npcId, "setShuttlecraftLounge", entity.id(), boardSeat, beamin )
				end
			end
	self.boardGunnerFollower = nil
end

function aiTargeting()
	--world.debugLine(vec2.add(animator.partPoint("frontGun", "firePoint"), mcontroller.position()), self.copilotTargetPos, {255,0,0,255})
	
	-- DUAL MACHINEGUNS
	self.aiFireMachineguns = false
	if vehicle.entityLoungingIn("copilotSeat") == nil or world.entityType(vehicle.entityLoungingIn("copilotSeat")) ~= "npc" then
		self.copilotTargetPos = vehicle.aimPosition("copilotSeat")
	else
		local npcId = vehicle.entityLoungingIn("copilotSeat")
		
		-- ok most of this is my own stuff but the base targeting code is ripped from the shuttlecraft mod
		-- anyways just also wanted to say that this stuff is cool, since *you can pull many functions from the NPC*, many more than I had thought possible!
		-- cool stuff since yeah main thing is that the AI targeting priorities here will be based off the targeting priorities of the NPC itself!
		
		local range = 100 -- this is GiC, crank that range number way up boyo
		local targetList = world.entityQuery(mcontroller.position(), range, {withoutEntityId = npcId,includedTypes = {"npc", "monster", "player"}, order = "nearest"})
		local validTarget = nil
		if targetList[1] ~= nil then -- were we able to find valid targets?
			for i = 1, #targetList do 
				if world.callScriptedEntity(npcId, "entity.isValidTarget", targetList[i]) and world.callScriptedEntity(npcId, "entity.entityInSight", targetList[i]) then 
					--if not checkSeatsForEntity(targetList[i]) then
						validTarget = targetList[i]
						--sb.logInfo(sb.printJson(world.entityHealth(targetList[i])[2]))
						--sb.logInfo(sb.printJson(validTarget))
						break
					--end
				end
			end
			
			
			if validTarget ~= nil then
				self.aiFireMachineguns = true --trigger firing of machine guns
				
				self.copilotTargetPos = world.entityPosition(validTarget)
				--sb.logInfo(sb.printJson(validTarget))
				--world.debugLine(vec2.add(animator.partPoint("frontGun", "firePoint"), mcontroller.position()), world.entityPosition(validTarget), {0,255,0,255})
			end
		end
	end
	
	
	--world.debugLine(vec2.add(animator.partPoint("sideGun", "firePoint"), mcontroller.position()), self.gunnerAimPos, {255,0,0,255})
	-- SIDE MACHINEGUN
	self.aiFireSidegun = false
	if vehicle.entityLoungingIn("passengerSeat2") == nil or world.entityType(vehicle.entityLoungingIn("passengerSeat2")) ~= "npc" then
		self.gunnerAimPos = vehicle.aimPosition("passengerSeat2")
	else
		local npcId = vehicle.entityLoungingIn("passengerSeat2")
		
		-- ok most of this is my own stuff but the base targeting code is ripped from the shuttlecraft mod
		-- anyways just also wanted to say that this stuff is cool, since *you can pull many functions from the NPC*, many more than I had thought possible!
		-- cool stuff since yeah main thing is that the AI targeting priorities here will be based off the targeting priorities of the NPC itself!
		
		local range = 100 -- suitable range to engage enemy targets the side 50 cal gun
		local targetList = world.entityQuery(mcontroller.position(), range, {withoutEntityId = npcId,includedTypes = {"npc", "monster", "player"}, order = "nearest"})
		local validTarget = nil
		if targetList[1] ~= nil then -- were we able to find valid targets?
			for i = 1, #targetList do 
				if world.callScriptedEntity(npcId, "entity.isValidTarget", targetList[i]) and world.callScriptedEntity(npcId, "entity.entityInSight", targetList[i]) then 
					validTarget = targetList[i]
					break
				end
			end
			
			
			if validTarget ~= nil then
				local pos = vec2.add(mcontroller.position(),animator.partPoint("sideGun", "firePoint"))
				local canPos = world.entityPosition(validTarget)
				local diff = world.distance(vec2.add({0,3.2},canPos), pos)
				local aimAngle = math.atan(diff[2], diff[1])
				
				local facing = 0
				if world.distance(vehicle.aimPosition("drivingSeat"), mcontroller.position())[1] > 0 and storage.health > 0 then
					facing = 1
				else
					facing = -1
				end
				
				local gunAngle = animator.currentRotationAngle("sidegun")
				if facing < 0 then gunAngle = math.pi - gunAngle + self.angle
				else
					gunAngle = gunAngle + self.angle
				end
				
				
				local toTarget = vec2.angle(world.distance(canPos, pos))
				local toTargetAngle = util.angleDiff(gunAngle, toTarget % (2*math.pi))
				
				if math.abs(toTargetAngle) <= (15 * math.pi / 180) then --15 degrees of lenience
					self.aiFireSidegun = true --trigger firing of machine guns
				end
				
				self.gunnerAimPos = world.entityPosition(validTarget)
				--sb.logInfo(sb.printJson(validTarget))
				--world.debugLine(vec2.add(animator.partPoint("sideGun", "firePoint"), mcontroller.position()), world.entityPosition(validTarget), {0,255,0,255})
			end
		end
	end
end

function update()
  oldUpdate()
  
  if not (animator.animationState("movement") == "invisible") and not (animator.animationState("movement") == "warpInPart1" or animator.animationState("movement") == "warpOutPart2") then
    local driverThisFrame = vehicle.entityLoungingIn("drivingSeat")
	
	-- gunner specific loading
	if (driverThisFrame) and self.boardGunnerFollower then gunnerFollowerEmbark(self.boardGunnerFollower) end 

    if (driverThisFrame ~= nil) then
      vehicle.setDamageTeam(world.entityDamageTeam(driverThisFrame))
    elseif vehicle.entityLoungingIn("copilotSeat") then
	  vehicle.setDamageTeam(world.entityDamageTeam(vehicle.entityLoungingIn("copilotSeat")))
	elseif vehicle.entityLoungingIn("passengerSeat2") then
	  vehicle.setDamageTeam(world.entityDamageTeam(vehicle.entityLoungingIn("passengerSeat2")))
	else
      vehicle.setDamageTeam({type = "passive"})
    end
  end
  
  hookControls()
end

function updateDoor()
	return
end

function hookControls()
	if (vehicle.controlHeld("drivingSeat","PrimaryFire")) and self.hookedEntity then
		self.hookedEntity = nil
		self.unhookBuffer = 1.0
	end
	
	self.unhookBuffer = (math.max(0,self.unhookBuffer - script.updateDt()))
end

function controls()
  -- GUN STUFF
 --if self.fireTimer >= 0 then self.fireTimer = self.fireTimer - script.updateDt()end
 
 if (vehicle.controlHeld("copilotSeat","PrimaryFire") or self.aiFireMachineguns) then
   if self.fireTimer <= 0 then
    world.spawnProjectile(shuttleProjectile, vec2.add(mcontroller.position(), animator.partPoint("frontGun", "firePoint")), entity.id(), aimVector(aimAngle,0.02), false, shuttleProjectileConfig)
    self.fireTimer = self.fireTimer + shuttleFireCycle
    animator.setAnimationState("frontFiring", "fire")
   else
    local oldFireTimer = self.fireTimer
    self.fireTimer = self.fireTimer - script.updateDt()
    if oldFireTimer > shuttleFireCycle / 2 and self.fireTimer <= shuttleFireCycle / 2 then
      world.spawnProjectile(shuttleProjectile, vec2.add(mcontroller.position(), animator.partPoint("backGun", "firePoint")), entity.id(), aimVector(aimAngle,0.02), false, shuttleProjectileConfig)
      animator.setAnimationState("backFiring", "fire")
    end
   end
 end
 
 
 if self.fireTimer2 > 0 then self.fireTimer2 = self.fireTimer2 - script.updateDt()end
 if (vehicle.controlHeld("passengerSeat2","PrimaryFire") or self.aiFireSidegun) then
   if self.fireTimer2 <= 0 then
    world.spawnProjectile("gic_redtracerbullet_heavy_a_machinegun", vec2.add(mcontroller.position(), animator.partPoint("sideGun", "firePoint")), entity.id(), aimVector(aimAngle2,0.03), false, shuttleProjectileConfig)
    self.fireTimer2 = self.fireTimer2 + 0.15 --0.2
    animator.setAnimationState("sideFiring", "fire")
   end
 end
end

local oldAnimate = animate
function animate()
  oldAnimate()
  
  animator.resetTransformationGroup("flip")
  if self.facingDirection < 0 then
    animator.scaleTransformationGroup("flip", {-1, 1})
  end

  animator.resetTransformationGroup("rotation")
  animator.rotateTransformationGroup("rotation", self.angle)

  -- GUN ANIMATION STUFF
  
  local aimLimit2 = math.pi/180 * 60
  local diff = world.distance(self.gunnerAimPos, vec2.add(mcontroller.position(),{(-4.75+6.35)*self.facingDirection , -3.0}))
  --diff[2] = diff[2] - 0.000366211 + 2.33
  --diff[1] = diff[1] - 4.875
  aimAngle2 = math.atan(diff[2], diff[1])
  if self.facingDirection < 0 then

   if aimAngle2 > 0 then
     aimAngle2 = math.max(aimAngle2, math.pi - aimLimit2 + self.angle)
   else
     aimAngle2 = math.min(aimAngle2, -math.pi + aimLimit2 + self.angle)
   end
   
   if vehicle.entityLoungingIn("passengerSeat2") then
	animator.rotateGroup("sidegun", math.pi - aimAngle2 + self.angle)
   end
  else
   if aimAngle2 - self.angle > 0 then
     aimAngle2 = math.min(aimAngle2, aimLimit2 + self.angle)
   else
     aimAngle2 = math.max(aimAngle2, -aimLimit2 + self.angle)
   end
   if vehicle.entityLoungingIn("passengerSeat2") then
	animator.rotateGroup("sidegun", aimAngle2 - self.angle)
   end
  end
  
  updateHook()
end

local oldMove = move
function move()
	oldMove()
end

function updateHook()
	if self.facingDirection < 0 then
		animator.rotateGroup("hook", 0 + self.angle)
	else
		animator.rotateGroup("hook", 0 - self.angle)
	end
	
	--world.debugText("test", mcontroller.position(), {0, 255, 0, 255})
	world.debugPoint(vec2.add(animator.partPoint("grapplehook", "hook"),mcontroller.position()), {0, 255, 0, 255})
	
	--world.sendEntityMessage(`Variant<EntityId, String>` entityId, `String` messageType, [`LuaValue` args ...])
	
	if self.unhookBuffer == 0 then
		if self.hookedEntity then
			world.debugText("hooked", mcontroller.position(), {0, 255, 0, 255})
			animator.setGlobalTag("hookState", 2)
			mcontroller.accelerate({0,-15})
			world.sendEntityMessage(self.hookedEntity, "lockHook", vec2.add(animator.partPoint("grapplehook", "hook"),mcontroller.position()),self.id)
		else
			animator.setGlobalTag("hookState", 1)
			lockhook()
		end
	else
		animator.setGlobalTag("hookState", 1)
	end
end

function lockhook()
	local candidates = world.entityQuery(vec2.add(animator.partPoint("grapplehook", "hook"),mcontroller.position()), 5, {withoutEntityId = self.id,
    includedTypes = {"vehicle"}})
	
	for _, candidate in ipairs(candidates) do
		world.sendEntityMessage(candidate, "lockHook", vec2.add(animator.partPoint("grapplehook", "hook"),mcontroller.position()),self.id)
		--world.callScriptedEntity(storage.projectileIds[1], "forceReturn")
	end
end

function uninit()
end
