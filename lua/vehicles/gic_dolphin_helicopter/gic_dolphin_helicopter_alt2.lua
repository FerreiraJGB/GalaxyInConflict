require("/scripts/vec2.lua")
require("/vehicles/gic_dolphin_helicopter/gic_dolphin_helicopter.lua")

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit
local oldMove = move

local aimAngle2 = 0

function init()
  oldInit()
end

-- override old movement stuff (well more of appending rather than override)
function move()
  if self.driver and self.rocketsLoaded < 9 then
	local updateDt = script.updateDt()
	local notDriverM1Held = (not vehicle.controlHeld("drivingSeat","primaryFire"))
	if notDriverM1Held  then self.rocketReloadTimer = self.rocketReloadTimer - updateDt end
		
	if self.rocketReloadTimer <= 0 then
		self.rocketsLoaded = self.rocketsLoaded + 1
		self.rocketReloadTimer = 0.5
		animator.setSoundVolume("rocketpodReload",2)
		animator.playSound("rocketpodReload")
	end
	
	-- to prevent double-timing reloads, as normal counter will do its thing in oldMove()
	if notDriverM1Held then self.rocketReloadTimer = self.rocketReloadTimer + updateDt end
  end
  
  oldMove()
end

-- override old controls
function controls()
  -- GUN STUFF
 --if self.fireTimer >= 0 then self.fireTimer = self.fireTimer - script.updateDt()end
 
 if (vehicle.controlHeld("drivingSeat","PrimaryFire")) then
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
 
 -- Seeker missile controls; pilot can use the seeker with [F], co-pilot can also use the seeker with [M2]. co-pilot takes priority over the pilot in case of controls.
 if vehicle.entityLoungingIn("copilotSeat") then
	
	-- shamelessly stolen from vanilla (guidedrocket ability), not that it even matters.
	self.missileIds = util.filter(self.missileIds, world.entityExists) -- filter out dead missiles
	local rocketTargetPosition = self.copilotTargetPos
	
	for _,missileId in pairs(self.missileIds) do
		world.callScriptedEntity(missileId, "setTarget", rocketTargetPosition)
	end
	-- end custom guided missile stuff
 
	-- standard "seek and destroy" capabilities
	if (vehicle.controlHeld("copilotSeat","Special1") or self.missileTarget ~= nil) and storage.missileLoaded == 1 then
		storage.missileLoaded = 2
		self.missileTimer = 5
		local facingMulti = 0
		if self.facingDirection == -1 then facingMulti = 1 end
		
		local params = {}
		
		if self.missileTarget ~= nil then
			params.initialTarget = findNearbyTarget(self.copilotTargetPos,30)
			params.initialTarget = findNearbyTarget(world.entityPosition(self.missileTarget),30)
		end
		
		world.spawnProjectile("gic_airtoair_missile_sika", vec2.add(mcontroller.position(), animator.partPoint("rocketPodPosition", "missileFirePoint")), entity.id(), {math.cos(self.angle+math.pi*facingMulti), math.sin(self.angle+math.pi*facingMulti)}, false, params)
		animator.playSound("rocketpodFire")
		animator.playSound("missileReload")
		
		animator.setGlobalTag("missilestatus","nomissile")
		animator.setGlobalTag("doorstatus","_nomissile")
		
	-- alternatively, right click to fire a missile that homes in on the copilot's cursor position! mfw TOW missile
	elseif (vehicle.controlHeld("copilotSeat","AltFire")) and storage.missileLoaded == 1 then
		
		storage.missileLoaded = 2
		self.missileTimer = 5
		local facingMulti = 0
		if self.facingDirection == -1 then facingMulti = 1 end
		
		local params = {}
		params.initialTarget = findNearbyTarget(self.copilotTargetPos,30)
		
		local spawnedMissile = world.spawnProjectile("gic_airtoair_guided_missile_sika", vec2.add(mcontroller.position(), animator.partPoint("rocketPodPosition", "missileFirePoint")), entity.id(), {math.cos(self.angle+math.pi*facingMulti), math.sin(self.angle+math.pi*facingMulti)}, false, params)
		
		table.insert(self.missileIds,spawnedMissile)
		--sb.logInfo(sb.printJson(spawnedMissile))
		
		animator.playSound("rocketpodFire")
		animator.playSound("missileReload")
		
		animator.setGlobalTag("missilestatus","nomissile")
		animator.setGlobalTag("doorstatus","_nomissile")
	
	end
	 
	if self.missileTimer > 0 then self.missileTimer = self.missileTimer - script.updateDt() end
	if self.missileTimer <= 0 and storage.missileLoaded == 2 then 
		animator.playSound("missileLoaded")
		storage.missileLoaded = 1
		animator.setGlobalTag("missilestatus","missile")
		animator.setGlobalTag("doorstatus","")
	end
	
 elseif vehicle.entityLoungingIn("drivingSeat") then
 
	if (vehicle.controlHeld("drivingSeat","Special1")) and storage.missileLoaded == 1 then -- press F to fire tracking missile; need to test later.
		storage.missileLoaded = 2
		self.missileTimer = 5
		local facingMulti = 0
		if self.facingDirection == -1 then facingMulti = 1 end
		
		local params = {}
		--params.initialTarget = findNearbyTarget(vehicle.aimPosition("copilotSeat"),30)
		params.initialTarget = findNearbyTarget(vehicle.aimPosition("drivingSeat"),30)
		
		world.spawnProjectile("gic_airtoair_missile_sika", vec2.add(mcontroller.position(), animator.partPoint("rocketPodPosition", "missileFirePoint")), entity.id(), {math.cos(self.angle+math.pi*facingMulti), math.sin(self.angle+math.pi*facingMulti)}, false, params)
		animator.playSound("rocketpodFire")
		animator.playSound("missileReload")
		
		animator.setGlobalTag("missilestatus","nomissile")
		animator.setGlobalTag("doorstatus","_nomissile")
	end
	 
	--if self.missileTimer > 0 and vehicle.entityLoungingIn("copilotSeat") then self.missileTimer = self.missileTimer - script.updateDt() end
	if self.missileTimer > 0 then self.missileTimer = self.missileTimer - script.updateDt() end
	if self.missileTimer <= 0 and storage.missileLoaded == 2 then 
		animator.playSound("missileLoaded")
		storage.missileLoaded = 1
		animator.setGlobalTag("missilestatus","missile")
		animator.setGlobalTag("doorstatus","")
	end
	
 end
 
 
 
  local diff = world.distance(vehicle.aimPosition("drivingSeat"), vec2.add(mcontroller.position(),{-1*self.facingDirection , -4}))
  local podAngle = math.atan(diff[2], diff[1])
  local podLimit = 10 * math.pi / 180
  if self.facingDirection < 0 then

   if podAngle > 0 then
     podAngle = math.max(podAngle, math.pi - podLimit + self.angle)
   else
     podAngle = math.min(podAngle, -math.pi + podLimit + self.angle)
   end
  else
   if podAngle - self.angle > 0 then
     podAngle = math.min(podAngle, podLimit + self.angle)
   else
     podAngle = math.max(podAngle, -podLimit + self.angle)
   end
  end
 
 if (vehicle.controlHeld("drivingSeat","Special2") and self.rocketsLoaded > 0) then
	local facingMulti = 0
	if self.facingDirection == -1 then facingMulti = 1 end
	
	if self.rocketpodTimer <= 0 then
		world.spawnProjectile(config.getParameter("rocketpodProjectile"), vec2.add(mcontroller.position(), animator.partPoint("rocketPodPosition", "firePoint")), entity.id(), {math.cos(self.angle+math.pi*facingMulti), math.sin(self.angle+math.pi*facingMulti)}, false, config.getParameter("rocketpodProjectileConfig"))
		self.rocketsLoaded = self.rocketsLoaded - 1
		--world.spawnProjectile(config.getParameter("rocketpodProjectile"), vec2.add(mcontroller.position(), animator.partPoint("rocketPodPosition", "firePoint")), entity.id(), aimVector(podAngle,0.01), false, config.getParameter("rocketpodProjectileConfig"))
		self.rocketpodTimer = config.getParameter("rocketpodCycle")
		animator.playSound("rocketpodFire")
	end
 end
 
 if self.rocketpodTimer > 0 and vehicle.entityLoungingIn("drivingSeat") then self.rocketpodTimer = self.rocketpodTimer - script.updateDt()end
