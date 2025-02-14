require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

Parry = WeaponAbility:new()

function Parry:init()
  self.cooldownTimer = 0
  self.shellLoaded = config.getParameter("shellLoaded",true)
  self.shells = config.getParameter("shells",4)
  self.shellsMax = 4
  
  self.ammoItem = "gic_1850x70mm_buckshot"
  
  self.lock = false
  animator.setGlobalTag("directives", "")
  --self.parryTimeTemp = self.parryTime
end

local altHeld = false
local altHoldTime = 0
local altHoldTmp = false
function Parry:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and fireMode == "alt"
	and not self.parryActive
    and self.cooldownTimer == 0 
	and status.resourcePositive("shieldStamina") then
    --and status.overConsumeResource("energy", self.energyUsage) then

    self.weapon:setStance(self.stances.parry)
	self.weapon:updateAim()
	self:setState(self.parry)
  elseif not shiftHeld and altHoldTime > 0
  and self.weapon.currentAbility == nil and self.shells < self.shellsMax and player.hasItem({name = self.ammoItem}) then
		
		--TAP ALT
		altHoldTmp = false
		altHoldTime = 0
		
		-- TODO - INSERT RELOAD ANIM HERE
		self:setState(self.reloadSpear)
		
		--self:setState(self.chargeSlash)
  elseif altHoldTmp == true and self.weapon.currentAbility == nil and altHoldTime == 0 and shiftHeld and self.lock == false and self.cooldownTimer == 0 then
  
		--HOLD ALT
		if self.shells > 0 and self.shellLoaded then
			self:setState(self.gunStance)
		elseif self.shells > 0 then
			self:setState(self.pumpSpear)
		elseif player.hasItem({name = self.ammoItem}) then
			self:setState(self.reloadSpear)
		end
		altHoldTmp = false
  end
  
  
  altHoldTime = math.max(0, altHoldTime - self.dt)
  if shiftHeld and altHoldTmp == false then
	altHoldTime = 0.15 --hold timer
	altHoldTmp = true
  end
  
  if altHoldTmp == true and altHoldTime == 0 and not shiftHeld then
	altHoldTmp = false
  end
  
  altHeld = shiftHeld
  
  
  if self.shellLoaded == true then
	activeItem.setCursor("/cursors/spearcursors/load" .. self.shells ..".cursor")
  else
	activeItem.setCursor("/cursors/spearcursors/unload" .. self.shells ..".cursor")
  end
  
  
  if fireMode == "alt" then
	self.fireModeTmp = 1
  else
	self.fireModeTmp = 0
  end
end

function Parry:parry()
  self.parryActive = true
  self.weapon:setStance(self.stances.parry)
  self.weapon:updateAim()
  self.parryTime = 999999
  status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = 99999}})
  --self.perfectBlockTime = 20 --ticks

  --status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = self.shieldHealth}})

  local blockPoly = animator.partPoly("parryShield", "shieldPoly")
  activeItem.setItemShieldPolys({blockPoly})

  animator.setAnimationState("parryShield", "active")
  --coroutine.yield()
  
  animator.playSound("guard")
  
  local counterAttackTrigger = false
  --
  local shieldHp = status.resource("shieldStamina")
  local damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 then
		if self.shieldTime <= self.perfectBlockTime and status.resource("shieldStamina") < shieldHp then
			animator.playSound("perfectBlock")
			
			self.shieldTime = 0
			status.setResource("shieldStamina", 1)
			
			--if self.shellLoaded == 1 then
				--counterAttackTrigger = true
			--end
		else
			animator.playSound("parry")
		end
        --animator.playSound("parry")
        animator.setAnimationState("parryShield", "block")
        return
      end
    end
	
	shieldHp = status.resource("shieldStamina")
  end)
  
  
  
  local perfectParryGone = false
  self.shieldTime = 0
  self.fireModeTmp = 1
  util.wait(self.parryTime, function(dt)
  
	--Interrupt when running out of shield stamina
	if not status.resourcePositive("shieldStamina") then 
		self.cooldownTimer = 1.5
		animator.playSound("break") 
		return true 
	end
	if self.fireModeTmp == 0 then 
		self.cooldownTimer = self.cooldownTime
		return true 
	end
	if counterAttackTrigger == true then
		return true
	end
  
	self.shieldTime = self.shieldTime + self.dt
	if self.shieldTime <= self.perfectBlockTime then
		animator.setGlobalTag("directives", "?border=2;AACCFFFF;00000000")
	else
		animator.setGlobalTag("directives", "")
		if perfectParryGone == false then
			status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = self.shieldHealth}})
			perfectParryGone = true
		end
	end
	
	damageListener:update()
  end)
  animator.setGlobalTag("directives", "")
  activeItem.setItemShieldPolys({})
  self.parryActive = false
  
  --if counterAttackTrigger == true then
	--status.clearPersistentEffects("broadswordParry")
	--self:setState(self.counterAttack);
  --end
