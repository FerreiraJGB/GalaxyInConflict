require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

Parry = WeaponAbility:new()

local stanceEffects = {"gic_master_sword_stanceNeutral","gic_master_sword_stanceFury","gic_master_sword_stanceDefensive"} -- persistent effects active depending on the stance. config later.
local stanceAbilities = {"gic_ms_matchlockability","gic_ms_bladestorm","gic_ms_counterability"} -- persistent effects active depending on the stance. config later.
local initStanceEffects = {"gic_ms_stanceNeutralFx","gic_ms_stanceFuryFx","gic_ms_stanceDefianceFx"} -- temporary effects that trigger on stance switch

local stanceTmp = 0
local altHeld = false
local altHoldTime = 0
local altHoldTmp = false
local counterattackTarget

function Parry:init()
  self.cooldownTimer = 0
  self.stance = 1
  animator.setGlobalTag("directives", "")
  --self.parryTimeTemp = self.parryTime
  
  if config.getParameter("stanceTmp") then stanceTmp = config.getParameter("stanceTmp") end
  if config.getParameter("lastStance") then self.stance = config.getParameter("lastStance") end
end

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
  and self.weapon.currentAbility == nil and self.cooldownTimer == 0 then
		
		--TAP ALT
		stanceTmp = stanceTmp + 1
		self.stance = 1 + stanceTmp % 3
		--sb.logInfo(stanceTmp)
		--sb.logInfo(stance)
		--sb.logInfo("")
		animator.playSound("switchStance")
		
		altHoldTmp = false
		altHoldTime = 0
		status.addEphemeralEffect(initStanceEffects[self.stance])
  elseif altHoldTmp == true and self.weapon.currentAbility == nil and altHoldTime == 0 and shiftHeld then
  
		--HOLD ALT
		
		if self.stance == 1 and status.stat("gic_ms_matchlock_cooldown") == 0 then
			self:setState(self.gunStance)
			
			altHoldTmp = false
		elseif self.stance == 2 and self.cooldownTimer == 0 and status.stat("gic_ms_blinkstorm_cooldown") == 0 then
			self:setState(self.blinkWindup)
			altHoldTmp = false
		elseif self.stance == 3 and self.cooldownTimer == 0 then--and status.stat("gic_ms_blinkstorm_cooldown") == 0 then
			--self:setState(self.quickslashWindup)
			self:setState(self.manualCounter)
			altHoldTmp = false
		end
  end
  status.setPersistentEffects("stanceEffect", {stanceEffects[self.stance]})
  status.setPersistentEffects("stanceAbility", {stanceAbilities[self.stance]})
  
  
  --world.debugText("altHoldTime " .. sb.printJson(altHoldTime), vec2.add(mcontroller.position(), {0,0}), "yellow")
  --world.debugText("fire mode " .. sb.printJson(self.fireMode), vec2.add(mcontroller.position(), {0,1}), "yellow")
  --world.debugText("alt fire? " .. sb.printJson(altHeld), vec2.add(mcontroller.position(), {0,2}), "yellow")
  
  altHoldTime = math.max(0, altHoldTime - self.dt)
  if shiftHeld and altHoldTmp == false then
	altHoldTime = 0.125 --hold timer
	altHoldTmp = true
  end
  
  if altHoldTmp == true and altHoldTime == 0 and not shiftHeld then
	altHoldTmp = false
  end
  
  altHeld = shiftHeld
  
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
  --self.perfectBlockTime = 20 --ticks

  status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = 99999}})

  local blockPoly = animator.partPoly("parryShield", "shieldPoly")
  activeItem.setItemShieldPolys({blockPoly})

  animator.setAnimationState("swoosh", "idle")
  animator.setAnimationState("parryShield", "active")
  --coroutine.yield()
  
  animator.playSound("guard")
  
  --
  local counterattackQuery = false
  
  local shieldHp = status.resource("shieldStamina")
  local damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 then
		if self.shieldTime <= self.perfectBlockTime and status.resource("shieldStamina") < shieldHp then
			animator.playSound("perfectBlock")
			
			
			self.shieldTime = 0
			status.setResource("shieldStamina", 1)
			
			if self.stance == 3 and status.stat("gic_ms_counterattack_cooldown") == 0 then		
				--valid targets 4 blocks in front of player
				local validCounterattackTargets = findTargets(vec2.add(mcontroller.position(),{4 * mcontroller.facingDirection(),0}),10)
				
				if validCounterattackTargets then 
					counterattackQuery = true
					status.addEphemeralEffect("regenerationfast",3)
					status.addEphemeralEffect("gic_smokebomb_ability",3.75)
					counterattackTarget = validCounterattackTargets[1]
					world.spawnProjectile("gic_counterflash_long",mcontroller.position(),activeItem.ownerEntityId(),{0, 0},false)
				else
					status.addEphemeralEffect("gic_smokebomb_ability")
					world.spawnProjectile("gic_counterflash",mcontroller.position(),activeItem.ownerEntityId(),{0, 0},false)
				end
			else
				if self.stance == 2 then
					status.addEphemeralEffect("gic_smokebomb_ability",3)
				else
					status.addEphemeralEffect("gic_smokebomb_ability")
				end
				
				if self.stance == 1 then
					status.addEphemeralEffect("gic_ms_cdreduce")
				end
				
				status.addEphemeralEffect("gic_smokebomb_ability")
				world.spawnProjectile("gic_counterflash",mcontroller.position(),activeItem.ownerEntityId(),{0, 0},false)--,config.getParameter("perfectParryParams"))		
			end
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
  
  
  
  
  self.shieldTime = 0
  self.fireModeTmp = 1
  
  local perfectParryGone = false
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
	
	if counterattackQuery == true then
		return true --exits parry state if counter attack is enabled and is triggered
	end
	
	damageListener:update()
  end)
  animator.setGlobalTag("directives", "")

  
  
  --while self.fireModeTmp == 1 and status.resourcePositive("shieldStamina") do
  --  self.damageListener = damageListener("damageTaken", function(notifications)
  --  for _,notification in pairs(notifications) do
      --if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 then
	--  if notification.hitType == "ShieldHit" then
    --    animator.playSound("parry")
	--	animator.playSound("guard")
   --     animator.setAnimationState("parryShield", "block")
   --     return
   --   end
  --  end
  --end)
	--local blockPoly = animator.partPoly("parryShield", "shieldPoly")
   -- activeItem.setItemShieldPolys({blockPoly})
    --coroutine.yield()
  --end
  
  --self.cooldownTimer = self.cooldownTime
  activeItem.setItemShieldPolys({})
  self.parryActive = false
  
  if counterattackQuery == true then
	self.weapon:setStance(self.stances.idle)
	status.clearPersistentEffects("broadswordParry")
	self:counterattack();
  end