end

-- override old animation
function animate()
  animator.resetTransformationGroup("flip")
  if self.facingDirection < 0 then
    animator.scaleTransformationGroup("flip", {-1, 1})
  end

  animator.resetTransformationGroup("rotation")
  animator.rotateTransformationGroup("rotation", self.angle)

  -- GUN ANIMATION STUFF
  
  local diff = world.distance(vehicle.aimPosition("drivingSeat"), vec2.add(mcontroller.position(),{(-4.75+10.625)*self.facingDirection , -4.85}))
  --diff[2] = diff[2] - 0.000366211 + 2.33
  --diff[1] = diff[1] - 4.875
  aimAngle = math.atan(diff[2], diff[1])
  if self.facingDirection < 0 then

   if aimAngle > 0 then
     aimAngle = math.max(aimAngle, math.pi - AimLimit + self.angle)
   else
     aimAngle = math.min(aimAngle, -math.pi + AimLimit + self.angle)
   end
   
   if vehicle.entityLoungingIn("drivingSeat") then
	animator.rotateGroup("guns", math.pi - aimAngle + self.angle)
   end
  else
   if aimAngle - self.angle > 0 then
     aimAngle = math.min(aimAngle, AimLimit + self.angle)
   else
     aimAngle = math.max(aimAngle, -AimLimit + self.angle)
   end
   if vehicle.entityLoungingIn("drivingSeat") then
	animator.rotateGroup("guns", aimAngle - self.angle)
   end
  end
  -- GUN ANIMATION STUFF ENDING
  
  -- LIGHTS
  local copilot = vehicle.entityLoungingIn("copilotSeat")
  if copilot and world.entityType(copilot) == "npc" then
	local daytime = world.timeOfDay()
	self.headlightState = animator.animationState("headlights")
	
	if daytime >= 0.5 and self.headlightState ~= "on" then --AI will turn lights on automatically when night is setting
		animator.playSound("headlightSwitchOff")
		animator.setLightActive("headlightBeam", true)
		animator.setAnimationState("headlights", "on")
	elseif daytime < 0.5 and self.headlightState ~= "off" then
		animator.playSound("headlightSwitchOff")
		animator.setLightActive("headlightBeam", false)
		animator.setAnimationState("headlights", "off")
	end
	
  elseif vehicle.controlHeld("copilotSeat", "up") then
      if self.headlightCanToggle then
	  
		self.headlightState = animator.animationState("headlights")
		if self.headlightState == "on" then
			animator.playSound("headlightSwitchOff")
			animator.setLightActive("headlightBeam", false)
			animator.setAnimationState("headlights", "off")
		else
			animator.playSound("headlightSwitchOn")
			animator.setLightActive("headlightBeam", true)
			animator.setAnimationState("headlights", "on")
			
		end
		self.headlightState = animator.animationState("headlights")
		
        self.headlightCanToggle = false
        end
      else
      self.headlightCanToggle = true
   end