end

function Parry:counterAttack()
	-- THIS COUNTER ATTACK IS NOW DEFUNCT. IGNORE FOR NOW, LEAVING IN CODE FOR LATER USE IF NEEDED.
	
	
	-- STANCE WILL BE BACKSTAB, WILL USE SWOOSH FOR DAMAGE AREA FOR NOW. --
	
	-- CLEAN UP PARALLEL SCRIPT STUFF, MAKE INTO PROPER PARALLEL SCRIPT LATER (IE MOVE MOVEMENTSUPPRESSE STUFF)
	animator.setAnimationState("parryShield", "inactive")
	
	status.setPersistentEffects("iframes", {{stat = "invulnerable", amount = 1}})
	
	self.weapon:setStance(self.stances.backstabWindup)
	self.weapon.aimDirection = self.weapon.aimDirection * -1
	self.weapon:updateAim()
	util.wait(0.25, function()
		mcontroller.controlModifiers({movementSuppressed = true})
	end)
	
	local damageConfig = self.damageConfig
	--damageConfig.baseDamage = damageConfig.baseDamage
	
	self.weapon:setStance(self.stances.backstab)
	self.weapon:updateAim()
	animator.playSound("fire")
	animator.setAnimationState("swoosh", "fire")
	util.wait(self.stances.backstab.duration, function()
		local damageArea = partDamageArea("swoosh")
		mcontroller.controlModifiers({movementSuppressed = true})
		self.weapon:setDamage(damageConfig, damageArea)
	end)
	
	--flip around, shoot
	self.weapon.aimDirection = self.weapon.aimDirection * -1
	self.weapon:setStance(self.stances.backstabShoot)
	self.weapon:updateAim()
	util.wait(0.15, function() 
		--mcontroller.controlModifiers({movementSuppressed = true})
		mcontroller.controlMove(0,0)
		mcontroller.controlCrouch()
	end)
	
	animator.playSound("gunFire")
	local fireOffset = vec2.add(mcontroller.position(), activeItem.handPosition({3.3,-0.5}))
	local params = {power=30}
	
	for i=0,5,1 do
		world.spawnProjectile("gic_redtracerbullet_heavy_c_nobleed", fireOffset,activeItem.ownerEntityId(),self:aimVector(0.05),false,params)
	end
	
	self.weapon:setStance(self.stances.backstabCooldown)
	util.wait(self.stances.backstabCooldown.duration, function() 
		--mcontroller.controlModifiers({movementSuppressed = true})
		mcontroller.controlMove(0,0)
		mcontroller.controlCrouch()
	end)
	
	mcontroller.clearControls();
	status.clearPersistentEffects("iframes")
end