end

function Parry:reset()
  animator.setAnimationState("parryShield", "inactive")
  status.clearPersistentEffects("broadswordParry")
  status.clearPersistentEffects("swordHolster")
  status.clearPersistentEffects("stanceEffect")
  status.clearPersistentEffects("stanceAbility")
  status.clearPersistentEffects("iframes")
  status.clearPersistentEffects("weaponMovementAbility")
  activeItem.setInstanceValue("lastStance",self.stance)
  activeItem.setInstanceValue("stanceTmp",stanceTmp)
  activeItem.setItemShieldPolys({})
end

function Parry:gunStance()
  --sb.logInfo("gunstance")
  
  status.setPersistentEffects("swordHolster",{"gic_master_sword_holster"})
  
  animator.setAnimationState("blade", "invis")
  self.weapon:setStance(self.stances.aimGun)
  animator.setAnimationState("swoosh", "invis")
  
  
  --animator.setAnimationState("gun", "active")
  animator.setAnimationState("gun", "spawnTransition")
  
  util.wait(99999, function()
	self.weapon:updateAim()
	mcontroller.controlModifiers({runningSuppressed = true})
    if not altHeld == true then return true end
  end)
  
  local fireOffset = vec2.add(mcontroller.position(), activeItem.handPosition({1.15,0.6}))
  local params = {power=200}
  
  
  world.spawnProjectile("gic_handcannon_immediate_a", fireOffset,activeItem.ownerEntityId(),self:aimVector(),false,params)
  world.spawnProjectile("gic_nagashimamatchlock_projectile", fireOffset,activeItem.ownerEntityId(),self:aimVector(),false,{speed=5,power=0})
  
  status.addEphemeralEffect("gic_master_sword_matchlockCooldown")
  animator.setAnimationState("gun", "idle")
  animator.playSound("fireGun") -- set up fireGun sfx later -- [ "/sfx/gun/gic_musket_fire_immediate.ogg" ]
  
  
  status.clearPersistentEffects("swordHolster")
  self.weapon:setStance(self.stances.idle)
  animator.setAnimationState("swoosh", "idle")
  animator.setAnimationState("blade", "idle")
  
  self.cooldownTimer = self.cooldownTime
  animator.setGlobalTag("directives", "")