end

--override old applyDamage; heal at 5x the rate to compensate for 4x the health (why 5x? because why not)
function applyDamage(damageRequest)
  local damage = 0
  
  local resistancesParam = config.getParameter("resistances")
  
  if damageRequest.damageSourceKind == "ews_melee" or damageRequest.damageType == "IgnoresDef" then
	if resistancesParam[damageRequest.damageSourceKind] then
		damage = damage + damageRequest.damage * (1 - resistancesParam[damageRequest.damageSourceKind])
	else
		damage = damage + damageRequest.damage
	end
  else
	
	if resistancesParam[damageRequest.damageSourceKind] then
		damage = damage + root.evalFunction2("protection", damageRequest.damage, config.getParameter("protection")) * (1 - resistancesParam[damageRequest.damageSourceKind])
	else
		damage = damage + root.evalFunction2("protection", damageRequest.damage, config.getParameter("protection"))
	end
  end
  if damageRequest.statusEffects and damageRequest.statusEffects[1] and damageRequest.statusEffects[1].effect == "gic_wrench" and storage.health > 0 then
	damage = 0
	if storage.health < self.maxHealth then
		local healthGained = math.min(200, self.maxHealth - storage.health)
		storage.health = storage.health + healthGained
	
		self.repairedHealth = healthGained
		self.queRepairText = true
	end
  end

	setDamageEmotes()
	updateVisualEffects(storage.health, damage, self.headlightsOn)


  local healthLost = math.min(damage, storage.health)
  storage.health = storage.health - healthLost

  return {{
    sourceEntityId = damageRequest.sourceEntityId,
    targetEntityId = entity.id(),
    position = mcontroller.position(),
    damageDealt = damage,
    healthLost = healthLost,
    hitType = "Hit",
    damageSourceKind = damageRequest.damageSourceKind,
    targetMaterialKind = self.materialKind,
    killed = storage.health <= 0
  }}
end

function update()
  oldUpdate()
end

function uninit()
end
