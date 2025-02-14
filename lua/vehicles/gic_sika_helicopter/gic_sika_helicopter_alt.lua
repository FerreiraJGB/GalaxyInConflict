require("/scripts/vec2.lua")
require("/vehicles/gic_sika_helicopter/gic_sika_helicopter.lua")

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit
local oldMove = move

local aimAngle2 = 0

function init()
  oldInit()
  
  self.rocketsLoaded = 9
  self.rocketReloadTimer = 0.5--2.0
  
  self.autocannonTimer = 0
  self.autocannonAmmo = 12
  self.autocannonReloadTimer = 1.0
  
  self.autocannonReloadTimerDefault = 1.0 --1.0s to reload an autocannon shell
end

-- override old movement stuff (well more of appending rather than override)
function move()
  local notDriverM1Held = (not vehicle.controlHeld("drivingSeat","primaryFire"))
  
  if self.driver and self.rocketsLoaded < 9 then
	local updateDt = script.updateDt()
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
  
  
  if self.driver and self.autocannonAmmo < 12 then
	if not vehicle.controlHeld("drivingSeat","primaryFire") then self.autocannonReloadTimer = self.autocannonReloadTimer - script.updateDt() end
		
	if self.autocannonReloadTimer <= 0 then
		self.autocannonAmmo = self.autocannonAmmo + 1
		self.autocannonReloadTimer = self.autocannonReloadTimerDefault
		animator.setSoundVolume("autocannonReload",2)
		animator.playSound("autocannonReload")
	end
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
 
 if vehicle.controlHeld("drivingSeat","primaryFire") and (self.rocketsLoaded > 0 or self.autocannonAmmo > 0) then
	local facingMulti = 0
	if self.facingDirection == -1 then facingMulti = 1 end
	
	-- rockets
	if self.rocketpodTimer <= 0 and self.rocketsLoaded > 0 then
		world.spawnProjectile(config.getParameter("rocketpodProjectile"), vec2.add(mcontroller.position(), animator.partPoint("rocketPodPosition", "firePoint")), entity.id(), {math.cos(self.angle+math.pi*facingMulti), math.sin(self.angle+math.pi*facingMulti)}, false, config.getParameter("rocketpodProjectileConfig"))
		self.rocketsLoaded = self.rocketsLoaded - 1
		--world.spawnProjectile(config.getParameter("rocketpodProjectile"), vec2.add(mcontroller.position(), animator.partPoint("rocketPodPosition", "firePoint")), entity.id(), aimVector(podAngle,0.01), false, config.getParameter("rocketpodProjectileConfig"))
		self.rocketpodTimer = config.getParameter("rocketpodCycle")
		animator.playSound("rocketpodFire")
	end
	
	-- autocannons
	if self.autocannonTimer <= 0 then
		world.spawnProjectile(config.getParameter("autocannonProjectile"), vec2.add(mcontroller.position(), animator.partPoint("autocannonPosition", "firePoint")), entity.id(), {math.cos(self.angle+math.pi*facingMulti), math.sin(self.angle+math.pi*facingMulti)}, false, config.getParameter("autocannoProjectileConfig"))
		self.autocannonAmmo = self.autocannonAmmo - 1
		self.autocannonTimer = config.getParameter("autocannonCycle")
		animator.playSound("autocannonFire")
		animator.setAnimationState("autocannonFiring", "fire")
	end
 end
 
 if self.rocketpodTimer > 0 and vehicle.entityLoungingIn("drivingSeat") then self.rocketpodTimer = self.rocketpodTimer - script.updateDt() end
 if self.autocannonTimer > 0 and vehicle.entityLoungingIn("drivingSeat") then self.autocannonTimer = self.autocannonTimer - script.updateDt() end
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
  
  --local diff = world.distance(vehicle.aimPosition("drivingSeat"), vec2.add(mcontroller.position(),{(-4.75+10.625)*self.facingDirection , -4.85}))
  --diff[2] = diff[2] - 0.000366211 + 2.33
  --diff[1] = diff[1] - 4.875
  aimAngle = self.angle--math.atan(diff[2], diff[1])
  --if self.facingDirection < 0 then

   --if aimAngle > 0 then
     --aimAngle = math.max(aimAngle, math.pi - AimLimit + self.angle)
   --else
     --aimAngle = math.min(aimAngle, -math.pi + AimLimit + self.angle)
   --end
   
   --if vehicle.entityLoungingIn("drivingSeat") then
	--animator.rotateGroup("guns", math.pi - aimAngle + self.angle)
   --end
  --else
   --if aimAngle - self.angle > 0 then
     --aimAngle = math.min(aimAngle, AimLimit + self.angle)
   --else
    -- aimAngle = math.max(aimAngle, -AimLimit + self.angle)
   --end
   --if vehicle.entityLoungingIn("drivingSeat") then
	--animator.rotateGroup("guns", aimAngle - self.angle)
   --end
  --end
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

--override old applyDamage; heal at 2x the rate to compensate for 4x the health
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