end


function Parry:blinkWindup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  util.wait(self.stances.windup.duration)

  self.blinkTargets = findTargets()
  --sb.logInfo(sb.printJson(self.blinkTargets))
  --self.blinkPosition = vec2.add(mcontroller.position(),{0,5})
  if self.blinkTargets then--self.blinkPosition then--and status.overConsumeResource("energy", self.energyUsage) then
	status.addEphemeralEffect("gic_master_sword_blinkstormCooldown")
    self:setState(self.blinkSlash)
  else
    self.cooldownTimer = self.cooldownTime
  end
end

function Parry:blinkSlash()
  local suppressMove = function()
    mcontroller.controlModifiers({movementSuppressed = true})
    mcontroller.controlParameters({
      gravityEnabled = false
    })
    mcontroller.setVelocity({0,0})
  end

  local slash = coroutine.create(self.slashAction)
  coroutine.resume(slash, self)

  while util.parallel(suppressMove, slash) do
    coroutine.yield()
  end
  mcontroller.controlModifiers({movementSuppressed = false})
end

function Parry:slashAction()
  status.addEphemeralEffect("blink")
  util.wait(0.25)

  local fromPosition = mcontroller.position()
  --local target = vec2.add(activeItem.ownerAimPosition(),{-2 * mcontroller.facingDirection(), 0}) -- mouse position
  
  status.setPersistentEffects("iframes", {{stat = "invulnerable", amount = 1}})
  local targetNum = 0
  local targetsHit = 0
  repeat
    targetNum = targetNum + 1
	local targetPos = world.entityPosition(self.blinkTargets[targetNum])
	
	if targetPos then
	targetsHit = targetsHit + 1
	local target = vec2.add(targetPos,{-1.75 * mcontroller.facingDirection(), 0}) -- target positions
  
	mcontroller.setPosition(target)--self.blinkPosition)
	--self.weapon.aimDirection = -self.weapon.aimDirection
	self.weapon:setStance(self.stances.slash)
	self.weapon:updateAim()

	util.wait(0.1)

	animator.setAnimationState("blinkSwoosh", "fire")
	animator.playSound("fire")
	
	local damageConfig = self.damageConfig
	damageConfig.baseDamage = damageConfig.baseDamage + (targetsHit - 1) * 20
	
	util.wait(self.stances.slash.duration, function()
		local damageArea = partDamageArea("blinkSwoosh")
		self.weapon:setDamage(damageConfig, damageArea)
	end)

	status.removeEphemeralEffect("blink")
	status.addEphemeralEffect("blink")
	util.wait(0.25)
	end
	
  until (targetNum >= #self.blinkTargets)
  mcontroller.setPosition(fromPosition)
  status.clearPersistentEffects("iframes")
  targetsHit = 0
  --self.weapon.aimDirection = -self.weapon.aimDirection

  self.cooldownTimer = 0.75
end

function Parry:counterattack()
  --sb.logInfo("counterAttackSuccess")
  self.overrideSuppress = false
  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  animator.setAnimationState("parryShield", "inactive")
  
  local suppressMove = function()
    mcontroller.controlModifiers({movementSuppressed = true})
    mcontroller.controlParameters({
      gravityEnabled = false
    })
	if self.overrideSuppress == false then
		mcontroller.setVelocity({0,0})
	end
  end

  local counterattackSlash = coroutine.create(self.counterattackSlash)
  coroutine.resume(counterattackSlash, self)

  while util.parallel(suppressMove, counterattackSlash) do
    coroutine.yield()
  end
  
  mcontroller.controlModifiers({movementSuppressed = false})
end

function Parry:counterattackSlash()
	local fromPosition = mcontroller.position()
	status.setPersistentEffects("iframes", {{stat = "invulnerable", amount = 1}})
	status.addEphemeralEffect("blink")
	util.wait(0.25)
	
	status.addEphemeralEffect("gic_master_sword_counterattackCooldown")
	
	local targetPos = world.entityPosition(counterattackTarget)
	--self.weapon:updateAim()
	--self.weapon.aimDirection = -self.weapon.aimDirection
	--self.weapon:updateAim()
	--mcontroller.setPosition(vec2.add(targetPos,{3 * mcontroller.facingDirection(),0}))
	
	if targetPos then
		self.weapon:setStance(self.stances.windup)
		
		--quick alternating slashes
		for i=1,3,1 do
			targetPos = world.entityPosition(counterattackTarget)
			
			if targetPos then
				self.weapon.aimDirection = -self.weapon.aimDirection
				self.weapon:updateAim()
				local teleportPos = vec2.add(targetPos,{3 * mcontroller.facingDirection(),0})
				mcontroller.setPosition(teleportPos)
			
				if i%2 == 0 then
					self.weapon:setStance(self.stances.windup)
					else
					self.weapon:setStance(self.stances.windup2)
				end
				util.wait(0.2)
			
				if i%2 == 0 then
					self.weapon:setStance(self.stances.slash)
					else
					self.weapon:setStance(self.stances.slash2)
				end
			
				self.weapon:updateAim()
			
				--util.wait(0.1)
				if i%2 == 0 then
					animator.setAnimationState("swoosh", "fire")
					else
					animator.setAnimationState("swoosh", "fire2")
				end
				animator.playSound("fire")
			
			
				local damageConfig = self.flurryConfig
				--damageConfig.baseDamage = damageConfig.baseDamage + (targetsHit - 1) * 20
			
				util.wait(self.stances.slash.duration, function()
					local damageArea = partDamageArea("swoosh")
					self.weapon:setDamage(damageConfig, damageArea)
				end)
			
				status.removeEphemeralEffect("blink")
				status.addEphemeralEffect("blink")
				util.wait(0.2)
			end
		end
	
	targetPos = world.entityPosition(counterattackTarget)
	--uppercut into downslam
	if targetPos then
		targetPos = world.entityPosition(counterattackTarget)
		self.weapon.aimDirection = -self.weapon.aimDirection
		self.weapon:updateAim()
		
		local teleportPos = vec2.add(targetPos,{3 * mcontroller.facingDirection(),0})
		mcontroller.setPosition(teleportPos)
		
		self.weapon:setStance(self.stances.windup)
		util.wait(0.2)
		self.weapon:setStance(self.stances.slash)
		self.weapon:updateAim()
		animator.setAnimationState("swoosh", "fire")
		animator.playSound("fire")
		
		local damageConfig = self.uppercutConfig
		util.wait(self.stances.slash.duration, function()
			local damageArea = partDamageArea("swoosh")
			self.weapon:setDamage(damageConfig, damageArea)
		end)
		
		status.removeEphemeralEffect("blink")
		status.addEphemeralEffect("blink")
		util.wait(0.2)
		
		
		-- downslam --
		local teleportPos = vec2.add(targetPos,{-3 * mcontroller.facingDirection(),15})
		mcontroller.setPosition(teleportPos)
		
		self.weapon:setStance(self.stances.windup2)
		util.wait(0.2)
		self.weapon:setStance(self.stances.slash2)
		self.weapon:updateAim()
		animator.setAnimationState("swoosh", "fire")
		animator.playSound("fire6")
		
		local damageConfig = self.downslamConfig
		self.overrideSuppress = true
		mcontroller.setVelocity({0,-70})
		util.wait(self.stances.slash.duration, function()
			mcontroller.controlModifiers({movementSuppressed = false})
			local damageArea = partDamageArea("swoosh")
			self.weapon:setDamage(damageConfig, damageArea)
		end)
			
		status.removeEphemeralEffect("blink")
		status.addEphemeralEffect("blink")
		util.wait(0.2)
	end
	
	
	end
	
	mcontroller.setVelocity({0,0})
	status.clearPersistentEffects("iframes")
	status.clearPersistentEffects("weaponMovementAbility")
	mcontroller.setPosition(fromPosition)
	self.cooldownTimer = 0.25
end


function Parry:manualCounter()
  self.weapon:setStance(self.stances.counter)
  self.weapon:updateAim()
  self.counterTime = 0.4
  status.addEphemeralEffect("gic_superarmor", self.counterTime)
  status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = 99999}})

  local blockPoly = animator.partPoly("counterShield", "shieldPoly")
  activeItem.setItemShieldPolys({blockPoly})

  --animator.setAnimationState("parryShield", "active")
  --coroutine.yield()
  
  animator.playSound("guard")
  
  --
  local counterAttackTarget
  local counterAttackQuery = false
  
  status.setResource("shieldStamina", 1)
  local shieldHp = status.resource("shieldStamina")
  local damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
	  --sb.logInfo(sb.printJson(notification))
      if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 and status.resource("shieldStamina") < shieldHp then
	  --sb.logInfo(status.resource("shieldStamina"))
		--if self.shieldTicks <= self.perfectBlockTime then
			--animator.playSound("counterAttack")
			--status.setResource("shieldStamina", self.shieldHealth)
			--animator.setAnimationState("parryShield", "block")
			
			local validCounterattackTargets = findTargets(vec2.add(mcontroller.position(),{3 * mcontroller.facingDirection(),0}),40)
			status.setResource("shieldStamina", 1)
			status.addEphemeralEffect("regenerationfast",1.0)
			
			if validCounterattackTargets then
				counterAttackQuery = true
				animator.playSound("counterAttack")
				counterAttackTarget = validCounterattackTargets[1]
				--sb.logInfo(sb.printJson(counterAttackTarget))
				--status.addEphemeralEffect("regenerationfast",1)
			end
        return
      end
    end
	
	shieldHp = status.resource("shieldStamina")
  end)
  
  
  
  --local perfectParryGone = false
  --self.shieldTicks = 0
  --self.fireModeTmp = 1
  util.wait(self.counterTime, function(dt)
  
	--suppress movement
    mcontroller.controlModifiers({movementSuppressed = true})
	
	if counterAttackQuery == true then return true end
  
	animator.setGlobalTag("directives", "?border=2;AACCFFFF;00000000")
	
	damageListener:update()
  end)
  
  
  animator.setGlobalTag("directives", "")
  activeItem.setItemShieldPolys({})
  
  if counterAttackQuery == true then
	self.counterTarget = counterAttackTarget
	counterAttackQuery = false
	self:setState(self.manualCounterattack)
  else
	self:setState(self.failedCounterAttack)
	
	
	--status.setPersistentEffects("stopMovement", {{stat = "activeMovementAbilities", amount = 1}})
	--util.wait(1.0)
	--status.clearPersistentEffects("stopMovement")
  end