function Parry:gunStance()
	self.lock = true
	self.weapon:setStance(self.stances.aimGun)
	--animator.setAnimationState("swoosh", "idle")
	
	util.wait(99999, function()
		self.weapon:updateAim()
		mcontroller.controlModifiers({runningSuppressed = true})
		if not altHeld == true then return true end
	end)
	
	animator.playSound("gunFire")
	local fireOffset = vec2.add(mcontroller.position(), activeItem.handPosition({3.3,-0.5}))
	local params = {power=40}
	
	animator.setParticleEmitterActive("muzzleFlash", true)
	animator.setParticleEmitterEmissionRate("muzzleFlash", 100)
	
	animator.setParticleEmitterActive("hotsmoke", true)
	animator.setParticleEmitterEmissionRate("hotsmoke", 100)
	
	self.shells = self.shells - 1
	activeItem.setInstanceValue("shells",self.shells)
	
	self.shellLoaded = false
	activeItem.setInstanceValue("shellLoaded",self.shellLoaded)
	
	local actionOnReapA = jarray()
	actionOnReapA[1] = {action = "config", file = "/projectiles/explosions/gic_smallexplosion/gic_smallexplosionknockback.config"}
	local spec = {type = "textured", image = "/particles/fog/1.png", position = {-1, 0}, layer = "front", timeToLive = 20, destructionTime = 3, destructionAction = "shrink", fullbright = false}
	actionOnReapA[2] = {time = 0.015, action = "particle", rotate = true, specification = spec}
	actionOnReapA[3] = actionOnReapA[2]
	
	world.spawnProjectile("gic_handcannon_immediate_a", fireOffset,activeItem.ownerEntityId(),self:aimVector(0.05),false,{power = 200, actionOnReap = actionOnReapA}) --power = 100
	for i=1,5,1 do
		world.spawnProjectile("gic_redtracerbullet_heavy_c_nobleed", fireOffset,activeItem.ownerEntityId(),self:aimVector(0.05),false,params)
	end
	
	self.weapon:setStance(self.stances.aimGunCooldown)
	
	util.wait(self.stances.aimGunCooldown.duration / 3)
	animator.setParticleEmitterActive("muzzleFlash", false)
	animator.setParticleEmitterActive("hotsmoke", false)
	util.wait(self.stances.aimGunCooldown.duration / 3 * 2)
	
	self.weapon:setStance(self.stances.idle)
	self.cooldownTimer = 0.15
	self.lock = false
end

function Parry:pumpSpear()
	self.lock = true
	
	animator.playSound("pump")
	
	self.weapon:setStance(self.stances.pump)
	util.wait(self.stances.pump.duration)
	
	local offset = vec2.add(mcontroller.position(), activeItem.handPosition({-0.35,0}))
	local params = {speed=7}
	world.spawnProjectile("gic_shellcasing_shotgunshell",offset,activeItem.ownerEntityId(),{-0.1*mcontroller.facingDirection(),1},false,params)
	
	self.weapon:setStance(self.stances.pumpFin)
	util.wait(self.stances.pumpFin.duration)
	
	self.shellLoaded = true
	activeItem.setInstanceValue("shellLoaded",self.shellLoaded)
	
	self.cooldownTimer = 0.15
	self.lock = false
end

function Parry:reloadSpear()
	self.lock = true

	self.weapon:setStance(self.stances.reloadPre)
	util.wait(self.stances.reloadPre.duration)
	
	repeat
		
		--sb.logInfo(self.fireModeTmp)
		animator.playSound("reload")
		
		self.weapon:setStance(self.stances.reload)
		util.wait(self.stances.reload.duration)
		
		self.shells = self.shells + 1
		activeItem.setInstanceValue("shells",self.shells)
		player.consumeItem({name = self.ammoItem, count = 1})
		
		self.weapon:setStance(self.stances.reload2)
		util.wait(self.stances.reload2.duration)
		
	until self.fireMode == "alt" or altHeld or self.fireModeTmp == 1 or self.shells == self.shellsMax or not player.hasItem({name = self.ammoItem})
	
	
	self.cooldownTimer = 0.5
	self.lock = false
	
	if self.shellLoaded == false then
		self:setState(self.pumpSpear)
	else
	
	self.weapon:setStance(self.stances.reloadEnd)
	self.weapon:updateAim()

	animator.playSound("spin")
	
	local progress = 0
	util.wait(self.stances.reloadEnd.duration, function()
		local from = self.stances.reloadEnd.weaponOffset or {0,0}
		local to = self.stances.idle.weaponOffset or {0,0}
		self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.reloadEnd.weaponRotation, self.stances.idle.weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.reloadEnd.armRotation, self.stances.idle.armRotation))

		progress = math.min(1.0, progress + (self.dt / self.stances.reloadEnd.duration))
	end)
	end
