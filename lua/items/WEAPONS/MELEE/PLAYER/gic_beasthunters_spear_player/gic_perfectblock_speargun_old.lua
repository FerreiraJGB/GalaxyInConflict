require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

Parry = WeaponAbility:new()

function Parry:init()
  self.cooldownTimer = 0
  self.shellLoaded = config.getParameter("shellLoaded",true)
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
    and shiftHeld
    and self.cooldownTimer == 0 then
    --and status.overConsumeResource("energy", self.energyUsage) then

    self.weapon:setStance(self.stances.parry)
	self.weapon:updateAim()
	self:setState(self.parry)
  elseif (self.fireMode == "none") and altHoldTime > 0
  and self.weapon.currentAbility == nil and self.cooldownTimer == 0 then
		
		--TAP ALT
		altHoldTmp = false
		altHoldTime = 0
		self:setState(self.chargeSlash)
  elseif altHoldTmp == true and self.weapon.currentAbility == nil and altHoldTime == 0 and self.fireMode == "alt" and self.lock == false and self.cooldownTimer == 0 then
  
		--HOLD ALT
		if self.shellLoaded == true then
			self:setState(self.gunStance)
		else
			self:setState(self.reloadSpear)
		end
		altHoldTmp = false
  end
  
  
  altHoldTime = math.max(0, altHoldTime - self.dt)
  if self.fireMode == "alt" and altHoldTmp == false then
	altHoldTime = 0.15 --hold timer
	altHoldTmp = true
  end
  
  if altHoldTmp == true and altHoldTime == 0 and self.fireMode == "none" then
	altHoldTmp = false
  end
  
  altHeld = self.fireMode == "alt"
  
  
  if self.shellLoaded == true then
	activeItem.setCursor("/cursors/chargeready.cursor")
  else
	activeItem.setCursor("/cursors/chargeinvalid.cursor")
  end
  
  
  if shiftHeld then
	self.fireModeTmp = 1
  else
	self.fireModeTmp = 0
  end
end

function Parry:parry()
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
  
  local damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 then
		if self.shieldTicks <= self.perfectBlockTime then
			animator.playSound("perfectBlock")
			
			self.shieldTicks = 0
			status.setResource("shieldStamina", self.shieldHealth)
			
			if self.shellLoaded == 1 then
				counterAttackTrigger = true
			end
		else
			animator.playSound("parry")
		end
        --animator.playSound("parry")
        animator.setAnimationState("parryShield", "block")
        return
      end
    end
  end)
  
  
  
  local perfectParryGone = false
  self.shieldTicks = 0
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
  
	self.shieldTicks = self.shieldTicks + 1
	if self.shieldTicks <= self.perfectBlockTime then
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
  
  if counterAttackTrigger == true then
	status.clearPersistentEffects("broadswordParry")
	self:setState(self.counterAttack);
  end
end

function Parry:counterAttack()
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
	local params = {power=30}
	
	self.shellLoaded = false
	activeItem.setInstanceValue("shellLoaded",self.shellLoaded)
	
	for i=0,5,1 do
		world.spawnProjectile("gic_redtracerbullet_heavy_c_nobleed", fireOffset,activeItem.ownerEntityId(),self:aimVector(0.05),false,params)
	end
	
	self.weapon:setStance(self.stances.aimGunCooldown)
	util.wait(self.stances.aimGunCooldown.duration)
	self.weapon:setStance(self.stances.idle)
	self.cooldownTimer = 0.25
	self.lock = false
end

function Parry:reloadSpear()
	self.lock = true
	
	animator.playSound("reload")
	self.weapon:setStance(self.stances.reload)
	util.wait(self.stances.reload.duration)
	
	self.weapon:setStance(self.stances.reloadFin)
	util.wait(self.stances.reloadFin.duration)
	
	self.shellLoaded = true
	activeItem.setInstanceValue("shellLoaded",self.shellLoaded)
	
	self.cooldownTimer = 0.5
	self.lock = false
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