end

function Parry:failedCounterAttack()
	self.cooldownTimer = 1.0
	status.addEphemeralEffect("gic_stun_1",1.0)
	status.overConsumeResource("energy", 9999)
	
	activeItem.setItemShieldPolys({})
	animator.setAnimationState("parryShield", "inactive")
	status.clearPersistentEffects("broadswordParry")
	
	self.weapon:setStance(self.stances.idle)
	
	util.wait(1.0)
	
	altHoldTmp = false
end


function Parry:manualCounterattack()
	self:reset()
    status.addEphemeralEffect("invulnerable",self.stances.afire1.duration + self.stances.apreslash1.duration + self.stances.awindup1.duration+0.2)
	
	self.weapon:setStance(self.stances.awindup1)
	self.weapon:updateAim()
	util.wait(self.stances.awindup1.duration)
	--sb.logInfo(sb.printJson(self.counterTarget))
	
	--if self.counterTarget then
	--sb.logInfo(sb.printJson(world.entityPosition(self.counterTarget)))
	--sb.logInfo("yes")
	--end
	self.weapon:setStance(self.stances.apreslash1)
	self.weapon:updateAim()
	util.wait(self.stances.apreslash1.duration)
	
	animator.setAnimationState("swoosh", "fire")
	animator.playSound("fire")
	animator.playSound("fireSwoosh")
	self.weapon:setStance(self.stances.afire1)
	self.weapon:updateAim()
	
	if world.entityPosition(self.counterTarget) then
		local diff = world.distance(world.entityPosition(self.counterTarget), mcontroller.position())
		local hyp = math.sqrt(diff[1]*diff[1] + diff[2]*diff[2])
		local velMult = 30
		local vel = {velMult*diff[1]/hyp,velMult*diff[2]/hyp}
		
		if mcontroller.onGround() and (vel[2] <= 0)then
			vel[1] = vel[1] * 2
		end
	
	--util.wait(self.stances.fire1.duration)
		if (mcontroller.facingDirection() > 0 and diff[1] > 0) or (mcontroller.facingDirection() < 0 and diff[1] < 0) then
		else
			self.weapon.aimDirection = -self.weapon.aimDirection
		end
		self.weapon:updateAim()
		mcontroller.setVelocity(vel)
	else
		mcontroller.setVelocity({mcontroller.facingDirection()*30,0}) --backup in case target entity is dead
	end
		--local moveConfig = mcontroller.parameters()
		--moveConfig.groundFriction = 0
		--mcontroller.applyParameters(moveConfig)
		
		world.spawnProjectile(self.counterProjectileType,mcontroller.position(),activeItem.ownerEntityId(),{mcontroller.facingDirection(), 0},false,self.counterProjectileConfig)
		
		local damageConfig = self.counterDamageConfig
		status.setPersistentEffects("stopMovement", {{stat = "activeMovementAbilities", amount = 1}})
		util.wait(self.stances.afire1.duration, function()
			local damageArea = partDamageArea("swoosh")
			self.weapon:setDamage(damageConfig, damageArea)
			mcontroller.controlModifiers({movementSuppressed = true})
		end)
		
		--mcontroller.resetParameters()
		status.clearPersistentEffects("stopMovement")
		
		
	-- second slash --
	
	status.addEphemeralEffect("invulnerable",self.stances.afire2.duration + self.stances.apreslash2.duration + self.stances.awindup2.duration+0.2)
	
	self.weapon:setStance(self.stances.awindup2)
	self.weapon:updateAim()
	util.wait(self.stances.awindup2.duration)
	--sb.logInfo(sb.printJson(self.counterTarget))
	
	--if self.counterTarget then
	--sb.logInfo(sb.printJson(world.entityPosition(self.counterTarget)))
	--sb.logInfo("yes")
	--end
	self.weapon:setStance(self.stances.apreslash2)
	self.weapon:updateAim()
	util.wait(self.stances.apreslash2.duration)
	
	animator.setAnimationState("swoosh", "fire2")
	animator.playSound("fire2")
	animator.playSound("fireSwoosh")
	self.weapon:setStance(self.stances.afire2)
	self.weapon:updateAim()
		
	if world.entityPosition(self.counterTarget) then
		local diff = world.distance(world.entityPosition(self.counterTarget), mcontroller.position())
		local hyp = math.sqrt(diff[1]*diff[1] + diff[2]*diff[2])
		local velMult = 30
		local vel = {velMult*diff[1]/hyp,velMult*diff[2]/hyp}
		
		if mcontroller.onGround() and (vel[2] <= 0)then
			vel[1] = vel[1] * 2
		end
	
	--util.wait(self.stances.fire1.duration)
		if (mcontroller.facingDirection() > 0 and diff[1] > 0) or (mcontroller.facingDirection() < 0 and diff[1] < 0) then
		else
			self.weapon.aimDirection = -self.weapon.aimDirection
		end
		self.weapon:updateAim()
		mcontroller.setVelocity(vel)
	else
		mcontroller.setVelocity({mcontroller.facingDirection()*30,0}) --backup in case target entity is dead
	end
		--local moveConfig = mcontroller.parameters()
		--moveConfig.groundFriction = 0
		--mcontroller.applyParameters(moveConfig)
		
		world.spawnProjectile(self.counterProjectileType,mcontroller.position(),activeItem.ownerEntityId(),{mcontroller.facingDirection(), 0},false,self.counterProjectileConfig)
		
		local damageConfig = self.counterDamageConfig
		status.setPersistentEffects("stopMovement", {{stat = "activeMovementAbilities", amount = 1}})
		util.wait(self.stances.afire2.duration, function()
			local damageArea = partDamageArea("swoosh")
			self.weapon:setDamage(damageConfig, damageArea)
			mcontroller.controlModifiers({movementSuppressed = true})
		end)
		
		--mcontroller.resetParameters()
		status.clearPersistentEffects("stopMovement")
	
	
	self.cooldownTimer = 0.5
	
	altHoldTmp = false