end

function Parry:chargeSlash()
  --local damageArea = partDamageArea("swoosh")
  self.weapon:setStance(self.stances.slashdashWindup)
  util.wait(self.stances.slashdashWindup.duration)

  
  animator.setGlobalTag("directives", "?border=2;AACCFFFF;00000000")
  animator.setAnimationState("swoosh", "charge")
  
  
  status.setPersistentEffects("iframes", {{stat = "invulnerable", amount = 1}})
  animator.playSound("charge")

  local position = mcontroller.position()


  self.weapon:setStance(self.stances.slashdash)
  
  self.weapon:updateAim()
  local damageArea = partDamageArea("swoosh")
  --sb.logInfo(self.weapon.aimAngle)
  self.dashSpeed = 100
  util.wait(self.dashTime or 0.3, function(dt)

    mcontroller.setVelocity({self.weapon.aimDirection * self.dashSpeed, -200})
	--local xVel = self.weapon.aimDirection*math.cos(self.weapon.aimAngle)*self.dashSpeed
	--local yVel = math.sin(self.weapon.aimAngle)*self.dashSpeed
	--mcontroller.setVelocity({xVel, -200})
    mcontroller.controlMove(self.weapon.aimDirection)
    --local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.slashdashConfig, damageArea)
  end)
  
  animator.setAnimationState("swoosh", "idle")
  
  mcontroller.setVelocity({0, 0})
  animator.setGlobalTag("directives", "")
  status.clearPersistentEffects("iframes")
  status.clearPersistentEffects("weaponMovementAbility")
  self.cooldownTimer = 0.75
end

function findTargets(pos,trackingDistance)
  local sourceEntity = entity.id()
  local queryParameters = {
    withoutEntityId = sourceEntity,
    includedTypes = {"creature"},
    order = "nearest"
  }

  if not trackingDistance then trackingDistance = 50 end
  if not pos then  pos = mcontroller.position() end
  
  local candidates = world.entityQuery(pos, trackingDistance, queryParameters)
  
  self.targetFound = false
  self.shouldFire = false
  self.toTarget = {mcontroller.facingDirection(),0}

  --sb.logInfo(#candidates)
  if #candidates == 0 then return false end

  --local vel = mcontroller.velocity()
  --local angle = vec2.angle(vel)
  local slashTargets = {}
  for _, candidate in ipairs(candidates) do
    if world.entityCanDamage(sourceEntity, candidate) then
      local canPos = world.entityPosition(candidate)
	  self.canPos = canPos
	  self.candidate = candidate
      if not world.lineTileCollision(pos, canPos) then
        --local toTarget = world.distance(canPos, pos)
		local pulledDat = candidate
		slashTargets[#slashTargets + 1] = pulledDat
      end
    end
  end
  
  if #slashTargets == 0 then return false end
  return slashTargets
end

function Parry:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, (self.weapon.aimAngle-0.02 + sb.nrand(inaccuracy, 0)))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function Parry:reset()
  animator.setAnimationState("parryShield", "inactive")
  status.clearPersistentEffects("broadswordParry")
  status.clearPersistentEffects("iframes")
  activeItem.setItemShieldPolys({})
end

function Parry:uninit()
  self:reset()
end