end


-- to be deprecated
function Parry:quickslashWindup()
  self.weapon:setStance(self.stances.slashdashWindup)
  self.weapon:updateAim()

  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  util.wait(self.stances.windup.duration)
  
  self:setState(self.quickslash)
end

function Parry:quickslash()
  self.weapon:setStance(self.stances.slashdash)
  animator.setGlobalTag("directives", "?border=2;AACCFFFF;00000000")
  animator.setAnimationState("swoosh", "fire3")

  status.setPersistentEffects("iframes", {{stat = "invulnerable", amount = 1}})
  animator.playSound("fire6")

  local position = mcontroller.position()


  --sb.logInfo(self.weapon.aimAngle)
  self.dashSpeed = 200
  util.wait(self.dashTime or 0.125, function(dt)

    --mcontroller.setVelocity({self.weapon.aimDirection * self.dashSpeed, -200})
	local xVel = self.weapon.aimDirection*math.cos(self.weapon.aimAngle)*self.dashSpeed
	local yVel = math.sin(self.weapon.aimAngle)*self.dashSpeed
	mcontroller.setVelocity({xVel, yVel})
    mcontroller.controlMove(self.weapon.aimDirection)
    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.slashdashConfig, damageArea)
  end)
  
  local xVel = self.weapon.aimDirection*math.cos(self.weapon.aimAngle)*30
  local yVel = math.sin(self.weapon.aimAngle)*30
  mcontroller.setVelocity({xVel,yVel})

  util.wait(0.15, function(dt)
	local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.slashdashConfig, damageArea)
  end)
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

function Parry:aimVector()
  local aimVector = vec2.rotate({1, 0}, (self.weapon.aimAngle))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  --sb.logInfo(self.weaponNegativeEffectResultFinal)
  --aimVector[1] * (self.weaponNegativeEffectResultFinal or 1) = aimVector[1] * mcontroller.facingDirection() * (self.weaponNegativeEffectResultFinal or 1)
  return aimVector
end

function Parry:uninit()
  self:reset()
end
